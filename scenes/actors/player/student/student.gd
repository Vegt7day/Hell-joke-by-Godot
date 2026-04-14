extends "res://scenes/actors/player/base/player_base.gd"
# 学生形态

class_name Student

# 学生特有属性
var pen_color_intensity: float = 1.0
var shoes_thrown: Array[String] = []

# 捡鞋冷却相关
var shoe_pickup_cooldown: float = 0.5  # 与鞋抛射体的 invincible_time 一致
var last_shoe_pickup_time: Dictionary = {}  # 记录每只鞋最后拾取时间
var shoe_pickup_ready: Dictionary = {}  # 记录每只鞋是否可以拾取

# 学生图片状态枚举
enum StudentSpriteState {
SHOES_SELECTED_LOW_INK = 1, # 鞋被选择（绿色），笔未选择且缺墨（灰色）
SHOES_SELECTED = 2,         # 鞋被选择（绿色），笔未选择（白色）
DOUBLE_FOOT_WHITE_PEN_LOW = 3,  # 双脚绿，笔白    
DOUBLE_FOOT_GREEN = 4,      # 双脚绿（鞋被扔掉），笔灰
PEN_SELECTED = 5,           # 笔被选择（绿色），鞋未选择（白色）    
DOUBLE_FOOT_WHITE = 6,      # 双脚白（鞋被扔掉），笔绿
DOUBLE_FOOT_GREEN_PEN_LOW = 7,  # 双脚白，笔灰绿
PEN_SELECTED_LOW_INK = 8,   # 笔被选择但缺墨（灰绿色），鞋未选择（白色）
}

# 抛射体相关属性
var projectile_manager: Node
var active_shoes: Array = []
var ink_projectiles: Array = []

# 回收相关属性
var is_recovering: bool = false
var recover_delay: float = 0.6  # 回收延迟时间
var recover_timer: float = 0.0
var recover_start_time: float = 0.0


var current_sprite_state = StudentSpriteState.PEN_SELECTED
var animation_timer: float = 0.0
var animation_speed: float = 0.1
var current_animation: String = "idle"
var last_facing_direction: float = 1.0  # 1=右，-1=左

func _ready():
	print("学生形态初始化: %s" % name)

	# 调用父类初始化
	super._ready()

	# 确保Sprite不会被翻转
	if sprite:
		sprite.scale.x = abs(sprite.scale.x)  # 确保x缩放为正
		sprite.flip_h = false  # 确保不水平翻转

	# 设置初始纹理
	update_student_sprite()

	# 初始化学生特有属性
	setup_student_limbs()

	# 初始化抛射体管理器
	setup_projectile_manager()
	setup_collision_and_signals()

	# 初始化鞋拾取冷却
	init_shoe_pickup_cooldown()
	init_shoe_pickup_cooldown()
	print("学生形态初始化完成")

func init_shoe_pickup_cooldown():
	"""初始化鞋拾取冷却"""
	print("初始化鞋拾取冷却")
	
	# 为左右鞋初始化冷却状态
	for shoe_name in ["left_shoe", "right_shoe"]:
		last_shoe_pickup_time[shoe_name] = 0.0
		shoe_pickup_ready[shoe_name] = true
	
	print("鞋拾取冷却初始化完成: %s" % shoe_pickup_ready)

func setup_collision_and_signals():
	"""设置碰撞和信号"""
	print("设置学生碰撞和信号")
	
	# 查找PickupArea节点
	var pickup_area = get_node_or_null("PickupArea")
	if pickup_area:
		print("找到学生PickupArea节点")
		# 设置碰撞层和掩码
		pickup_area.set_collision_layer_value(8, true)   # 第8层：玩家
		pickup_area.set_collision_mask_value(4, true)    # 第4层：拾取
		
		print("学生PickupArea碰撞层: %s, 碰撞掩码: %s" % [pickup_area.collision_layer, pickup_area.collision_mask])
		
		# 连接信号
		pickup_area.area_entered.connect(_on_student_area_entered)
		pickup_area.body_entered.connect(_on_student_body_entered)
		
		print("学生拾取信号已连接")
	else:
		print("警告: 学生没有PickupArea节点")

