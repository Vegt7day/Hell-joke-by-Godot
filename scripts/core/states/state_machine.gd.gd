# 文件: scripts/core/states/state_machine.gd
extends Node
# 状态机

class_name StateMachine

# 信号
signal state_changed(old_state: String, new_state: String)
signal transition_started(from_state: String, to_state: String)
signal transition_completed(to_state: String)

# 属性
@export var initial_state: String = "idle"
@export var debug_mode: bool = false

# 状态
var states: Dictionary = {}
var current_state: Node
var previous_state: String = ""
var state_history: Array[String] = []
var actor: Node
var is_transitioning: bool = false

func _ready():
	actor = get_parent()
	setup_states()
	start()

func setup_states():
	"""初始化所有子状态节点"""
	for child in get_children():
		# 检查是否是State类型
		var script = child.get_script()
		if script and "State" in script.resource_path:
			child.setup(self, actor)
			states[child.name.to_lower()] = child
			child.transition_requested.connect(_on_state_transition_requested)
	
	print("状态机初始化完成，状态数量: %d" % states.size())

func start():
	"""启动状态机"""
	if initial_state in states:
		transition_to(initial_state)
	else:
		push_error("初始状态不存在: %s" % initial_state)

func transition_to(state_name: String, data: Dictionary = {}):
	"""转换到指定状态"""
	if is_transitioning:
		print("警告：正在状态转换中，请等待")
		return
	
	var new_state = states.get(state_name.to_lower())
	if not new_state:
		print("错误：状态不存在: %s" % state_name)
		return
	
	if current_state and current_state.name == new_state.name:
		if debug_mode:
			print("已在目标状态: %s" % state_name)
		return
	
	is_transitioning = true
	
	# 记录状态历史
	if current_state:
		state_history.append(current_state.name)
		if state_history.size() > 10:  # 限制历史长度
			state_history.pop_front()
	
	var old_state_name = current_state.name if current_state else "none"
	
	emit_signal("transition_started", old_state_name, state_name)
	
	if debug_mode:
		print("状态转换: %s -> %s" % [old_state_name, state_name])
	
	# 退出当前状态
	if current_state:
		current_state.exit()
	
	# 更新状态
	previous_state = old_state_name
	current_state = new_state
	
	# 进入新状态
	current_state.enter(data)
	
	emit_signal("state_changed", previous_state, state_name)
	emit_signal("transition_completed", state_name)
	
	is_transitioning = false

func get_state(state_name: String) -> Node:
	"""获取状态实例"""
	return states.get(state_name.to_lower())

func get_current_state_name() -> String:
	"""获取当前状态名称"""
	return current_state.name if current_state else "none"

func is_in_state(state_name: String) -> bool:
	"""检查是否在指定状态"""
	return current_state and current_state.name.to_lower() == state_name.to_lower()

func can_transition_to(state_name: String) -> bool:
	"""检查是否可以转换到指定状态"""
	return state_name in states and not is_transitioning

func go_back():
	"""返回到上一个状态"""
	if state_history.size() > 0:
		var previous = state_history.pop_back()
		transition_to(previous)
		return true
	return false

func _on_state_transition_requested(state_name: String, data: Dictionary = {}):
	"""处理状态转换请求"""
	transition_to(state_name, data)

func _process(delta: float):
	if current_state:
		current_state.process(delta)

func _physics_process(delta: float):
	if current_state:
		current_state.physics_process(delta)

func _input(event: InputEvent):
	if current_state:
		current_state.input(event)

func _unhandled_input(event: InputEvent):
	if current_state:
		current_state.unhandled_input(event)
