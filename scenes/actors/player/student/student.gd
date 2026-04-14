extends "res://scenes/actors/player/base/player_base.gd"
# 学生形态

class_name Student

# 学生特有属性
var pen_color_intensity: float = 1.0
var shoes_thrown: Array[String] = []

# 学生图片状态枚举
enum StudentSpriteState {
	PEN_SELECTED = 1,           # 笔被选择（绿色），鞋未选择（白色）
	SHOES_SELECTED = 2,         # 鞋被选择（绿色），笔未选择（白色）
	PEN_SELECTED_LOW_INK = 3,   # 笔被选择但缺墨（灰绿色），鞋未选择（白色）
	SHOES_SELECTED_LOW_INK = 4, # 鞋被选择（绿色），笔未选择且缺墨（灰色）
	DOUBLE_FOOT_GREEN = 5,      # 双脚绿（鞋被扔掉），笔灰
	DOUBLE_FOOT_WHITE = 6,      # 双脚白（鞋被扔掉），笔绿
	DOUBLE_FOOT_GREEN_PEN_LOW = 7,  # 双脚绿，笔灰绿
	DOUBLE_FOOT_WHITE_PEN_LOW = 8,  # 双脚白，笔灰绿
}

var current_sprite_state = StudentSpriteState.PEN_SELECTED
var animation_timer: float = 0.0
var animation_speed: float = 0.1
var current_animation: String = "idle"
var last_facing_direction: float = 1.0  # 1=右，-1=左

func _ready():
	print("学生形态初始化: %s" % name)
	
	# 调用父类初始化
	super._ready()
	
	# 设置初始纹理
	update_student_sprite()
	
	# 初始化学生特有属性
	setup_student_limbs()
	
	print("学生形态初始化完成")

func setup_student_limbs():
	"""初始化学生肢体"""
	print("设置学生肢体")
	
	# 学生特有的肢体配置
	limbs["pen"]["color"] = Color(0.9, 0.9, 1.0, 1.0)  # 浅蓝色
	limbs["left_shoe"]["position"] = Vector2(-10, 20)
	limbs["right_shoe"]["position"] = Vector2(10, 20)
	
	# 移除book，因为学生没有书
	limbs.erase("book")
	
	# 设置初始活动肢体为笔
	active_limb = "pen"

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
	var direction_prefix = "1" if facing_direction < 0 else "0"  # 左=11，右=01
	
	match current_sprite_state:
		StudentSpriteState.PEN_SELECTED:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "5.png")  # 笔绿，鞋白
		StudentSpriteState.SHOES_SELECTED:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "1.png")  # 鞋绿，笔灰
		StudentSpriteState.PEN_SELECTED_LOW_INK:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "8.png")  # 笔灰绿，鞋白
		StudentSpriteState.SHOES_SELECTED_LOW_INK:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "2.png")  # 鞋绿，笔白
		StudentSpriteState.DOUBLE_FOOT_GREEN:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "4.png")  # 双脚绿，笔灰
		StudentSpriteState.DOUBLE_FOOT_WHITE:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "6.png")  # 双脚白，笔绿
		StudentSpriteState.DOUBLE_FOOT_GREEN_PEN_LOW:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "3.png")  # 双脚绿，笔白
		StudentSpriteState.DOUBLE_FOOT_WHITE_PEN_LOW:
			sprite.texture = load(texture_path + "student_state_" + direction_prefix + "7.png")  # 双脚白，笔灰绿
	
	print("学生纹理更新为状态: %d, 朝向: %s" % [current_sprite_state, "左" if facing_direction < 0 else "右"])

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

func update_sprite_based_on_game_logic():
	"""根据游戏逻辑更新纹理状态"""
	# 检查鞋是否被扔掉
	var left_shoe_thrown = limbs["left_shoe"]["thrown"]
	var right_shoe_thrown = limbs["right_shoe"]["thrown"]
	var both_shoes_thrown = left_shoe_thrown and right_shoe_thrown
	
	# 检查笔的墨水状态
	var pen_has_ink = ink > 20  # 墨水大于20%为有墨
	var pen_low_ink = ink <= 20 and ink > 0  # 墨水0-20%为缺墨
	var pen_no_ink = ink <= 0  # 墨水为0
	
	# 如果双鞋都被扔掉，进入脚模式
	if both_shoes_thrown:
		# 脚模式
		if active_limb == "pen":
			# 笔被选择
			if pen_low_ink or pen_no_ink:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_WHITE_PEN_LOW)  # 双脚白，笔灰绿
			else:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_WHITE)  # 双脚白，笔绿
		else:
			# 鞋被选择（在脚模式下，鞋不能再被选择，强制选择笔）
			active_limb = "pen"
			if pen_low_ink or pen_no_ink:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_GREEN_PEN_LOW)  # 双脚绿，笔白
			else:
				set_sprite_state(StudentSpriteState.DOUBLE_FOOT_GREEN)  # 双脚绿，笔灰
	else:
		# 鞋模式
		if active_limb == "pen":
			# 笔被选择
			if pen_low_ink or pen_no_ink:
				set_sprite_state(StudentSpriteState.PEN_SELECTED_LOW_INK)  # 笔灰绿，鞋白
			else:
				set_sprite_state(StudentSpriteState.PEN_SELECTED)  # 笔绿，鞋白
		else:
			# 鞋被选择
			if pen_low_ink or pen_no_ink:
				set_sprite_state(StudentSpriteState.SHOES_SELECTED_LOW_INK)  # 鞋绿，笔白
			else:
				set_sprite_state(StudentSpriteState.SHOES_SELECTED)  # 鞋绿，笔灰