func _on_student_area_entered(area: Area2D):
	"""学生区域进入"""
	print("学生区域进入: %s (%s)" % [area.name, area.get_class()])
	
	# 检查是否是鞋抛射体
	if area and "shoe_owner" in area:
		print("检测到鞋抛射体 (通过shoe_owner属性)")
		# 尝试拾取
		_try_pickup_shoe(area)
	else:
		print("不是鞋抛射体: %s" % area.get_class())

func _input(event):
	"""处理输入"""

	# 检查是否有鞋子需要回收
	if event.is_action_pressed("recover"):
		# 检查是否有鞋子需要回收
		if active_shoes.size() > 0 and not is_recovering:
			print("按下R键，开始回收延迟")
			start_recover_delay()
		else:
			# 如果没有鞋子，使用原来的恢复逻辑
			if not is_recovering:
				recover_limbs()

func start_recover_delay():
	"""开始回收延迟"""
	print("开始回收延迟: %.2f秒" % recover_delay)
	
	# 设置回收状态
	is_recovering = true
	recover_timer = 0.0
	recover_start_time = Time.get_unix_time_from_system()
	
	# 播放回收音效
	play_student_recover_sound()
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()
	
	# 禁用输入，防止重复触发
	set_process_input(false)
	
	print("回收延迟开始，等待 %.2f 秒" % recover_delay)


func _try_pickup_shoe(shoe):
	"""尝试拾取鞋子"""
	if not shoe or not shoe.can_be_picked_up:
		print("鞋子还不能被拾取（鞋子无敌时间）")
		return
	
	# 获取鞋子的所有者信息
	var shoe_name = shoe.shoe_owner
	print("尝试拾取鞋子: %s" % shoe_name)
	
	# 检查学生是否在拾取冷却中
	if not is_shoe_pickup_ready(shoe_name):
		var remaining_time = get_shoe_pickup_cooldown_remaining(shoe_name)
		print("学生拾取冷却中，还需等待: %.2f秒" % remaining_time)
		return
	
	# 调用pickup_shoe方法
	if pickup_shoe(shoe_name, shoe):
		print("拾取成功: %s" % shoe_name)
		# 开始拾取冷却
		start_shoe_pickup_cooldown(shoe_name)
	else:
		print("拾取失败")

func is_shoe_pickup_ready(shoe_name: String) -> bool:
	"""检查鞋子是否可以拾取"""
	if shoe_name not in shoe_pickup_ready:
		return true
	
	return shoe_pickup_ready[shoe_name]

func get_shoe_pickup_cooldown_remaining(shoe_name: String) -> float:
	"""获取拾取冷却剩余时间"""
	if shoe_name not in last_shoe_pickup_time:
		return 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - last_shoe_pickup_time[shoe_name]
	var remaining = max(0, shoe_pickup_cooldown - elapsed)
	
	return remaining

func start_shoe_pickup_cooldown(shoe_name: String):
	"""开始拾取冷却"""
	print("开始拾取冷却: %s" % shoe_name)
		
	# 记录当前时间
	last_shoe_pickup_time[shoe_name] = Time.get_ticks_msec() / 1000.0
	shoe_pickup_ready[shoe_name] = false
	
	# 设置一个定时器，冷却结束后恢复
	await get_tree().create_timer(shoe_pickup_cooldown).timeout
	shoe_pickup_ready[shoe_name] = true
	
	print("拾取冷却结束: %s" % shoe_name)

func _on_student_body_entered(body: PhysicsBody2D):
	"""学生物理体进入"""
	print("学生物理体进入: %s (%s)" % [body.name, body.get_class()])
func setup_student_limbs():
	"""初始化学生肢体"""
	print("设置学生肢体")
	
	# 学生特有的肢体配置
	limbs["pen"]["color"] = Color(0.9, 0.9, 1.0, 1.0)  # 浅蓝色
	limbs["left_shoe"]["position"] = Vector2(-10, 20)
	limbs["right_shoe"]["position"] = Vector2(10, 20)
	
	# 移除book，因为学生没有书
	limbs.erase("book")
	
	# 确保所有必要的键都存在
	for shoe in ["left_shoe", "right_shoe"]:
		if not "active" in limbs[shoe]:
			limbs[shoe]["active"] = true
		if not "thrown" in limbs[shoe]:
			limbs[shoe]["thrown"] = false
		if not "position" in limbs[shoe]:
			limbs[shoe]["position"] = Vector2.ZERO
		if not "color" in limbs[shoe]:
			limbs[shoe]["color"] = Color.WHITE
	
	# 设置初始活动肢体为笔
	active_limb = "pen"

