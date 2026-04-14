# 位置: projectiles/shoe_projectile.gd
extends Area2D
class_name ShoeProjectile

# 信号
signal projectile_hit(target: Node, position: Vector2)
signal projectile_destroyed
signal projectile_recovered
signal projectile_landed(position: Vector2)

# 属性
@export var speed: float = 400.0
@export var damage: float = 20.0
@export var lifetime: float = 10.0
@export var gravity_strength: float = 600.0
@export var bounce_count: int = 2
@export var invincible_time: float = 0.5  # 发射后0.5秒内不能拾取
@export var rotation_speed: float = 2.0
@export var trail_enabled: bool = true
@export var trail_color: Color = Color(0.6, 0.4, 0.2, 0.8)

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = false
var shoe_owner: String = ""  # "left_shoe" 或 "right_shoe"
var has_landed: bool = false
var is_stuck: bool = false
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
var lifetime_timer: float = 0.0
var current_bounce_count: int = 0
var hit_targets: Array[Node] = []

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
	if not is_active or has_landed or is_stuck:
		return
	
	# 更新计时器
	lifetime_timer += delta
	invincible_timer += delta
	
	# 检查生命周期
	if lifetime_timer >= lifetime:
		destroy()
		return
	
	# 应用重力
	velocity.y += gravity_strength * delta
	
	# 移动
	position += velocity * delta
	
	# 更新旋转
	if velocity.length() > 0:
		update_rotation()
	
	# 检查是否可以拾取
	if invincible_timer >= invincible_time and not can_be_picked_up:
		enable_pickup()

func update_rotation():
	"""更新旋转"""
	var angle = velocity.angle()
	rotation = angle
	
	# 添加旋转效果
	if rotation_speed > 0:
		rotation += lifetime_timer * rotation_speed * PI

func setup_shoe(start_position: Vector2, move_direction: Vector2, owner: Node, shoe_name: String, params: Dictionary = {}):
	"""设置鞋抛射体"""
	print("设置鞋抛射体: %s" % shoe_name)
	
	global_position = start_position
	direction = move_direction.normalized()
	shoe_owner = shoe_name
	owner_node = owner
	
	# 重置状态
	has_landed = false
	is_stuck = false
	can_be_picked_up = false
	lifetime_timer = 0.0
	invincible_timer = 0.0
	current_bounce_count = 0
	hit_targets.clear()
	
	# 应用参数
	if "throw_power" in params:
		speed = speed * params.throw_power
	if "damage" in params:
		damage = params.damage
	if "bounce_count" in params:
		bounce_count = params.bounce_count
	if "rotation_speed" in params:
		rotation_speed = params.rotation_speed
	if "invincible_time" in params:
		invincible_time = params.invincible_time
	if "trail_color" in params:
		trail_color = params.trail_color
	if "gravity" in params:
		gravity_strength = params.gravity
	
	# 计算初速度 - 抛物线
	var horizontal_speed = speed * direction.x
	var vertical_speed = -abs(speed * direction.y) - 200.0  # 向上弹
	
	velocity = Vector2(horizontal_speed, vertical_speed)
	
	# 如果direction.y是负数（向下扔），调整垂直速度
	if direction.y > 0:
		velocity.y = speed * direction.y * 0.5
	else:
		velocity.y = speed * direction.y - 150.0  # 确保向上弹
	
	# 设置激活
	set_active(true)
	
	print("鞋抛射体设置完成: 所有者=%s, 速度=%s, 向上弹力=%s" % [shoe_name, velocity, -abs(speed * direction.y) - 200.0])
	return self

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	if not is_active or has_landed or is_stuck:
		return
	
	print("鞋抛射体与区域碰撞: %s" % area.name)
	
	# 检查是否是地面或墙壁
	# 方法1: 检查父节点是否是TileMap
	var parent = area.get_parent()
	var is_ground = false
	
	# 检查是否是TileMap
	if parent and parent is TileMap:
		is_ground = true
	# 方法2: 检查是否在地面组中
	elif area.is_in_group("ground"):
		is_ground = true
	# 方法3: 检查是否是StaticBody2D并且不是玩家

	if is_ground:
		handle_ground_collision(area, area.global_position)
	elif is_valid_target(area):
		handle_collision(area, area.global_position)
	
	# 处理弹跳
	if bounce_enabled() and current_bounce_count < bounce_count and not is_stuck:
		handle_bounce(area)
