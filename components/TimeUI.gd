extends Control
class_name TimeUI

# UI elements
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var state_label: Label = $VBoxContainer/StateLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var rewind_button: Button = $VBoxContainer/ButtonContainer/RewindButton
@onready var pause_button: Button = $VBoxContainer/ButtonContainer/PauseButton
@onready var forward_button: Button = $VBoxContainer/ButtonContainer/ForwardButton
@onready var reset_button: Button = $VBoxContainer/ButtonContainer/ResetButton

# Time manager reference
var time_manager: TimeManager

func _ready():
	# Find time manager
	time_manager = get_node("/root/TimeManager")
	if time_manager:
		time_manager.time_state_changed.connect(_on_time_state_changed)
		time_manager.time_tick.connect(_on_time_tick)
	
	# Connect button signals
	if rewind_button:
		rewind_button.pressed.connect(_on_rewind_pressed)
		rewind_button.button_up.connect(_on_rewind_released)
	
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	
	if forward_button:
		forward_button.pressed.connect(_on_forward_pressed)
		forward_button.button_up.connect(_on_forward_released)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	
	# Initialize UI
	_update_ui()

func _update_ui():
	if not time_manager:
		return
	
	# Update time display
	if time_label:
		var time_text = "Time: %.2f" % time_manager.current_time
		time_label.text = time_text
	
	# Update state display
	if state_label:
		var state_text = "State: "
		match time_manager.get_time_state():
			TimeManager.TimeState.NORMAL:
				state_text += "Normal"
			TimeManager.TimeState.PAUSED:
				state_text += "Paused"
			TimeManager.TimeState.REWINDING:
				state_text += "Rewinding"
			TimeManager.TimeState.FAST_FORWARD:
				state_text += "Fast Forward"
		state_label.text = state_text
	
	# Update progress bar (time history)
	if progress_bar:
		var max_time = 60.0  # 60 seconds max
		progress_bar.max_value = max_time
		progress_bar.value = min(time_manager.current_time, max_time)
	
	# Update button states
	if pause_button:
		if time_manager.get_time_state() == TimeManager.TimeState.PAUSED:
			pause_button.text = "Resume"
		else:
			pause_button.text = "Pause"

func _on_time_state_changed(new_state: TimeManager.TimeState):
	_update_ui()

func _on_time_tick(current_time: float):
	_update_ui()

func _on_rewind_pressed():
	if time_manager:
		time_manager.set_time_state(TimeManager.TimeState.REWINDING)

func _on_rewind_released():
	if time_manager and time_manager.get_time_state() == TimeManager.TimeState.REWINDING:
		time_manager.set_time_state(TimeManager.TimeState.NORMAL)

func _on_pause_pressed():
	if time_manager:
		if time_manager.get_time_state() == TimeManager.TimeState.PAUSED:
			time_manager.set_time_state(TimeManager.TimeState.NORMAL)
		else:
			time_manager.set_time_state(TimeManager.TimeState.PAUSED)

func _on_forward_pressed():
	if time_manager:
		time_manager.set_time_state(TimeManager.TimeState.FAST_FORWARD)

func _on_forward_released():
	if time_manager and time_manager.get_time_state() == TimeManager.TimeState.FAST_FORWARD:
		time_manager.set_time_state(TimeManager.TimeState.NORMAL)

func _on_reset_pressed():
	if time_manager:
		time_manager.reset_time()

func show_time_controls(show: bool):
	visible = show

func set_time_display_format(format: String):
	# Allow customization of time display format
	pass