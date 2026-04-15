extends Area2D
class_name ProjectileBase

# 信号
signal projectile_spawned
signal projectile_hit(target: Node, position: Vector2)
signal projectile_destroyed
signal projectile_recovered
signal projectile_trigger_mechanism(mechanism: Node, position: Vector2)  # 新增：触发机关信号

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

# 新增：攻击性控制属性
@export_category("攻击性控制")
@export var is_offensive: bool = true  # 是否有攻击性，能否触发机关
@export var can_trigger_mechanisms: bool = true  # 是否能触发机关
@export var trigger_mechanism_on_contact: bool = true  # 是否在接触时触发机关
@export var trigger_mechanism_on_destroy: bool = false  # 是否在销毁时触发机关
@export var mechanism_trigger_cooldown: float = 0.2  # 触发机关的冷却时间
@export var can_damage_players: bool = true  # 是否能伤害玩家
@export var can_damage_enemies: bool = true  # 是否能伤害敌人
@export var can_damage_objects: bool = true  # 是否能伤害物体
@export var can_damage_mechanisms: bool = true  # 是否能伤害机关
@export var damage_multiplier: Dictionary = {  # 伤害倍数
	"player": 1.0,
	"enemy": 1.0,
	"mechanism": 1.0,
	"object": 1.0
}

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
var triggered_mechanisms: Array[Node] = []  # 新增：已触发的机关列表
var current_bounce_count: int = 0
var lifetime_timer: float = 0.0
var recovery_timer: float = 0.0
var trigger_cooldown_timer: float = 0.0  # 新增：触发冷却计时器
var projectile_type: String = "generic"
var is_trigger_cooldown: bool = false  # 新增：是否在触发冷却中

func _ready():
	# 默认不活动
	set_active(false)
	
	# 连接信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	print("抛射体基类初始化完成: %s, 攻击性: %s" % [name, is_offensive])

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
	
	# 更新触发冷却计时器
	if is_trigger_cooldown:
		trigger_cooldown_timer += delta
		if trigger_cooldown_timer >= mechanism_trigger_cooldown:
			is_trigger_cooldown = false
			trigger_cooldown_timer = 0.0
	
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
	trigger_cooldown_timer = 0.0
	
	# 清空列表
	hit_targets.clear()
	triggered_mechanisms.clear()
	current_bounce_count = 0
	is_trigger_cooldown = false
	
	# 发射信号
	projectile_spawned.emit()
	
	print("抛射体设置完成: 位置=%s, 方向=%s, 速度=%s, 攻击性=%s" % [position, direction, velocity, is_offensive])

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

func set_offensive_state(offensive: bool, can_trigger: bool = true):
	"""设置抛射体的攻击性状态"""
	is_offensive = offensive
	can_trigger_mechanisms = can_trigger
	
	print("抛射体攻击性状态: 攻击性=%s, 可触发机关=%s" % [offensive, can_trigger])

func set_damage_filter(can_damage_player: bool, can_damage_enemy: bool, can_damage_object: bool, can_damage_mechanism: bool):
	"""设置伤害过滤器"""
	can_damage_players = can_damage_player
	can_damage_enemies = can_damage_enemy
	can_damage_objects = can_damage_object
	can_damage_mechanisms = can_damage_mechanism
	
	print("抛射体伤害过滤器: 玩家=%s, 敌人=%s, 物体=%s, 机关=%s" % [can_damage_player, can_damage_enemy, can_damage_object, can_damage_mechanism])

func set_damage_multiplier(target_type: String, multiplier: float):
	"""设置对特定类型目标的伤害倍数"""
	if target_type in ["player", "enemy", "mechanism", "object"]:
		damage_multiplier[target_type] = multiplier
		print("设置伤害倍数: %s=%f" % [target_type, multiplier])

func get_target_type(target: Node) -> String:
	"""获取目标类型"""
	if target.is_in_group("player"):
		return "player"
	elif target.is_in_group("enemy"):
		return "enemy"
	elif target is Mechanism or target.has_method("get_mechanism_data"):
		return "mechanism"
	elif target.is_in_group("wall"):
		return "wall"
	elif target.is_in_group("ground"):
		return "ground"
	elif target.is_in_group("environment"):  # 环境物体
		return "environment"
	else:
		return "object"
		
