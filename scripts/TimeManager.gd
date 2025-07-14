extends Node
class_name TimeManager

signal time_state_changed(new_state: TimeState)
signal time_tick(current_time: float)

enum TimeState {
	NORMAL,
	PAUSED,
	REWINDING,
	FAST_FORWARD
}

# Time recording and playback
var time_history: Array[Dictionary] = []
var current_time: float = 0.0
var time_state: TimeState = TimeState.NORMAL
var rewind_speed: float = 2.0
var fast_forward_speed: float = 2.0
var max_history_length: int = 3600  # 60 seconds at 60 FPS

# Time chunks for efficient storage
var time_chunk_size: float = 0.1  # Store state every 0.1 seconds
var last_chunk_time: float = 0.0

# Objects that can be affected by time
var time_objects: Array[Node] = []

func _ready():
	# Connect to process
	set_process(true)
	
func _process(delta):
	match time_state:
		TimeState.NORMAL:
			_process_normal_time(delta)
		TimeState.PAUSED:
			_process_paused_time(delta)
		TimeState.REWINDING:
			_process_rewind_time(delta)
		TimeState.FAST_FORWARD:
			_process_fast_forward_time(delta)
	
	emit_signal("time_tick", current_time)

func _process_normal_time(delta: float):
	current_time += delta
	
	# Record time state periodically
	if current_time - last_chunk_time >= time_chunk_size:
		_record_time_state()
		last_chunk_time = current_time

func _process_paused_time(delta: float):
	# Time is paused, don't advance
	pass

func _process_rewind_time(delta: float):
	current_time -= delta * rewind_speed
	if current_time < 0:
		current_time = 0
		set_time_state(TimeState.PAUSED)
	
	_restore_time_state(current_time)

func _process_fast_forward_time(delta: float):
	current_time += delta * fast_forward_speed
	_restore_time_state(current_time)

func _record_time_state():
	var state_data = {
		"time": current_time,
		"objects": {}
	}
	
	# Record state of all time objects
	for obj in time_objects:
		if obj.has_method("get_time_state"):
			state_data.objects[obj.get_instance_id()] = obj.get_time_state()
	
	time_history.append(state_data)
	
	# Keep history within limits
	if time_history.size() > max_history_length:
		time_history.pop_front()

func _restore_time_state(target_time: float):
	# Find the closest time state
	var closest_state = null
	var closest_time_diff = INF
	
	for state in time_history:
		var time_diff = abs(state.time - target_time)
		if time_diff < closest_time_diff:
			closest_time_diff = time_diff
			closest_state = state
	
	if closest_state:
		# Restore object states
		for obj in time_objects:
			if obj.has_method("set_time_state"):
				var obj_id = obj.get_instance_id()
				if obj_id in closest_state.objects:
					obj.set_time_state(closest_state.objects[obj_id])

func set_time_state(new_state: TimeState):
	time_state = new_state
	emit_signal("time_state_changed", new_state)

func register_time_object(obj: Node):
	if not obj in time_objects:
		time_objects.append(obj)

func unregister_time_object(obj: Node):
	if obj in time_objects:
		time_objects.erase(obj)

func get_time_state() -> TimeState:
	return time_state

func reset_time():
	current_time = 0.0
	time_history.clear()
	last_chunk_time = 0.0
	set_time_state(TimeState.NORMAL)

# Input handling
func _input(event):
	if event.is_action_pressed("time_pause"):
		if time_state == TimeState.PAUSED:
			set_time_state(TimeState.NORMAL)
		else:
			set_time_state(TimeState.PAUSED)
	elif event.is_action_pressed("time_rewind"):
		set_time_state(TimeState.REWINDING)
	elif event.is_action_pressed("time_forward"):
		set_time_state(TimeState.FAST_FORWARD)
	elif event.is_action_released("time_rewind") or event.is_action_released("time_forward"):
		if time_state == TimeState.REWINDING or time_state == TimeState.FAST_FORWARD:
			set_time_state(TimeState.NORMAL)