# 在学生形态代码中，修改 setup_projectile_manager 函数
func setup_projectile_manager():
	"""设置抛射体管理器"""
	print("设置抛射体管理器")
	
	# 方法1: 通过路径获取AutoLoad节点
	projectile_manager = get_node("/root/ProjectileManager")
	
	if projectile_manager:
		print("✓ 抛射体管理器已找到")
		print("  管理器类型: %s" % projectile_manager.get_class())
		
		# 检查方法是否存在
		if projectile_manager.has_method("spawn_projectile"):
			print("✓ 抛射体管理器有spawn_projectile方法")
		else:
			print("✗ 抛射体管理器没有spawn_projectile方法")
			# 打印所有方法
			print("  可用方法:")
			var methods = projectile_manager.get_method_list()
			for method in methods:
				print("    - %s" % method.name)
	else:
		print("✗ 未找到抛射体管理器")
		# 创建简易管理器
		create_simple_projectile_manager()

func create_simple_projectile_manager():
	"""创建简易的抛射体管理器（备用）"""
	print("创建简易抛射体管理器")
	
	projectile_manager = Node.new()
	projectile_manager.name = "SimpleProjectileManager"
	
	# 添加spawn_projectile方法
	projectile_manager.spawn_projectile = func(projectile_type: String, position: Vector2, direction: Vector2, owner: Node, params: Dictionary = {}):
		print("简易管理器生成抛射体: 类型=%s" % projectile_type)
		
		# 创建简单的抛射体占位
		var projectile = Area2D.new()
		projectile.name = "SimpleProjectile_" + projectile_type
		
		# 添加Sprite
		var sprite = Sprite2D.new()
		sprite.modulate = Color.RED
		projectile.add_child(sprite)
		
		# 添加碰撞形状
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 5
		projectile.add_child(shape)
		
		# 添加到场景
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.add_child(projectile)
			projectile.global_position = position
			print("✓ 简单抛射体已创建: %s" % projectile_type)
			return projectile
		
		return null
	
	# 添加到场景树
	get_tree().root.add_child(projectile_manager)
	
func switch_limb():
	"""学生形态切换肢体 - 覆盖父类方法"""
	print("学生切换肢体")
	
	# 只有两个肢体：pen 和 shoes（双鞋作为一个整体）
	# 检查当前激活的肢体
	if active_limb == "pen":
		# 切换到鞋
		active_limb = "shoes"
		print("切换到肢体: 双鞋")
	else:
		# 切换回笔
		active_limb = "pen"
		print("切换到肢体: 笔")
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()
	
	# 更新UI
	if EventBus.instance:
		EventBus.instance.player_form_changed.emit("pen" if active_limb == "shoes" else "shoes", active_limb)

func use_active_limb():
	"""使用当前活动肢体 - 覆盖父类方法"""
	print("使用肢体: %s" % active_limb)
	
	match active_limb:
		"pen":
			use_pen()
		"shoes":
			# 使用双鞋
			use_shoes()
		_:
			print("未知肢体: %s" % active_limb)

func update_student_sprite():
	"""根据当前状态和朝向更新学生纹理"""
	if not sprite:
		return
	
	var texture_path = "res://assets/graphics/characters/student/"
	
	# 根据朝向选择正确的图片
	var direction_prefix = "1" if facing_direction < 0 else "0"  # 左=1，右=0
	var state_number = str(current_sprite_state)
	
	# 确保Sprite不被翻转
	sprite.scale.x = abs(sprite.scale.x)
	sprite.flip_h = false
	
	# 生成文件名，如student_state_01.png或student_state_11.png
	var filename = "student_state_" + direction_prefix + state_number + ".png"
	var full_path = texture_path + filename
	
	# 尝试加载纹理
	if FileAccess.file_exists(full_path):
		var texture = load(full_path)
		if texture:
			sprite.texture = texture
			print("学生纹理更新为状态: %d, 朝向: %s, 文件: %s" % [current_sprite_state, "左" if facing_direction < 0 else "右", filename])
		else:
			print("错误: 无法加载纹理: %s" % full_path)
	else:
		print("警告: 纹理文件不存在: %s" % full_path)
		# 使用默认颜色
		sprite.modulate = Color(0.4, 0.6, 0.8)  # 蓝色占位

