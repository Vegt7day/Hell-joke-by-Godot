extends "res://scripts/core/states/state.gd"
# 空闲状态

class_name MoveState

func _init():
	name = "move"

func enter(data: Dictionary = {}):
	super.enter(data)
	print("进入移动状态")
	
	if actor and actor.animation_player:
		actor.animation_player.play("run")

func physics_process(delta: float):
	super.physics_process(delta)
	
	# 检查是否应该转换到空闲状态
	if actor.input_direction.x == 0:
		transition_to("idle")
	
	# 检查是否在地面
	if not actor.is_on_floor():
		transition_to("fall")

func input(event: InputEvent):
	super.input(event)
	
	# 处理跳跃输入
	if event.is_action_pressed("jump") and actor.is_on_floor():
		transition_to("jump")
	
	# 处理攻击输入
	if event.is_action_pressed("attack_q"):
		print("移动中Q键按下")
	elif event.is_action_pressed("attack_j"):
		print("移动中J键按下")

func exit():
	super.exit()
	print("退出移动状态")
