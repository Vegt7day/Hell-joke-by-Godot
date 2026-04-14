# projectiles/projectile_base.gd
extends Area2D
class_name ProjectileBase

# 信号
signal projectile_spawned
signal projectile_hit(target: Node, position: Vector2)
signal projectile_destroyed
signal projectile_recovered

# 导出属性
@export_category("基本属性")
@export var projectile_speed: float = 300.0
@export var projectile_damage: float = 10.0
@export var projectile_lifetime: float = 5.0
@export var gravity_enabled: bool = false
@export var gravity_strength: float = 98.0
@export var bounce_enabled: bool = false
@export var bounce_count: int = 3
@export var destroy_on_hit: bool = true
@export var is_recoverable: bool = true
@export var auto_recover_after_time: float = 0.0  # 0=不自动回收

# 引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particle_system: CPUParticles2D = $Particles

# 内部属性
var velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var is_active: bool = false
var owner_node: Node
var owner_team: String = ""
var hit_targets: Array[Node] = []
var current_bounce_count: int = 0
var lifetime_timer: float = 0.0
var recovery_timer: float = 0.0
var projectile_type: String = "generic"

func _ready():
	# 默认不活动
	set_active(false)
	
	# 连接信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	print("抛射体基类初始化完成: %s" % name)

func _physics_process(delta: float):
	if not is_active:
		return
	
	# 更新生命周期计时器
	if projectile_lifetime > 0:
		lifetime_timer += delta
		if lifetime_timer >= projectile_lifetime:
			destroy()
			return
	
	# 更新自动回收计时器
	if auto_recover_after_time > 0:
		recovery_timer += delta
		if recovery_timer >= auto_recover_after_time:
			recover()
			return
	
	# 应用重力
	if gravity_enabled:
		velocity.y += gravity_strength * delta
	
	# 移动抛射体
	position += velocity * delta
	
	# 更新旋转（如果需要）
	if velocity.length() > 0:
		update_rotation()

func update_rotation():
	"""更新抛射体旋转"""
	if velocity.length() > 0:
		var angle = velocity.angle()
		rotation = angle

func setup_projectile(start_position: Vector2, move_direction: Vector2, owner: Node, team: String = "", type: String = "generic"):
	"""设置抛射体初始状态"""
	position = start_position
	direction = move_direction.normalized()
	velocity = direction * projectile_speed
	owner_node = owner
	owner_team = team
	projectile_type = type
	
	# 设置激活
	set_active(true)
	
	# 重置计时器
	lifetime_timer = 0.0
	recovery_timer = 0.0
	hit_targets.clear()
	current_bounce_count = 0
	
	# 发射信号
	projectile_spawned.emit()
	
	print("抛射体设置完成: 位置=%s, 方向=%s, 速度=%s" % [position, direction, velocity])

func set_active(active: bool):
	"""设置抛射体活动状态"""
	is_active = active
	
	# 控制碰撞检测
	collision_shape.disabled = not active
	
	# 控制可见性
	visible = active
	
	# 控制物理处理
	set_physics_process(active)
	
	print("抛射体活动状态: %s" % active)

func set_movement_type(move_type: String, params: Dictionary = {}):
	"""设置移动类型"""
	match move_type:
		"straight":
			# 直线运动
			gravity_enabled = false
			print("设置直线运动")
		
		"parabolic":
			# 抛物线运动
			gravity_enabled = true
			gravity_strength = params.get("gravity", 98.0)
			print("设置抛物线运动，重力: %f" % gravity_strength)
		
		"homing":
			# 追踪目标（需要目标节点）
			gravity_enabled = false
			# 这里可以添加追踪逻辑
			print("设置追踪运动")
		
		"sinusoidal":
			# 正弦波运动
			gravity_enabled = false
			# 这里可以添加正弦波逻辑
			print("设置正弦波运动")
		
		"boomerang":
			# 回旋镖运动
			gravity_enabled = false
			print("设置回旋镖运动")

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	if not is_active:
		return
	
	# 检查是否是有效目标
	if is_valid_target(area):
		handle_collision(area, area.global_position)
	
	# 处理弹跳
	if bounce_enabled and current_bounce_count < bounce_count:
		handle_bounce(area)

func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	if not is_active:
		return
	
	# 检查是否是有效目标
	if is_valid_target(body):
		handle_collision(body, body.global_position)
	
	# 处理弹跳
	if bounce_enabled and current_bounce_count < bounce_count:
		handle_bounce(body)

func is_valid_target(target: Node) -> bool:
	"""检查是否是有效目标"""
	# 避免自碰撞
	if target == self or target == owner_node:
		return false
	
	# 避免重复击中同一目标
	if target in hit_targets:
		return false
	
	# 这里可以添加团队检测
	# 例如：if target.has_method("get_team") and target.get_team() == owner_team:
	#     return false
	
	return true

func handle_collision(target: Node, hit_position: Vector2):
	"""处理碰撞"""
	print("抛射体碰撞: 目标=%s, 位置=%s" % [target.name, hit_position])
	
	# 记录已击中的目标
	hit_targets.append(target)
	
	# 发射碰撞信号
	projectile_hit.emit(target, hit_position)
	
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(projectile_damage, projectile_type)
	
	# 如果碰撞后销毁
	if destroy_on_hit:
		destroy()
	
	# 播放碰撞效果
	play_hit_effect(hit_position)

func handle_bounce(collider: Node):
	"""处理弹跳"""
	current_bounce_count += 1
	
	# 获取碰撞法线
	var collision_point = get_collision_point(collider)
	var normal = get_collision_normal(collision_point)
	
	# 计算反射方向
	if normal != Vector2.ZERO:
		velocity = velocity.bounce(normal) * 0.8  # 减少能量
	
	print("抛射体弹跳: 剩余次数=%d" % (bounce_count - current_bounce_count))
	
	# 播放弹跳效果
	play_bounce_effect()

func get_collision_point(collider: Node) -> Vector2:
	"""获取碰撞点"""
	# 简单的碰撞点估计
	return global_position

func get_collision_normal(point: Vector2) -> Vector2:
	"""获取碰撞法线"""
	# 这里可以实现更精确的法线计算
	# 暂时使用简化版本
	return Vector2.UP

func play_hit_effect(hit_position: Vector2):
	"""播放击中效果"""
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
	
	# 触发粒子系统
	if particle_system:
		particle_system.emitting = true
		particle_system.global_position = hit_position

func play_bounce_effect():
	"""播放弹跳效果"""
	if animation_player and animation_player.has_animation("bounce"):
		animation_player.play("bounce")

func destroy():
	"""销毁抛射体"""
	print("销毁抛射体")
	
	# 播放销毁动画
	play_destroy_effect()
	
	# 发射销毁信号
	projectile_destroyed.emit()
	
	# 延迟后移除
	await get_tree().create_timer(0.5).timeout
	queue_free()

func recover():
	"""回收抛射体"""
	if not is_recoverable:
		destroy()
		return
	
	print("回收抛射体")
	
	# 播放回收动画
	play_recover_effect()
	
	# 发射回收信号
	projectile_recovered.emit()
	
	# 通知所有者
	if owner_node and owner_node.has_method("on_projectile_recovered"):
		owner_node.on_projectile_recovered(self)
	
	# 延迟后移除
	await get_tree().create_timer(0.3).timeout
	queue_free()

func play_destroy_effect():
	"""播放销毁效果"""
	if animation_player and animation_player.has_animation("destroy"):
		animation_player.play("destroy")

func play_recover_effect():
	"""播放回收效果"""
	if animation_player and animation_player.has_animation("recover"):
		animation_player.play("recover")