func update_animation():
	"""更新动画状态"""
	if not is_alive:
		return
	
	var new_animation = ""
	
	if not is_on_floor():
		new_animation = "jump" if velocity.y < 0 else "fall"
	elif abs(velocity.x) > 10:
		new_animation = "run"
	else:
		new_animation = "idle"
	
	if new_animation != current_animation:
		current_animation = new_animation
		print("学生动画状态: %s" % current_animation)

func _physics_process(delta: float):
	"""物理处理"""
	# 调用父类处理
	super._physics_process(delta)
	
	# 检查朝向是否变化
	if facing_direction != last_facing_direction:
		last_facing_direction = facing_direction
		# 朝向变化时更新纹理
		update_student_sprite()
	
	# 更新动画状态
	update_animation()
	
	# 根据游戏逻辑更新纹理状态
	update_sprite_based_on_game_logic()
		# 更新回收计时器
	if is_recovering:
		recover_timer += delta
		if recover_timer >= recover_delay:
			# 延迟结束，开始实际回收
			recover_timer = 0.0
			is_recovering = false
			start_shoe_recovery_animation()

func start_shoe_recovery_animation():
	"""开始鞋子回收动画"""
	print("回收延迟结束，开始回收动画")
	
	# 调用回收所有抛射体（有动画效果）
	recover_all_projectiles()
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()
	
	# 重新启用输入
	set_process_input(true)
	
	print("回收动画开始")
		
func update_sprite_based_on_game_logic():
	"""根据游戏逻辑更新纹理状态"""
	# 检查鞋是否被扔掉
	var left_shoe_thrown = "thrown" in limbs["left_shoe"] and limbs["left_shoe"]["thrown"]
	var right_shoe_thrown = "thrown" in limbs["right_shoe"] and limbs["right_shoe"]["thrown"]
	var both_shoes_thrown = left_shoe_thrown and right_shoe_thrown
	
	# 检查笔的墨水状态
	var pen_has_ink = ink > 0  # 墨水大于20%为有墨
	var pen_no_ink = ink <= 0  # 墨水为0
	# 如果双鞋都被扔掉，进入脚模式
	if both_shoes_thrown:
		# 脚模式
		if active_limb == "pen":
			# 笔被选择
			if pen_no_ink:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_WHITE_PEN_LOW)  # 双脚白，笔灰绿
			else:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_WHITE)  # 双脚白，笔绿
		else:
			# 鞋被选择（在脚模式下，鞋不能再被选择，强制选择笔）
			active_limb = "pen"
			if pen_no_ink:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_GREEN_PEN_LOW)  # 双脚绿，笔白
			else:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_GREEN)  # 双脚绿，笔灰
	else:
		# 鞋模式
		if active_limb == "pen":
			# 笔被选择
			if pen_no_ink:
				set_sprite_state(StudentSpriteState.PEN_SELECTED_LOW_INK)  # 笔灰绿，鞋白
			else:
				set_sprite_state(StudentSpriteState.PEN_SELECTED)  # 笔绿，鞋白
		else:
			# 鞋被选择
			if pen_no_ink:
				set_sprite_state(StudentSpriteState.SHOES_SELECTED_LOW_INK)  # 鞋绿，笔白
			else:
				set_sprite_state(StudentSpriteState.SHOES_SELECTED)  # 鞋绿，笔灰

func set_sprite_state(new_state: StudentSpriteState): 
	"""设置学生纹理状态"""
	if new_state != current_sprite_state:
		current_sprite_state = new_state
		update_student_sprite()

func use_pen():
	"""学生形态使用笔 - 发射墨弹"""
	print("学生使用笔 - 发射墨弹")
	
	# 检查墨水是否足够
	var ink_cost = 100
	if ink < ink_cost:
		print("墨水不足，无法使用笔")
		play_empty_ink_sound()
		return
	
	# 消耗墨水
	var old_ink = ink
	ink = max(0, ink - ink_cost)
	ink_changed.emit(old_ink, ink)
	
	# 发射墨弹
	emit_ink_projectile()
	
	# 笔颜色变淡
	pen_color_intensity = max(0.3, pen_color_intensity - 0.1)
	
	# 减少耐久
	if "durability" in limbs["pen"]:
		limbs["pen"]["durability"] = max(0, limbs["pen"]["durability"] - 3)
		
		# 检查笔耐久
		if limbs["pen"]["durability"] <= 0:
			limbs["pen"]["active"] = false
			print("笔已损坏")
	
	print("学生发射墨弹，剩余墨水: %f" % ink)
	
	# 播放音效
	play_student_ink_sound()
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()

