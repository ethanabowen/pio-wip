extends IsometricCharacter
class_name PlayerController

# UI references
@onready var position_label: Label = get_node("../../UI/InfoUI/VBoxContainer/PositionLabel")
@onready var camera: Camera2D = get_node("../Camera2D")
@onready var tile_map: IsometricTileMap = get_node("../TileMap")

# Mouse interaction
var mouse_tile_position: Vector2i
var selected_tile: Vector2i = Vector2i(-1, -1)

func _ready():
	super._ready()
	
	# Connect signals
	position_changed.connect(_on_position_changed)
	tile_position_changed.connect(_on_tile_position_changed)
	
	# Initialize camera to follow player
	if camera:
		camera.global_position = global_position

func _process(delta):
	super._process(delta)
	
	# Update mouse tile position
	var mouse_pos = get_global_mouse_position()
	if camera:
		mouse_tile_position = IsometricUtils.get_tile_from_mouse(mouse_pos, camera)
	
	# Handle mouse input
	if Input.is_action_just_pressed("ui_accept"):
		_handle_mouse_click()

func _handle_mouse_click():
	# Check if the tile is valid and walkable
	if tile_map and tile_map.is_tile_walkable(mouse_tile_position):
		# Find path to the clicked tile
		var path = tile_map.find_path(tile_position, mouse_tile_position)
		if path.size() > 0:
			# Move to the first tile in the path
			move_to_tile(path[0])
		else:
			# If no path found, try direct movement
			if IsometricUtils.tile_distance(tile_position, mouse_tile_position) == 1:
				move_to_tile(mouse_tile_position)
	else:
		# Interact with the tile
		interact_with_tile(mouse_tile_position)

func _on_position_changed(new_pos: Vector2):
	# Update camera position
	if camera:
		camera.global_position = global_position
	
	# Update position label
	if position_label:
		position_label.text = "Position: (%d, %d)" % [tile_position.x, tile_position.y]

func _on_tile_position_changed(new_tile_pos: Vector2i):
	# Update position label
	if position_label:
		position_label.text = "Position: (%d, %d)" % [new_tile_pos.x, new_tile_pos.y]

func interact_with_tile(tile_pos: Vector2i):
	if not tile_map:
		return
	
	var tile_type = tile_map.get_tile_type(tile_pos)
	
	match tile_type:
		IsometricTileMap.TileType.TREE:
			# Remove tree
			tile_map.set_tile_type(tile_pos, IsometricTileMap.TileType.GRASS)
			print("Cut down tree at ", tile_pos)
		
		IsometricTileMap.TileType.ROCK:
			# Remove rock
			tile_map.set_tile_type(tile_pos, IsometricTileMap.TileType.GRASS)
			print("Broke rock at ", tile_pos)
		
		IsometricTileMap.TileType.GRASS:
			# Plant tree
			tile_map.set_tile_type(tile_pos, IsometricTileMap.TileType.TREE)
			print("Planted tree at ", tile_pos)
		
		IsometricTileMap.TileType.WATER:
			print("Cannot interact with water")
		
		_:
			print("Interacted with tile at ", tile_pos)

func get_mouse_tile_position() -> Vector2i:
	return mouse_tile_position

func teleport_to_spawn():
	teleport_to_tile(Vector2i(25, 25))  # Center of the default map

# Override time state to include camera position
func get_time_state() -> Dictionary:
	var state = super.get_time_state()
	if camera:
		state["camera_position"] = camera.global_position
	return state

func set_time_state(state: Dictionary):
	super.set_time_state(state)
	if "camera_position" in state and camera:
		camera.global_position = state.camera_position