extends "res://scripts/core/states/state.gd"
# 空闲状态

class_name JumpState

func _init():
	name = "jump"

func enter(data: Dictionary = {}):
	super.enter(data)
	print("进入跳跃状态")
	
	if actor and actor.animation_player:
		actor.animation_player.play("jump")

func physics_process(delta: float):
	super.physics_process(delta)
	
	# 检查是否应该转换到下落状态
	if actor.velocity.y > 0:
		transition_to("fall")
	
	# 检查是否回到地面
	if actor.is_on_floor():
		if actor.input_direction.x != 0:
			transition_to("move")
		else:
			transition_to("idle")

func exit():
	super.exit()
	print("退出跳跃状态")