func emit_ink_projectile():
	"""发射墨弹"""
	if not projectile_manager:
		print("错误: 抛射体管理器未初始化")
		return
	
	# 计算发射位置和方向
	var spawn_position = global_position + Vector2(20 * facing_direction, -10)
	var direction = Vector2(facing_direction, 0)
	
	# 墨弹参数
	var ink_params = {
		"ink_color": Color(0.1, 0.1, 0.3, 0.8),  # 深蓝色
		"splash_size": 60.0,
		"is_sticky": true,
		"stick_duration": 3.0,
		"damage": 15.0,
		"splash_damage": 5.0,
		"splash_radius": 80.0
	}
	
	# 生成墨弹
	var ink_projectile = projectile_manager.spawn_projectile("ink", spawn_position, direction, self, ink_params)
	if ink_projectile:
		ink_projectiles.append(ink_projectile)
		
		# 连接信号
		ink_projectile.projectile_hit.connect(_on_ink_hit)
		ink_projectile.projectile_destroyed.connect(_on_ink_destroyed.bind(ink_projectile))
		
		print("墨弹发射成功")

func _on_ink_hit(target: Node, position: Vector2):
	"""墨弹击中"""
	print("墨弹击中: %s" % target.name)
	
	# 这里可以添加墨弹击中后的额外效果
	if EventBus.instance:
		EventBus.instance.debug_message.emit("墨弹击中: " + target.name, 1)

func _on_ink_destroyed(projectile):
	"""墨弹销毁"""
	if projectile in ink_projectiles:
		ink_projectiles.erase(projectile)

func use_shoes():
	"""学生形态使用双鞋 - 扔鞋"""
	print("学生使用双鞋 - 扔鞋")
	
	# 检查鞋是否可用
	var left_shoe_available = "active" in limbs["left_shoe"] and limbs["left_shoe"]["active"] and not ("thrown" in limbs["left_shoe"] and limbs["left_shoe"]["thrown"])
	var right_shoe_available = "active" in limbs["right_shoe"] and limbs["right_shoe"]["active"] and not ("thrown" in limbs["right_shoe"] and limbs["right_shoe"]["thrown"])
	
	# 如果两只鞋都可用，两只都扔掉
	if left_shoe_available and right_shoe_available:
		# 扔左鞋
		throw_shoe("left_shoe")
		
		# 稍微延迟后扔右鞋
		await get_tree().create_timer(0.2).timeout
		throw_shoe("right_shoe")
		
	elif left_shoe_available or right_shoe_available:
		# 只有一只鞋可用
		var available_shoe = "left_shoe" if left_shoe_available else "right_shoe"
		throw_shoe(available_shoe)
	else:
		print("没有可用的鞋")
		return
	
	# 触发移速增加效果
	apply_student_speed_boost()
	
	# 开始流血效果
	start_student_bleed_effect()
	
	# 更新UI
	update_ui()
	
	# 播放音效
	play_student_shoe_throw_sound()
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()

