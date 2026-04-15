extends Mechanism
class_name Wall

# 导出变量
@export var is_destructible: bool = false
@export var health: int = 3
@export var breaks_into_dust: bool = false
@export var dust_amount: int = 3

# 内部变量
var current_health: int

func _ready():
	"""初始化墙壁"""
	mechanism_type = "wall"
	text = "墙"
	text_color = Color(0.7, 0.5, 0.3)  # 土黄色
	
	# 墙壁可以被攻击
	can_be_triggered = true
	is_active = true
	current_health = health
	
	# 调用父类初始化
	super._ready()

func setup_collision():
	"""设置墙壁的碰撞"""
	if collision_shape and collision_shape.shape is RectangleShape2D:
		# 计算矩形大小（基于格子数）
		var actual_size = Vector2(grid_width * element_size, grid_height * element_size)
		collision_shape.shape.size = actual_size
		
		# 墙壁是障碍物，阻挡玩家
		set_collision_layer_value(3, true)  # 障碍层
		set_collision_mask_value(1, true)   # 玩家层
		set_collision_mask_value(4, true)   # 子弹层
		
		print("墙壁碰撞大小: %s, 可破坏: %s" % [actual_size, is_destructible])

func on_bullet_hit(bullet: Node2D):
	"""子弹击中墙壁"""
	print("子弹击中墙壁: %s" % text)
	
	if is_destructible and not is_in_cooldown:
		take_damage(1, bullet)
		start_cooldown()

func on_dust_hit(dust: Node2D):
	"""灰尘击中墙壁"""
	print("灰尘击中墙壁: %s" % text)
	
	if is_destructible and not is_in_cooldown:
		take_damage(1, dust)
		start_cooldown()

func take_damage(damage: int, attacker: Node2D = null):
	"""受到伤害"""
	if not is_destructible:
		return
	
	current_health -= damage
	print("墙壁受到伤害: %d, 剩余生命: %d" % [damage, current_health])
	
	# 播放受击效果
	play_hit_effect()
	
	# 如果生命值归零，销毁墙壁
	if current_health <= 0:
		destroy(attacker)

func play_hit_effect():
	"""播放受击效果"""
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")
	else:
		# 简单的闪烁效果
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate", Color.RED, 0.1)
		tween.tween_property(label, "modulate", text_color, 0.2)

func destroy(attacker: Node2D = null):
	"""销毁墙壁"""
	print("墙壁被摧毁: %s" % text)
	
	# 播放销毁动画
	if anim_player and anim_player.has_animation("destroy"):
		anim_player.play("destroy")
		await anim_player.animation_finished
	else:
		# 淡出效果
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	# 如果可以，产生灰尘
	if breaks_into_dust and attacker:
		spawn_dust(attacker.global_position)
	
	# 从场景中移除
	queue_free()

func spawn_dust(position: Vector2):
	"""产生灰尘"""
	print("墙壁破碎产生灰尘")
	# 这里可以实例化灰尘粒子或灰尘机关
	# 暂时只是打印日志
	for i in range(dust_amount):
		print("产生灰尘 %d" % (i + 1))

# 墙壁的触发就是被摧毁
func trigger(triggerer: Node2D = null):
	"""触发墙壁（被攻击）"""
	if not is_active or is_in_cooldown:
		return
	
	print("墙壁被触发: %s, 触发者: %s" % [text, triggerer])
	
	# 如果可破坏，受到伤害
	if is_destructible:
		take_damage(1, triggerer)
	
	# 冷却
	if cooldown_time > 0:
		start_cooldown()

# 保存数据
func get_element_data() -> Dictionary:
	"""获取墙壁数据（用于保存）"""
	var data = super.get_mechanism_data()
	data["type"] = "wall"
	data["grid_width"] = grid_width
	data["grid_height"] = grid_height
	data["is_destructible"] = is_destructible
	data["health"] = health
	data["current_health"] = current_health
	data["breaks_into_dust"] = breaks_into_dust
	data["dust_amount"] = dust_amount
	return data
