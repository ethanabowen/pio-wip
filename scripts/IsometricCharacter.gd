extends CharacterBody2D
class_name IsometricCharacter

signal position_changed(new_pos: Vector2)
signal tile_position_changed(new_tile_pos: Vector2i)

# Movement properties
@export var speed: float = 100.0
@export var acceleration: float = 500.0
@export var friction: float = 400.0

# Isometric properties
var world_position: Vector2
var tile_position: Vector2i
var target_position: Vector2
var is_moving: bool = false
var move_tween: Tween

# Time management
var time_manager: TimeManager
var position_history: Array[Vector2] = []
var animation_history: Array[String] = []

# Animation
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Character states
enum CharacterState {
	IDLE,
	WALKING,
	RUNNING,
	INTERACTING
}

var current_state: CharacterState = CharacterState.IDLE
var facing_direction: Vector2 = Vector2.DOWN

# Movement directions for isometric
var move_directions = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0),
	"up_left": Vector2(-1, -1),
	"up_right": Vector2(1, -1),
	"down_left": Vector2(-1, 1),
	"down_right": Vector2(1, 1)
}

func _ready():
	# Initialize position
	world_position = global_position
	tile_position = IsometricUtils.world_to_tile(world_position)
	
	# Find time manager
	time_manager = get_node("/root/TimeManager")
	if time_manager:
		time_manager.register_time_object(self)
	
	# Set up sprite
	if sprite:
		sprite.sprite_frames = _create_default_sprite_frames()
		sprite.play("idle_down")
	
	# Update isometric sorting
	_update_isometric_sorting()

func _physics_process(delta):
	if time_manager and time_manager.get_time_state() == TimeManager.TimeState.PAUSED:
		return
	
	_handle_movement(delta)
	_update_animation()
	_update_isometric_sorting()

func _handle_movement(delta):
	var input_vector = Vector2.ZERO
	
	# Get input
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		facing_direction = input_vector
		current_state = CharacterState.WALKING
	else:
		current_state = CharacterState.IDLE
	
	# Apply movement
	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Move and handle collisions
	move_and_slide()
	
	# Update world position
	var new_world_pos = IsometricUtils.iso_to_world(global_position)
	if new_world_pos != world_position:
		world_position = new_world_pos
		var new_tile_pos = IsometricUtils.world_to_tile(world_position)
		
		if new_tile_pos != tile_position:
			tile_position = new_tile_pos
			emit_signal("tile_position_changed", tile_position)
		
		emit_signal("position_changed", world_position)

func _update_animation():
	if not sprite:
		return
	
	var animation_name = ""
	
	# Determine animation based on state and direction
	match current_state:
		CharacterState.IDLE:
			animation_name = "idle_"
		CharacterState.WALKING:
			animation_name = "walk_"
		CharacterState.RUNNING:
			animation_name = "run_"
	
	# Add direction
	if facing_direction.x > 0.5:
		if facing_direction.y > 0.5:
			animation_name += "down_right"
		elif facing_direction.y < -0.5:
			animation_name += "up_right"
		else:
			animation_name += "right"
	elif facing_direction.x < -0.5:
		if facing_direction.y > 0.5:
			animation_name += "down_left"
		elif facing_direction.y < -0.5:
			animation_name += "up_left"
		else:
			animation_name += "left"
	else:
		if facing_direction.y > 0.5:
			animation_name += "down"
		elif facing_direction.y < -0.5:
			animation_name += "up"
		else:
			animation_name += "down"  # Default
	
	# Play animation if it exists
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name:
			sprite.play(animation_name)
	else:
		# Fallback to simple direction
		var simple_name = animation_name.split("_")[0] + "_down"
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(simple_name):
			if sprite.animation != simple_name:
				sprite.play(simple_name)

func _update_isometric_sorting():
	# Update z-index based on world position for proper sorting
	var depth = IsometricUtils.get_iso_depth(world_position)
	z_index = int(depth)

func move_to_tile(target_tile: Vector2i):
	if is_moving:
		return
	
	var target_world = IsometricUtils.tile_to_world(target_tile)
	var target_iso = IsometricUtils.world_to_iso(target_world)
	
	is_moving = true
	target_position = target_iso
	
	# Create tween for smooth movement
	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_iso, 0.5)
	move_tween.tween_callback(_on_move_complete)

func _on_move_complete():
	is_moving = false
	world_position = IsometricUtils.iso_to_world(global_position)
	tile_position = IsometricUtils.world_to_tile(world_position)
	emit_signal("position_changed", world_position)
	emit_signal("tile_position_changed", tile_position)

func teleport_to_tile(target_tile: Vector2i):
	var target_world = IsometricUtils.tile_to_world(target_tile)
	var target_iso = IsometricUtils.world_to_iso(target_world)
	
	global_position = target_iso
	world_position = target_world
	tile_position = target_tile
	
	emit_signal("position_changed", world_position)
	emit_signal("tile_position_changed", tile_position)
	_update_isometric_sorting()

func get_current_tile() -> Vector2i:
	return tile_position

func get_world_position() -> Vector2:
	return world_position

func set_facing_direction(direction: Vector2):
	facing_direction = direction.normalized()

# Time management functions
func get_time_state() -> Dictionary:
	return {
		"position": global_position,
		"world_position": world_position,
		"tile_position": tile_position,
		"velocity": velocity,
		"facing_direction": facing_direction,
		"current_state": current_state,
		"animation": sprite.animation if sprite else "",
		"animation_frame": sprite.frame if sprite else 0
	}

func set_time_state(state: Dictionary):
	if "position" in state:
		global_position = state.position
	if "world_position" in state:
		world_position = state.world_position
	if "tile_position" in state:
		tile_position = state.tile_position
	if "velocity" in state:
		velocity = state.velocity
	if "facing_direction" in state:
		facing_direction = state.facing_direction
	if "current_state" in state:
		current_state = state.current_state
	if "animation" in state and sprite:
		sprite.animation = state.animation
	if "animation_frame" in state and sprite:
		sprite.frame = state.animation_frame
	
	_update_isometric_sorting()

func _create_default_sprite_frames() -> SpriteFrames:
	# This would typically be created in the Godot editor
	# For now, return null and expect the sprite frames to be assigned in the editor
	return null

func interact_with_tile(tile_pos: Vector2i):
	# Override this method in derived classes
	print("Interacting with tile at: ", tile_pos)

func can_move_to_tile(tile_pos: Vector2i) -> bool:
	# Check if the tile is walkable
	var tile_map = get_node("../TileMap") as IsometricTileMap
	if tile_map:
		return tile_map.is_tile_walkable(tile_pos)
	return true