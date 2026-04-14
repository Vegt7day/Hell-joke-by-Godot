extends Area2D
class_name InkProjectile

# 定义信号
signal projectile_hit(target: Node, position: Vector2)
signal projectile_destroyed()

# 墨水属性
var velocity: Vector2 = Vector2.ZERO
var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var lifetime: float = 5.0
var lifetime_timer: float = 0.0
var splash_radius: float = 60.0
var ink_color: Color = Color(0.1, 0.1, 0.3, 0.8)
var owner_node: Node
var has_hit: bool = false

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var trail_particles: CPUParticles2D = $TrailParticles  # 新增：拖尾粒子

func _ready():
	print("墨水抛射体初始化完成")
	
	# 设置碰撞检测
	set_collision_layer(0)  # 清除所有层
	set_collision_mask(0)  # 清除所有掩码
	
	# 设置碰撞层（抛射体自身）
	set_collision_layer_value(1, true)  # 默认层
	set_collision_layer_value(4, true)  # 抛射体层（如果需要）
	
	# 设置碰撞掩码（检测哪些层）
	set_collision_mask_value(2, true)  # 地面/障碍物
	set_collision_mask_value(3, true)  # 敌人
	set_collision_mask_value(5, true)  # 可交互物
	
	# 连接信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# 设置Sprite
	setup_sprite()
	
	# 设置碰撞形状
	setup_collision_shape()
	
	# 设置粒子（用于撞击效果，初始不发射）
	setup_particles()
	
	# 设置拖尾粒子
	setup_trail_particles()

func setup_sprite():
	"""设置墨弹的Sprite显示"""
	if sprite:
		# 这里可以加载您的墨弹图片
		# 如果没有墨弹图片，可以使用临时纹理
		if not sprite.texture:
			create_temp_sprite_texture()
		sprite.modulate = ink_color
		sprite.scale = Vector2(1, 1)  # 调整大小
		print("墨水Sprite设置完成")