func throw_shoe(shoe_name: String):
	"""扔鞋"""
	print("扔鞋: %s" % shoe_name)
	
	if not projectile_manager:
		print("错误: 抛射体管理器未初始化")
		return
	
	# 检查鞋是否已经被扔掉
	if "thrown" in limbs[shoe_name] and limbs[shoe_name]["thrown"]:
		print("鞋已经被扔掉: %s" % shoe_name)
		return
	
	# 标记鞋已扔掉
	limbs[shoe_name]["thrown"] = true
	if shoe_name not in shoes_thrown:
		shoes_thrown.append(shoe_name)
	
	# 播放音效
	play_student_shoe_throw_sound()
	
	# 计算发射位置
	var y_offset = 61 if shoe_name == "left_shoe" else 61
	var x_offset = -40 if shoe_name == "left_shoe" else 40
	var spawn_position = global_position + Vector2(x_offset, y_offset)
	
	# 垂直向上方向
	var throw_direction = Vector2(0, -1).normalized()
	
	# 鞋参数 - 调整为垂直上下运动
	var shoe_params = {
		"shoe_name": shoe_name,
		"upward_speed": 300.0,  # 向上速度
		"bounce_height": 50.0,  # 弹起高度
		"gravity": 400.0,  # 重力
		"rotation_speed": 2.0,
		"invincible_time": 0.5,  # 0.5秒无敌时间
		"return_duration": 1.0  # 1秒返回时间
	}
	
	# 生成鞋抛射体
	var shoe_projectile = projectile_manager.spawn_projectile("shoe", spawn_position, throw_direction, self, shoe_params)
	if shoe_projectile:
		active_shoes.append(shoe_projectile)
		
		# 连接信号
		shoe_projectile.projectile_landed.connect(_on_shoe_landed.bind(shoe_projectile, shoe_name))
		#shoe_projectile.projectile_recovered.connect(_on_shoe_recovered.bind(shoe_projectile, shoe_name))
		
		print("鞋发射成功: %s" % shoe_name)
		
		# 更新纹理状态
		update_sprite_based_on_game_logic()
	else:
		print("鞋发射失败: %s" % shoe_name)
		# 重置状态
		limbs[shoe_name]["thrown"] = false
		if shoe_name in shoes_thrown:
			shoes_thrown.erase(shoe_name)
			
func _on_shoe_hit(target: Node, position: Vector2, shoe_name: String):
	"""鞋击中目标"""
	print("鞋击中目标: %s, 鞋: %s, 位置: %s" % [target.name, shoe_name, position])
	
	if EventBus.instance:
		EventBus.instance.debug_message.emit("鞋击中: " + shoe_name, 1)

func _on_shoe_landed(projectile, shoe_name: String, position: Vector2):
	"""鞋落地"""
	print("鞋落地: %s, 位置: %s" % [shoe_name, position])
	
	if EventBus.instance:
		EventBus.instance.debug_message.emit("鞋落地: " + shoe_name, 1)
	
	# 从活动鞋列表中移除
	if projectile in active_shoes:
		active_shoes.erase(projectile)

func _on_shoe_destroyed(projectile):
	"""鞋销毁"""
	if projectile in active_shoes:
		active_shoes.erase(projectile)

func pickup_shoe(shoe_name: String, projectile) -> bool:
	"""拾取鞋"""
	print("学生尝试拾取鞋: %s" % shoe_name)
	
	# 检查是否是学生的鞋
	if shoe_name in ["left_shoe", "right_shoe"]:
		# 检查鞋是否被扔掉
		if "thrown" in limbs[shoe_name] and limbs[shoe_name]["thrown"]:
			print("拾取成功: %s" % shoe_name)
			
			# 标记当前鞋子已回收
			limbs[shoe_name]["thrown"] = false
			if shoe_name in shoes_thrown:
				shoes_thrown.erase(shoe_name)
			
			# 恢复耐久
			if "durability" in limbs[shoe_name]:
				limbs[shoe_name]["durability"] = 100.0
			
			# 从活动鞋列表中移除当前鞋子
			if projectile in active_shoes:
				active_shoes.erase(projectile)
			
			# 重要：调用鞋子的回收方法！
			if projectile and projectile.has_method("recover_to_owner"):
				print("开始回收鞋子动画: %s" % shoe_name)
				projectile.recover_to_owner(self, 0.3)  # 0.3秒回收动画
			else:
				print("警告：鞋子没有recover_to_owner方法，直接销毁")
				if is_instance_valid(projectile):
					projectile.queue_free()
			
			# 1. 查找并回收另一只鞋子
			recover_other_shoe(shoe_name)
			
			# 2. 更新纹理状态
			update_sprite_based_on_game_logic()
			
			# 3. 播放拾取音效
			play_shoe_pickup_sound()
			
			# 4. 发送事件
			if EventBus.instance:
				EventBus.instance.shoe_picked_up.emit(shoe_name, global_position, self)
			
			return true
		else:
			print("鞋没有被扔掉: %s" % shoe_name)
	else:
		print("不是学生的鞋: %s" % shoe_name)
	
	return false

