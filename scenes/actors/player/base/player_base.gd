extends CharacterBody2D
# 玩家基类

class_name PlayerBase

# 信号
signal health_changed(old_health: float, new_health: float)
signal ink_changed(old_ink: float, new_ink: float)
signal player_died(cause: String)
signal player_respawned
signal limb_changed(limb_name: String, active: bool)

# 导出属性
@export_category("基础属性")
@export var max_health: float = 100.0
@export var max_ink: float = 100.0
@export var move_speed: float = 200.0
@export var jump_force: float = 350.0
@export var gravity: float = 980.0

# 引用
@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: Node = $StateMachine

# 当前属性
var health: float = 100.0
var ink: float = 100.0
var is_alive: bool = true
var can_move: bool = true
var facing_direction: float = 1.0
var input_direction: Vector2 = Vector2.ZERO
var checkpoint_position: Vector2 = Vector2.ZERO

# 肢体系统
var limbs: Dictionary = {
	"pen": {"active": true, "color": Color.WHITE, "durability": 100.0},
	"left_shoe": {"active": true, "position": Vector2.ZERO, "thrown": false},
	"right_shoe": {"active": true, "position": Vector2.ZERO, "thrown": false},
	"book": {"active": false, "pages": 0, "max_pages": 10}
}
var active_limb: String = "pen"

func _ready():
	print("玩家基类初始化: %s" % name)
	
	# 初始化属性
	health = max_health
	ink = max_ink
	checkpoint_position = global_position
	
	# 设置物理处理
	set_physics_process(true)
	
	print("玩家基类初始化完成")

func _physics_process(delta: float):
	if not is_alive or not can_move:
		return
	
	# 处理输入
	handle_input()
	
	# 应用重力
	apply_gravity(delta)
	
	# 处理移动
	handle_movement(delta)
	
	# 处理跳跃
	handle_jump()
	
	# 移动角色
	move_and_slide()
	
	# 更新动画
	update_animation()

func handle_input():
	"""处理输入"""
	if not can_move:
		return
	
	# 获取输入方向
	input_direction.x = Input.get_axis("move_left", "move_right")
	
	# 更新面向方向
	if input_direction.x != 0:
		facing_direction = sign(input_direction.x)

	# 处理Q键：切换肢体
	if Input.is_action_just_pressed("attack_q"):
		switch_limb()
	
	# 处理J键：使用当前肢体
	if Input.is_action_just_pressed("attack_j"):
		use_active_limb()
	
	# 处理R键：回收
	if Input.is_action_just_pressed("reload_r"):
		recover_limbs()

func handle_movement(delta: float):
	"""处理移动"""
	if input_direction.x != 0:
		velocity.x = input_direction.x * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

func apply_gravity(delta: float):
	"""应用重力"""
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump():
	"""处理跳跃"""
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
		print("执行跳跃")

func switch_limb():
	"""切换肢体"""
	print("切换肢体")
	
	var limb_keys = limbs.keys()
	var current_index = limb_keys.find(active_limb)
	
	if current_index == -1:
		active_limb = limb_keys[0]
	else:
		var next_index = (current_index + 1) % limb_keys.size()
		active_limb = limb_keys[next_index]
	
	print("切换到肢体: %s" % active_limb)

func use_active_limb():
	"""使用当前活动肢体"""
	print("使用肢体: %s" % active_limb)
	
	match active_limb:
		"pen":
			use_pen()
		"left_shoe", "right_shoe":
			use_shoe(active_limb)
		"book":
			use_book()
		_:
			print("未知肢体: %s" % active_limb)

func recover_limbs():
	"""回收肢体"""
	print("回收肢体")

func use_pen():
	"""使用笔"""
	print("使用笔")

func use_shoe(shoe_name: String):
	"""使用鞋"""
	print("使用鞋: %s" % shoe_name)

func use_book():
	"""使用课本"""
	print("使用课本")

func take_damage(amount: float, source: String = "unknown"):
	"""受到伤害"""
	if not is_alive:
		return
	
	var old_health = health
	health = max(0, health - amount)
	health_changed.emit(old_health, health)
	
	print("受到伤害: %f, 来源: %s, 剩余生命: %f" % [amount, source, health])
	
	if health <= 0:
		die(source)

func die(cause: String = "unknown"):
	"""死亡"""
	if not is_alive:
		return
	
	is_alive = false
	can_move = false
	
	print("玩家死亡，原因: %s" % cause)
	
	player_died.emit(cause)
	
	# 等待后重生
	await get_tree().create_timer(2.0).timeout
	respawn()

func respawn():
	"""重生"""
	print("玩家重生")
	
	health = max_health
	ink = max_ink
	is_alive = true
	can_move = true
	
	# 恢复到检查点
	global_position = checkpoint_position
	
	player_respawned.emit()
	
	print("重生完成")

func update_animation():
	"""更新动画"""
	if not animation_player:
		return
	
	var animation_name = ""
	
	if not is_alive:
		animation_name = "death"
	elif not is_on_floor():
		animation_name = "jump" if velocity.y < 0 else "fall"
	elif abs(velocity.x) > 10:
		animation_name = "run"
	else:
		animation_name = "idle"
	
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)

func set_checkpoint(position: Vector2, checkpoint_id: String = "default"):
	"""设置检查点"""
	checkpoint_position = position
	print("检查点设置: %s" % checkpoint_id)