func set_sprite_state(new_state: StudentSpriteState): 
	"""设置学生纹理状态"""
	if new_state != current_sprite_state:
		current_sprite_state = new_state
		update_student_sprite()

func use_pen():
	"""学生形态使用笔"""
	print("学生使用笔")
	
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
	
	# 笔颜色变淡
	pen_color_intensity = max(0.3, pen_color_intensity - 0.1)
	
	# 发射墨弹
	emit_student_ink_projectile()
	
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

func emit_student_ink_projectile():
	"""学生形态发射墨弹"""
	print("学生发射墨弹")
	
	# 创建墨弹实例
	# 这里可以添加墨弹的具体实现
	
	if EventBus.instance:
		EventBus.instance.debug_message.emit("学生发射墨弹", 1)

func use_shoes():
	"""学生形态使用双鞋"""
	print("学生使用双鞋")
	
	# 检查鞋是否可用
	var left_shoe_available = limbs["left_shoe"]["active"] and not limbs["left_shoe"]["thrown"]
	var right_shoe_available = limbs["right_shoe"]["active"] and not limbs["right_shoe"]["thrown"]
	
	# 如果两只鞋都可用，两只都扔掉
	if left_shoe_available and right_shoe_available:
		# 标记两只鞋都扔掉
		limbs["left_shoe"]["thrown"] = true
		limbs["right_shoe"]["thrown"] = true
		
		if "left_shoe" not in shoes_thrown:
			shoes_thrown.append("left_shoe")
		if "right_shoe" not in shoes_thrown:
			shoes_thrown.append("right_shoe")
		
		# 实际扔出鞋子
		throw_shoe("left_shoe")
		throw_shoe("right_shoe")
		
		# 触发移速增加效果
		apply_student_speed_boost()
		
		# 开始流血效果
		start_student_bleed_effect()
		
		# 更新UI
		update_ui()
		
		# 播放音效
		play_student_shoe_throw_sound()
		
		# 切换到笔（因为鞋被扔掉了）
		active_limb = "pen"
	elif left_shoe_available or right_shoe_available:
		# 只有一只鞋可用
		var available_shoe = "left_shoe" if left_shoe_available else "right_shoe"
		
		# 标记鞋扔掉
		limbs[available_shoe]["thrown"] = true
		if available_shoe not in shoes_thrown:
			shoes_thrown.append(available_shoe)
		
		# 实际扔出鞋子
		throw_shoe(available_shoe)
		
		# 触发移速增加效果
		apply_student_speed_boost()
		
		# 开始流血效果
		start_student_bleed_effect()
		
		# 更新UI
		update_ui()
		
		# 播放音效
		play_student_shoe_throw_sound()
	else:
		print("没有可用的鞋")
		return
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()

func throw_shoe(shoe_name: String):
	"""实际扔出鞋子"""
	print("扔出鞋子: %s" % shoe_name)
	
	# 计算扔出方向
	var throw_direction = Vector2(facing_direction, -0.3).normalized()
	
	# 创建鞋子实例
	# 这里可以添加鞋子的具体实现
	
	# 更新肢体位置
	limbs[shoe_name]["position"] = Vector2.ZERO
	
	if EventBus.instance:
		EventBus.instance.debug_message.emit("扔出鞋子: " + shoe_name, 1)

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
		if limb != "book" and "durability" in limbs[limb]:
			limbs[limb]["durability"] = 100.0
	
	# 更新纹理状态
	update_sprite_based_on_game_logic()
	
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
		if limbs[shoe]["thrown"]:
			limbs[shoe]["thrown"] = false
			if "durability" in limbs[shoe]:
				limbs[shoe]["durability"] = 100.0
	
	shoes_thrown.clear()
	
	print("学生回收鞋子")

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