func recover_other_shoe(picked_up_shoe_name: String):
	"""回收另一只鞋子"""
	print("开始回收另一只鞋子，当前拾取: %s" % picked_up_shoe_name)
	
	# 确定另一只鞋子的名称
	var other_shoe_name = ""
	if picked_up_shoe_name == "left_shoe":
		other_shoe_name = "right_shoe"
	elif picked_up_shoe_name == "right_shoe":
		other_shoe_name = "left_shoe"
	else:
		print("无效的鞋子名称: %s" % picked_up_shoe_name)
		return
	
	print("需要回收的另一只鞋: %s" % other_shoe_name)
	
	# 检查另一只鞋子是否被扔掉
	if not ("thrown" in limbs[other_shoe_name] and limbs[other_shoe_name]["thrown"]):
		print("另一只鞋没有被扔掉: %s" % other_shoe_name)
		return
	
	# 在active_shoes中查找另一只鞋子
	var other_shoe_projectile = null
	for shoe in active_shoes:
		if is_instance_valid(shoe) and "shoe_owner" in shoe and shoe.shoe_owner == other_shoe_name:
			other_shoe_projectile = shoe
			break
	
	if other_shoe_projectile:
		print("找到另一只鞋子对象: %s" % other_shoe_name)
		
		# 标记另一只鞋子已回收
		limbs[other_shoe_name]["thrown"] = false
		if other_shoe_name in shoes_thrown:
			shoes_thrown.erase(other_shoe_name)
		
		# 从活动鞋列表中移除
		if other_shoe_projectile in active_shoes:
			active_shoes.erase(other_shoe_projectile)
		
		# 恢复耐久
		if "durability" in limbs[other_shoe_name]:
			limbs[other_shoe_name]["durability"] = 100.0
		
		# 调用另一只鞋子的回收方法
		if other_shoe_projectile.has_method("recover_to_owner"):
			print("开始回收另一只鞋子动画: %s" % other_shoe_name)
			# 稍微延迟一下，让两只鞋子的回收动画有先后顺序
			await get_tree().create_timer(0.2).timeout
			other_shoe_projectile.recover_to_owner(self, 0.3)
		else:
			print("警告：另一只鞋子没有recover_to_owner方法，直接销毁")
			if is_instance_valid(other_shoe_projectile):
				other_shoe_projectile.queue_free()
		
		print("成功回收另一只鞋子: %s" % other_shoe_name)
	else:
		print("未找到另一只鞋子的对象: %s" % other_shoe_name)
func play_shoe_pickup_sound():
	"""播放拾取鞋音效"""
	if AudioManager.instance:
		var sound_path = "res://assets/audio/sfx/characters/student/shoe_pickup.ogg"
		if FileAccess.file_exists(sound_path):
			AudioManager.instance.play_sfx(sound_path)
		else:
			print("警告: 拾取鞋音效文件不存在: %s" % sound_path)

func apply_student_speed_boost():
	"""学生形态应用速度提升"""
	print("学生速度提升")
	
	# 保存原始速度
	var original_move_speed = move_speed
	
	# 应用速度提升
	move_speed = original_move_speed * 1.5
	
	# 5秒后恢复
	await get_tree().create_timer(5.0).timeout
	if move_speed > original_move_speed:  # 检查是否被其他效果重置
		move_speed = original_move_speed
		print("学生速度提升效果结束")

func start_student_bleed_effect():
	"""学生形态开始流血效果"""
	print("学生开始流血")
	
	# 每2秒扣1%最大生命值
	var bleed_timer = 10.0
	while bleed_timer > 0 and is_alive:
		await get_tree().create_timer(2.0).timeout
		if is_alive:
			var bleed_damage = max_health * 0.01
			take_damage(bleed_damage, "bleed")
		bleed_timer -= 2.0

func recover_limbs():
	"""学生形态回收肢体"""
	print("学生回收肢体")
	
	# 回收墨
	recover_student_ink()
	
	# 回收鞋
	recover_student_shoes()
	
	# 停止流血
	end_bleeding_effect()
	
	# 结束速度提升
	move_speed = 200.0  # 恢复默认速度
	
	# 恢复笔颜色
	pen_color_intensity = 1.0
	
	# 恢复耐久
	for limb in limbs:
		if "durability" in limbs[limb]:
			limbs[limb]["durability"] = 100.0
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()
	
	# 回收所有抛射体
	recover_all_projectiles()
	
	# 播放回收音效
	play_student_recover_sound()

