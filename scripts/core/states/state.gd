# 文件: scripts/core/states/state.gd
extends Node
# 状态基类

class_name State

# 信号
signal state_entered
signal state_exited
signal transition_requested(state_name: String, data: Dictionary  )

# 引用
var state_machine: Node
var actor: Node

func _init():
	# 基础状态
	name = "BaseState"
	set_process_mode(PROCESS_MODE_DISABLED)

func setup(_state_machine: Node, _actor: Node):
	state_machine = _state_machine
	actor = _actor
	print("状态初始化: %s" % name)

func enter(data: Dictionary = {}):
	"""进入状态"""
	print("进入状态: %s" % name)
	set_process(true)
	set_physics_process(true)
	state_entered.emit()

func exit():
	"""退出状态"""
	print("退出状态: %s" % name)
	set_process(false)
	set_physics_process(false)
	state_exited.emit()

func process(delta: float):
	"""每帧调用"""
	pass

func physics_process(delta: float):
	"""物理帧调用"""
	pass

func input(event: InputEvent):
	"""输入处理"""
	pass

func unhandled_input(event: InputEvent):
	"""未处理的输入"""
	pass

func transition_to(state_name: String, data: Dictionary = {}):
	"""请求状态转换"""
	transition_requested.emit(state_name, data)