func can_damage_target_type(target_type: String) -> bool:
	"""检查是否可以伤害特定类型的目标"""
	match target_type:
		"player":
			return can_damage_players
		"enemy":
			return can_damage_enemies
		"mechanism":
			return can_damage_mechanisms
		"wall", "ground", "environment":
			return false  # 墙壁和地面通常不受伤害
		"object":
			return can_damage_objects
		_:
			return false

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	if not is_active or is_trigger_cooldown:
		return
	
	# 检查是否是有效目标
	if is_valid_target(area):
		handle_collision(area, area.global_position)
	
	# 处理弹跳
	if bounce_enabled and current_bounce_count < bounce_count:
		handle_bounce(area)

func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	if not is_active or is_trigger_cooldown:
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
	
	# 获取目标类型
	var target_type = get_target_type(target)
	
	# 如果抛射体没有攻击性，且目标是玩家、敌人、机关，则不作为有效伤害目标
	if not is_offensive and target_type in ["player", "enemy", "mechanism"]:
		# 但仍然可以触发机关
		if target_type == "mechanism" and can_trigger_mechanisms:
			return true
		return false
	
	# 检查是否可以伤害该类型目标
	if not can_damage_target_type(target_type):
		return false
	
	return true
func handle_collision(target: Node, hit_position: Vector2):
	"""处理碰撞"""
	print("抛射体碰撞: 目标=%s(%s), 位置=%s, 攻击性=%s" % [target.name, get_target_type(target), hit_position, is_offensive])
	
	# 记录已击中的目标
	hit_targets.append(target)
	
	# 发射碰撞信号
	projectile_hit.emit(target, hit_position)
	
	# 获取目标类型
	var target_type = get_target_type(target)
	
	# 处理墙壁和地面碰撞
	if target_type in ["wall", "ground", "environment"]:
		handle_environment_collision(target, hit_position)
		return
	
	# 处理机关触发
	if target_type == "mechanism" and can_trigger_mechanisms and trigger_mechanism_on_contact:
		trigger_mechanism(target, hit_position)
	
	# 处理伤害
	if is_offensive and can_damage_target_type(target_type):
		apply_damage(target, target_type)
	
	# 如果碰撞后销毁
	if destroy_on_hit:
		destroy()
	
	# 播放碰撞效果
	play_hit_effect(hit_position)
	
	# 开始触发冷却
	if mechanism_trigger_cooldown > 0:
		start_trigger_cooldown()

func handle_environment_collision(target: Node, hit_position: Vector2):
	"""处理环境物体（墙壁、地面）碰撞"""
	var target_type = get_target_type(target)
	print("抛射体与环境物体碰撞: %s, 位置=%s" % [target_type, hit_position])
	
	# 播放碰撞效果
	play_hit_effect(hit_position)
	
	# 如果与墙壁/地面碰撞后销毁
	if destroy_on_hit:
		destroy()

func trigger_mechanism(mechanism: Node, position: Vector2):
	"""触发机关"""
	# 避免重复触发同一机关
	if mechanism in triggered_mechanisms:
		return
	
	# 标记为已触发
	triggered_mechanisms.append(mechanism)
	
	# 发射触发机关信号
	projectile_trigger_mechanism.emit(mechanism, position)
	
	# 调用机关的触发方法
	if mechanism.has_method("on_bullet_hit"):
		mechanism.on_bullet_hit(self)
		print("触发机关: %s" % mechanism.name)
	elif mechanism.has_method("trigger"):
		mechanism.trigger(self)
		print("触发机关: %s" % mechanism.name)
	else:
		print("警告: 机关 %s 没有可用的触发方法" % mechanism.name)

func apply_damage(target: Node, target_type: String):
	"""应用伤害"""
	if target.has_method("take_damage"):
		# 计算伤害
		var damage = projectile_damage
		
		# 应用伤害倍数
		if target_type in damage_multiplier:
			damage *= damage_multiplier[target_type]
		
		# 应用伤害
		target.take_damage(damage, projectile_type)
		
		print("对 %s 造成伤害: %f" % [target_type, damage])
	else:
		print("目标 %s 没有 take_damage 方法" % target.name)

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

func start_trigger_cooldown():
	"""开始触发冷却"""
	if mechanism_trigger_cooldown > 0:
		is_trigger_cooldown = true
		trigger_cooldown_timer = 0.0
		print("开始触发冷却: %.2f秒" % mechanism_trigger_cooldown)

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
	
	# 在销毁时触发已接触但未触发的机关
	if trigger_mechanism_on_destroy and can_trigger_mechanisms:
		for target in hit_targets:
			var target_type = get_target_type(target)
			if target_type == "mechanism" and target not in triggered_mechanisms:
				trigger_mechanism(target, target.global_position)
	
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