func recover_student_ink():
	"""学生形态回收墨"""
	var ink_recover = 100.0
	var old_ink = ink
	ink = min(max_ink, ink + ink_recover)
	ink_changed.emit(old_ink, ink)
	
	print("学生回收墨，当前墨水: %f" % ink)

func recover_student_shoes():
	"""学生形态回收鞋"""
	for shoe in ["left_shoe", "right_shoe"]:
		if "thrown" in limbs[shoe]:
			limbs[shoe]["thrown"] = false
	
	shoes_thrown.clear()
	
	print("学生回收鞋子")
func recover_all_projectiles():
	"""回收所有抛射体 - 有动画效果"""
	print("回收所有抛射体（动画效果）")
	
	var shoes_recovering = []
	
	# 收集所有需要回收的鞋子
	for shoe in active_shoes.duplicate():
		if is_instance_valid(shoe) and shoe.has_method("recover_to_owner"):
			shoes_recovering.append(shoe)
	
	# 按鞋子的y位置排序（上方的先回收）
	shoes_recovering.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	
	# 逐个回收鞋子
	for i in range(shoes_recovering.size()):
		var shoe = shoes_recovering[i]
		if is_instance_valid(shoe):
			# 添加顺序延迟，让鞋子依次回收
			await get_tree().create_timer(i * 0.1).timeout
			if is_instance_valid(shoe) and shoe.has_method("recover_to_owner"):
				shoe.recover_to_owner(self, 0.3)
	# 销毁所有墨弹
	for ink in ink_projectiles.duplicate():
		if is_instance_valid(ink):
			ink.queue_free()
	# 清空列表
	active_shoes.clear()
	ink_projectiles.clear()
	
	# 延迟一段时间，确保动画完成
	await get_tree().create_timer(0.5).timeout
	
	# 标记鞋已回收
	recover_student_shoes()

func recover_shoe(shoe_name: String, projectile):
	"""从外部触发鞋子回收（被另一只鞋子触发）"""
	print("外部触发鞋子回收: %s" % shoe_name)
	
	# 检查鞋子是否被扔掉
	if "thrown" in limbs[shoe_name] and limbs[shoe_name]["thrown"]:
		print("外部触发回收鞋子: %s" % shoe_name)
		
		# 标记鞋子已回收
		limbs[shoe_name]["thrown"] = false
		if shoe_name in shoes_thrown:
			shoes_thrown.erase(shoe_name)
		
		# 从活动鞋列表中移除
		if projectile in active_shoes:
			active_shoes.erase(projectile)
		
		# 恢复耐久
		if "durability" in limbs[shoe_name]:
			limbs[shoe_name]["durability"] = 100.0
		
		# 调用鞋子的回收方法
		if projectile and projectile.has_method("recover_to_owner"):
			print("外部触发开始回收鞋子动画: %s" % shoe_name)
			projectile.recover_to_owner(self, 0.4)  # 稍长时间，有先后顺序
		else:
			print("警告：外部触发回收鞋子没有recover_to_owner方法")
			if is_instance_valid(projectile):
				projectile.queue_free()
		# 更新纹理状态
		update_sprite_based_on_game_logic()
func end_bleeding_effect():
	"""结束流血效果"""
	print("结束流血效果")
	# 这里可以实现流血效果的停止逻辑

func update_ui():
	"""更新UI"""
	# 这里可以更新HUD显示
	pass

func play_student_ink_sound():
	"""播放学生墨水音效"""
	if AudioManager.instance:
		AudioManager.instance.play_sfx("res://assets/audio/sfx/characters/student/ink_shoot.ogg")

func play_empty_ink_sound():
	"""播放墨水空音效"""
	if AudioManager.instance:
		AudioManager.instance.play_sfx("res://assets/audio/sfx/characters/student/ink_empty.ogg")

func play_student_shoe_throw_sound():
	"""播放学生扔鞋音效"""
	if AudioManager.instance:
		AudioManager.instance.play_sfx("res://assets/audio/sfx/characters/student/shoe_throw_student.ogg")

func play_student_recover_sound():
	"""播放学生回收音效"""
	if AudioManager.instance:
		AudioManager.instance.play_sfx("res://assets/audio/sfx/characters/student/recover_student.ogg")
