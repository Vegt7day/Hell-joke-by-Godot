extends ProjectileBase
class_name InkProjectile

# 注意：现在继承自 ProjectileBase，不再需要重复定义父类已有的信号和属性

# 墨水特有属性
var splash_radius: float = 60.0
var ink_color: Color = Color(0.1, 0.1, 0.3, 0.8)
var has_hit: bool = false


@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var trail_particles: CPUParticles2D = $TrailParticles  # 新增：拖尾粒子

func _ready():
	# 调用父类初始化
	super._ready()
	
	# 设置墨弹特有属性
	projectile_type = "ink"  # 抛射体类型
	is_offensive = true  # 设置为有攻击性
	can_trigger_mechanisms = true  # 可以触发机关
	
	# 设置墨水特有的碰撞层和掩码
	setup_ink_collision_layers()
	
	# 设置Sprite
	setup_sprite()
	
	# 设置粒子
	setup_particles()
	
	# 设置拖尾粒子
	setup_trail_particles()
	
	print("墨水抛射体初始化完成，攻击性: %s" % is_offensive)

func setup_ink_collision_layers():
	"""设置墨弹特有的碰撞层"""
	# 清除所有层
	set_collision_layer(0)
	set_collision_mask(0)
	
	# 设置碰撞层（抛射体自身）
	set_collision_layer_value(1, true)  # 默认层
	set_collision_layer_value(4, true)  # 抛射体层
	
	# 设置碰撞掩码（检测哪些层）
	set_collision_mask_value(2, true)  # 地面/障碍物
	set_collision_mask_value(3, true)  # 敌人
	set_collision_mask_value(5, true)  # 可交互物
	set_collision_mask_value(6, true)  # 机关（新增）

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
	
	# 使用父类的 setup_projectile 方法
	var team = params.get("team", "")
	setup_projectile(start_position, move_direction, owner, team, "ink")
	
	# 保存参数
	velocity = move_direction.normalized() * projectile_speed
	
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
		projectile_damage = params["damage"]
	
	if "splash_radius" in params:
		splash_radius = params["splash_radius"]
	
	if "speed" in params:
		projectile_speed = params["speed"]
		velocity = move_direction.normalized() * projectile_speed
	
	# 设置Sprite方向
	if move_direction.x < 0:
		sprite.flip_h = true
		# 调整拖尾方向
		if trail_particles:
			trail_particles.direction = Vector2(1, 0)  # 朝左时，拖尾向右
	
	print("墨水抛射体设置完成: 速度=%s, 攻击性=%s" % [velocity, is_offensive])

func _physics_process(delta: float):
	"""物理处理 - 在父类处理的基础上添加墨水特有的行为"""
	# 调用父类的物理处理
	super._physics_process(delta)
	
	# 可以在这里添加墨水特有的行为
	# 例如：墨水的特殊移动逻辑、粒子效果更新等

func handle_collision(target: Node, hit_position: Vector2):
	"""重写碰撞处理，添加墨水特有的效果"""
	if has_hit:
		return
	
	has_hit = true
	
	# 停止拖尾粒子
	if trail_particles:
		trail_particles.emitting = false
	
	# 隐藏Sprite
	if sprite:
		sprite.visible = false
	
	# 播放墨水特有的撞击效果
	play_ink_impact_effect(hit_position)
	
	# 调用父类的碰撞处理
	super.handle_collision(target, hit_position)
	
	# 可以在这里添加墨水特有的效果
	# 例如：创建墨水区域、染色效果等

func play_ink_impact_effect(hit_position: Vector2):
	"""播放墨水特有的撞击效果"""
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
	print("播放墨水撞击音效")

func play_hit_effect(hit_position: Vector2):
	"""重写父类的击中效果，播放墨水特有的效果"""
	# 不调用父类的方法，因为我们已经有了自己的效果
	play_ink_impact_effect(hit_position)

func get_projectile_class() -> String:
	return "InkProjectile"
