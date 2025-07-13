extends Node2D
class_name TimeAffectedObject

# Example object that demonstrates time state management
# This could be a moving platform, rotating object, or any animated element

# Time management
var time_manager: TimeManager
var initial_position: Vector2
var rotation_speed: float = 90.0  # degrees per second
var movement_amplitude: float = 50.0
var movement_frequency: float = 1.0

# State variables
var current_rotation: float = 0.0
var time_elapsed: float = 0.0

func _ready():
	# Store initial position
	initial_position = global_position
	
	# Register with time manager
	time_manager = get_node("/root/TimeManager")
	if time_manager:
		time_manager.register_time_object(self)
		time_manager.time_state_changed.connect(_on_time_state_changed)

func _process(delta):
	# Only update if time is not paused
	if time_manager and time_manager.get_time_state() != TimeManager.TimeState.PAUSED:
		_update_object(delta)

func _update_object(delta):
	# Update time elapsed
	time_elapsed += delta
	
	# Rotate the object
	current_rotation += rotation_speed * delta
	if current_rotation >= 360.0:
		current_rotation -= 360.0
	
	rotation_degrees = current_rotation
	
	# Move the object in a sinusoidal pattern
	var offset = Vector2(
		sin(time_elapsed * movement_frequency) * movement_amplitude,
		cos(time_elapsed * movement_frequency * 0.5) * movement_amplitude * 0.5
	)
	
	global_position = initial_position + offset

func _on_time_state_changed(new_state: TimeManager.TimeState):
	# React to time state changes
	match new_state:
		TimeManager.TimeState.NORMAL:
			modulate = Color.WHITE
		TimeManager.TimeState.PAUSED:
			modulate = Color.GRAY
		TimeManager.TimeState.REWINDING:
			modulate = Color.BLUE
		TimeManager.TimeState.FAST_FORWARD:
			modulate = Color.RED

# Time state management - required for time-affected objects
func get_time_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation": current_rotation,
		"time_elapsed": time_elapsed,
		"modulate": modulate
	}

func set_time_state(state: Dictionary):
	if "position" in state:
		global_position = state.position
	if "rotation" in state:
		current_rotation = state.rotation
		rotation_degrees = current_rotation
	if "time_elapsed" in state:
		time_elapsed = state.time_elapsed
	if "modulate" in state:
		modulate = state.modulate

# Example of how to create a time-affected collectible
func collect():
	# This object has been collected
	if time_manager:
		time_manager.unregister_time_object(self)
	queue_free()

# Example of how to reset the object
func reset_to_initial_state():
	global_position = initial_position
	current_rotation = 0.0
	time_elapsed = 0.0
	rotation_degrees = 0.0
	modulate = Color.WHITE