# 添加 body_entered 信号处理
func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	if not is_active or has_landed or is_stuck:
		return
	
	print("鞋抛射体与物体碰撞: %s" % body.name)
	
	var is_ground = false
	

	# 检查是否是StaticBody2D并且不是玩家
	if body is StaticBody2D and not body.is_in_group("player"):
		is_ground = true
	
	if is_ground:
		handle_ground_collision(body, body.global_position)
	elif is_valid_target(body):
		handle_collision(body, body.global_position)
	
	# 处理弹跳
	if bounce_enabled() and current_bounce_count < bounce_count and not is_stuck:
		handle_bounce(body)
func bounce_enabled() -> bool:
	"""检查是否允许弹跳"""
	return bounce_count > 0 and not has_landed

func handle_ground_collision(surface: Node, position: Vector2):
	"""处理地面碰撞"""
	print("鞋抛射体碰撞到地面")
	
	# 停止运动
	velocity = Vector2.ZERO
	has_landed = true
	is_stuck = true
	
	# 稍微调整位置，使其看起来在地面上
	global_position.y = position.y - 8
	
	# 停止物理处理
	set_physics_process(false)
	
	# 等待无敌时间过后再启用拾取
	if invincible_timer >= invincible_time:
		enable_pickup()
	
	# 发射落地信号
	projectile_landed.emit(global_position)
	
	# 重置生命周期计时器，允许长时间停留
	lifetime = 30.0  # 延长生命周期，给玩家时间拾取
	
	print("鞋已落地，位置: %s" % global_position)

func is_valid_target(target: Node) -> bool:
	"""检查是否是有效目标"""
	# 避免自碰撞
	if target == self:
		return false
	
	# 避免重复击中同一目标
	if target in hit_targets:
		return false
	
	# 避免击中所有者
	if target == owner_node:
		return false
	
	return true

func handle_collision(target: Node, hit_position: Vector2):
	"""处理碰撞"""
	print("鞋碰撞: 目标=%s, 鞋=%s" % [target.name, shoe_owner])
	
	# 记录已击中的目标
	hit_targets.append(target)
	
	# 发射碰撞信号
	projectile_hit.emit(target, hit_position)
	
	# 应用伤害
	if target.has_method("take_damage"):
		print("对目标 %s 造成 %s 点伤害" % [target.name, damage])
		target.take_damage(damage, "shoe")
	
	# 如果是地面或墙壁，粘在上面
	if target is TileMap or target is StaticBody2D:
		stick_to_surface(target, hit_position)
	else:
		# 非墙壁目标，继续运动
		pass

func handle_bounce(collider: Node):
	"""处理弹跳"""
	current_bounce_count += 1
	
	print("鞋弹跳: 第%d次" % current_bounce_count)
	
	# 计算反弹方向
	var normal = Vector2.UP
	velocity = velocity.bounce(normal) * 0.7  # 反弹并减少能量
	
	# 添加一些随机性
	velocity.x *= randf_range(0.9, 1.1)
	
	# 如果反弹次数用完，降低重力
	if current_bounce_count >= bounce_count:
		gravity_strength = 200.0  # 降低重力，使落地更平缓

func stick_to_surface(surface: Node, position: Vector2):
	"""粘在表面上"""
	print("鞋粘在表面上")
	
	# 停止运动
	velocity = Vector2.ZERO
	has_landed = true
	is_stuck = true
	
	# 固定在位置
	global_position = position
	
	# 停止物理处理
	set_physics_process(false)
	
	# 等待无敌时间过后再启用拾取
	if invincible_timer >= invincible_time:
		enable_pickup()
	
	# 发射落地信号
	projectile_landed.emit(global_position)
	
	# 延长生命周期
	lifetime = 30.0

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
	float_tween.tween_property(self, "position:y", position.y - 2, 0.8)
	float_tween.tween_property(self, "position:y", position.y, 0.8)

func _on_pickup_area_entered(area: Area2D):
	"""拾取区域进入（区域）"""
	#print("拾取区域进入（区域）: %s" % area.name)
	_on_pickup_entered(area)

func _on_pickup_body_entered(body: PhysicsBody2D):
	"""拾取区域进入（物理体）"""
	#print("拾取区域进入（物理体）: %s" % body.name)
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

func destroy():
	"""销毁抛射体"""
	print("销毁鞋抛射体")
	
	is_active = false
	has_landed = true
	
	# 播放销毁动画
	if animation_player and animation_player.has_animation("destroy"):
		animation_player.play("destroy")
		await animation_player.animation_finished
	
	# 发射销毁信号
	projectile_destroyed.emit()
	
	queue_free()

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
