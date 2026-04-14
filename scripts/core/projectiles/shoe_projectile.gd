# 位置: projectiles/shoe_projectile.gd
extends Area2D
class_name ShoeProjectile

# 信号
signal projectile_landed(position: Vector2)
signal projectile_recovered()

# 属性
@export var upward_speed: float = 400.0
@export var gravity_strength: float = 600.0
@export var invincible_time: float = 0.5  # 发射后0.5秒内不能拾取
@export var rotation_speed: float = 2.0
@export var bounce_height: float = 100.0  # 向上弹起的高度

var is_active: bool = false
var shoe_owner: String = ""  # "left_shoe" 或 "right_shoe"
var has_landed: bool = false
var can_be_picked_up: bool = false
var owner_node: Node = null
var invincible_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_shape: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var light_2d: Light2D = $Light2D

# 内部属性
var velocity: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var max_height_reached: bool = false
var return_timer: float = 0.0
var return_duration: float = 1.0  # 返回过程持续时间

func _ready():
	set_active(false)
	
	# 连接信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# 拾取区域信号
	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)
		pickup_area.body_entered.connect(_on_pickup_body_entered)
		pickup_area.monitoring = false
		pickup_area.monitorable = false
		if pickup_shape:
			pickup_shape.disabled = true
	
	# 灯光
	if light_2d:
		light_2d.visible = false
	
	print("鞋抛射体初始化完成")

func _physics_process(delta: float):
	if not is_active or has_landed:
		return
	
	# 更新计时器
	invincible_timer += delta
	
	# 第一阶段：向上运动
	if not max_height_reached:
		# 应用重力
		velocity.y -= gravity_strength * delta
		
		# 向上移动
		position += velocity * delta
		
		# 检查是否到达最高点
		if position.y <= start_position.y - bounce_height:
			max_height_reached = true
			velocity.y = 0
			print("到达最高点，开始下落")
	
	# 第二阶段：向下运动
	else:
		return_timer += delta
		
		# 使用缓动函数平滑返回
		var progress = clamp(return_timer / return_duration, 0, 1)
		var ease_value = ease_out_quad(progress)  # 使用缓出函数
		
		# 计算当前位置
		var current_height = bounce_height * (1.0 - ease_value)
		position.y = start_position.y - current_height
		
		# 更新旋转
		if rotation_speed > 0:
			rotation = progress * PI * 2 * rotation_speed
		
		# 检查是否返回起点
		if progress >= 1.0:
			position = start_position
			has_landed = true
			set_physics_process(false)
			
			# 等待无敌时间过后再启用拾取
			if invincible_timer >= invincible_time:
				enable_pickup()
			else:
				# 如果还没到无敌时间，设置一个定时器
				var remaining_time = invincible_time - invincible_timer
				if remaining_time > 0:
					await get_tree().create_timer(remaining_time).timeout
					enable_pickup()
			
			# 发射落地信号
			projectile_landed.emit(global_position)
			print("鞋已返回起点: %s" % shoe_owner)
	
	# 检查是否可以拾取
	if invincible_timer >= invincible_time and not can_be_picked_up and has_landed:
		enable_pickup()

func ease_out_quad(x: float) -> float:
	"""二次缓出函数"""
	return 1 - (1 - x) * (1 - x)

func setup_shoe(start_position: Vector2, move_direction: Vector2, owner: Node, shoe_name: String, params: Dictionary = {}):
	"""设置鞋抛射体"""
	print("设置鞋抛射体: %s" % shoe_name)
	
	self.start_position = start_position
	global_position = start_position
	shoe_owner = shoe_name
	owner_node = owner
	
	# 重置状态
	has_landed = false
	max_height_reached = false
	can_be_picked_up = false
	invincible_timer = 0.0
	return_timer = 0.0
	
	# 应用参数
	if "upward_speed" in params:
		upward_speed = params.upward_speed
	if "gravity" in params:
		gravity_strength = params.gravity
	if "bounce_height" in params:
		bounce_height = params.bounce_height
	if "rotation_speed" in params:
		rotation_speed = params.rotation_speed
	if "invincible_time" in params:
		invincible_time = params.invincible_time
	if "return_duration" in params:
		return_duration = params.return_duration
	
	# 设置初始向上速度
	velocity = Vector2(0, -upward_speed)
	
	# 设置激活
	set_active(true)
	
	print("鞋抛射体设置完成: 所有者=%s, 起始位置=%s" % [shoe_name, start_position])
	return self

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	if not is_active or has_landed:
		return
	
	print("鞋抛射体与区域碰撞: %s" % area.name)
	
	# 这里不处理碰撞，因为我们是垂直运动

func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	if not is_active or has_landed:
		return
	
	print("鞋抛射体与物体碰撞: %s" % body.name)
	
	# 这里不处理碰撞，因为我们是垂直运动

func enable_pickup():
	"""启用拾取"""
	if can_be_picked_up:
		return
	
	print("鞋可拾取: %s" % shoe_owner)
	
	can_be_picked_up = true
	
	# 启用拾取区域
	if pickup_area:
		pickup_area.monitoring = true
		pickup_area.monitorable = true
		if pickup_shape:
			pickup_shape.disabled = false
	
	# 显示发光效果
	if light_2d:
		light_2d.visible = true
		# 添加闪烁动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(light_2d, "energy", 1.0, 0.5)
		tween.tween_property(light_2d, "energy", 0.5, 0.5)
	
	# 添加轻微的上下浮动效果
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", position.y - 3, 0.6)
	float_tween.tween_property(self, "position:y", position.y, 0.6)

func _on_pickup_area_entered(area: Area2D):
	"""拾取区域进入（区域）"""
	_on_pickup_entered(area)

func _on_pickup_body_entered(body: PhysicsBody2D):
	"""拾取区域进入（物理体）"""
	_on_pickup_entered(body)

func _on_pickup_entered(node: Node):
	"""处理拾取"""
	if not can_be_picked_up:
		print("鞋还不能被拾取（无敌时间）")
		return
	
	# 检查是否是玩家
	var player = node
	if node is Area2D or node is CollisionShape2D:
		player = node.get_parent()
	
	print("尝试拾取鞋: %s, 拾取者: %s" % [shoe_owner, player.name if player else "未知"])
	
	if player and player.has_method("pickup_shoe"):
		print("玩家有pickup_shoe方法")
		if player.pickup_shoe(shoe_owner, self):
			print("拾取成功: %s" % shoe_owner)
			# 被拾取，回收
			recover()
		else:
			print("拾取失败: pickup_shoe返回false")
	else:
		print("不是玩家或没有pickup_shoe方法: %s" % (player.name if player else "无父节点"))

func recover():
	"""回收抛射体"""
	print("回收鞋抛射体: %s" % shoe_owner)
	
	is_active = false
	has_landed = true
	
	# 播放回收动画
	if animation_player and animation_player.has_animation("recover"):
		animation_player.play("recover")
		await animation_player.animation_finished
	
	# 发射回收信号
	projectile_recovered.emit()
	
	queue_free()

func set_active(active: bool):
	"""设置活动状态"""
	is_active = active
	
	# 控制碰撞检测
	if collision_shape:
		collision_shape.disabled = not active
	
	# 控制可见性
	visible = active
	
	# 控制物理处理
	set_physics_process(active)
	
	print("鞋抛射体活动状态: %s" % active)