func create_temp_sprite_texture():
	"""创建临时纹理（如果没有墨弹图片）"""
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(ink_color)
	
	# 绘制一个圆形墨滴
	var center = Vector2(8, 8)
	var radius = 6.0
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			if distance < radius:
				# 内部：纯色
				image.set_pixel(x, y, ink_color)
			elif distance < radius + 1.0:
				# 边缘：半透明
				var edge_color = ink_color
				edge_color.a = 0.5
				image.set_pixel(x, y, edge_color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func setup_collision_shape():
	"""设置碰撞形状"""
	if collision_shape and not collision_shape.shape:
		var shape = CircleShape2D.new()
		shape.radius = 4.0
		collision_shape.shape = shape
		print("墨水碰撞形状设置完成")

func setup_particles():
	"""设置粒子系统（用于撞击效果）"""
	if particles:
		# 初始不发射
		particles.emitting = false
		particles.amount = 16
		particles.lifetime = 0.5
		particles.one_shot = true
		
		# 速度范围
		particles.initial_velocity_min = 50.0
		particles.initial_velocity_max = 150.0
		
		# 扩散范围
		particles.spread = 360.0
		particles.gravity = Vector2(0, 98.0)
		
		# 大小
		particles.scale_amount_min = 0.1
		particles.scale_amount_max = 0.3
		
		# 颜色
		particles.color = ink_color
		particles.color_ramp = create_color_ramp()
		
		# 粒子形状
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		
		print("撞击粒子设置完成")

func setup_trail_particles():
	"""设置拖尾粒子"""
	if trail_particles:
		# 持续发射拖尾
		trail_particles.emitting = true
		trail_particles.amount = 8
		trail_particles.lifetime = 0.3
		
		# 速度和方向
		trail_particles.initial_velocity_min = 1.0
		trail_particles.initial_velocity_max = 10.0
		trail_particles.direction = Vector2(-1, 0)  # 向后发射
		
		# 大小
		trail_particles.scale_amount_min = 0.05
		trail_particles.scale_amount_max = 0.1
		
		# 颜色
		trail_particles.color = ink_color
		
		# 粒子形状
		trail_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		
		print("拖尾粒子设置完成")

func create_color_ramp() -> Gradient:
	"""创建颜色渐变"""
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		ink_color,
		Color(ink_color.r, ink_color.g, ink_color.b, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	return gradient

func setup_ink(start_position: Vector2, move_direction: Vector2, owner: Node, params: Dictionary = {}):
	"""设置墨水抛射体"""
	print("设置墨水抛射体: 位置=%s, 方向=%s" % [start_position, move_direction])
	
	# 保存参数
	global_position = start_position
	direction = move_direction.normalized()
	velocity = direction * speed
	owner_node = owner
	
	# 应用自定义参数
	if "ink_color" in params:
		ink_color = params["ink_color"]
		if sprite:
			sprite.modulate = ink_color
		if particles:
			particles.color = ink_color
		if trail_particles:
			trail_particles.color = ink_color
	
	if "damage" in params:
		damage = params["damage"]
	
	if "splash_radius" in params:
		splash_radius = params["splash_radius"]
	
	if "speed" in params:
		speed = params["speed"]
		velocity = direction * speed
	
	# 设置Sprite方向
	if direction.x < 0:
		sprite.flip_h = true
		# 调整拖尾方向
		if trail_particles:
			trail_particles.direction = Vector2(1, 0)  # 朝左时，拖尾向右
	
	print("墨水抛射体设置完成: 速度=%s" % velocity)

func _physics_process(delta: float):
	"""物理处理 - 移动Sprite"""
	if has_hit:
		return
	
	# 更新位置
	global_position += velocity * delta
	
	# 更新生命周期
	lifetime_timer += delta
	if lifetime_timer >= lifetime:
		destroy()
		return
	
	# 检查是否超出屏幕边界
	if is_out_of_bounds():
		destroy()

func is_out_of_bounds() -> bool:
	"""检查是否超出屏幕边界"""
	var viewport_rect = get_viewport().get_visible_rect()
	var margin = 100
	
	return (
		global_position.x < viewport_rect.position.x - margin or
		global_position.x > viewport_rect.end.x + margin or
		global_position.y < viewport_rect.position.y - margin or
		global_position.y > viewport_rect.end.y + margin
	)

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	print("墨水抛射体与区域碰撞: %s" % area.name)
	handle_collision(area, area.global_position)

func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	print("墨水抛射体与物理体碰撞: %s" % body.name)
	handle_collision(body, body.global_position)

func handle_collision(target: Node, hit_position: Vector2):
	"""处理碰撞"""
	if has_hit:
		return
	
	# 避免自碰撞
	if target == self or target == owner_node:
		print("避免自碰撞")
		return
	
	print("墨水抛射体击中目标: %s, 位置: %s" % [target.name, hit_position])
	
	has_hit = true
	
	# 停止拖尾粒子
	if trail_particles:
		trail_particles.emitting = false
	
	# 隐藏Sprite
	if sprite:
		sprite.visible = false
	
	# 播放撞击粒子效果
	play_impact_effect(hit_position)
	
	# 发射碰撞信号
	projectile_hit.emit(target, hit_position)
	
	# 应用伤害
	if target.has_method("take_damage"):
		print("应用伤害: %.1f" % damage)
		target.take_damage(damage, "ink")
	
	# 延迟后销毁抛射体
	await get_tree().create_timer(0.5).timeout
	destroy()

func play_impact_effect(hit_position: Vector2):
	"""播放撞击效果"""
	print("播放墨水撞击效果")
	
	# 移动粒子到撞击位置
	if particles:
		particles.global_position = hit_position
		particles.restart()
		particles.emitting = true
	
	# 播放撞击音效
	play_impact_sound()

func play_impact_sound():
	"""播放撞击音效"""
	# 您可以在这里添加撞击音效
	print("播放撞击音效")

func destroy():
	"""销毁抛射体"""
	print("销毁墨水抛射体")
	
	# 发射销毁信号
	projectile_destroyed.emit()
	queue_free()

func get_projectile_class() -> String:
	return "InkProjectile"
