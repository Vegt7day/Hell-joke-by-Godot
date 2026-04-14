extends Node
# 输入管理器

signal input_action_pressed(action: String)
signal input_action_released(action: String)
signal input_device_changed(device_type: String)
signal input_mode_changed(mode: String)  # keyboard, gamepad, touch

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }

var current_input_mode: InputMode = InputMode.KEYBOARD
var action_states: Dictionary = {}
var action_callbacks: Dictionary = {}

static var instance: Node

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("InputManager 已加载")
	
	# 初始化所有动作状态
	for action in InputMap.get_actions():
		action_states[action] = false
		action_callbacks[action] = {
			"pressed": [],
			"released": []
		}
	
	set_process(true)

func _process(_delta):
	# 检查所有动作的状态变化
	for action in action_states.keys():
		var is_pressed = Input.is_action_pressed(action)
		var was_pressed = action_states[action]
		
		if is_pressed and not was_pressed:
			action_states[action] = true
			emit_signal("input_action_pressed", action)
			_call_action_callbacks(action, "pressed")
		elif not is_pressed and was_pressed:
			action_states[action] = false
			emit_signal("input_action_released", action)
			_call_action_callbacks(action, "released")

func register_action_callback(action: String, event_type: String, callback: Callable):
	# event_type: "pressed" 或 "released"
	if action in action_callbacks and event_type in action_callbacks[action]:
		action_callbacks[action][event_type].append(callback)

func _call_action_callbacks(action: String, event_type: String):
	if action in action_callbacks and event_type in action_callbacks[action]:
		for callback in action_callbacks[action][event_type]:
			if callback.is_valid():
				callback.call(action)

func get_action_strength(action: String) -> float:
	return Input.get_action_strength(action)

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_released(action: String) -> bool:
	return Input.is_action_just_released(action)

func vibrate_controller(weak_magnitude: float, strong_magnitude: float, duration: float = 0.5):
	# 手柄震动
	if Input.get_connected_joypads().size() > 0:
		Input.start_joy_vibration(0, weak_magnitude, strong_magnitude, duration)
