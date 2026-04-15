extends Mechanism
class_name Door

enum DoorState { CLOSED, OPEN, LOCKED }

@export var door_color: String = ""
@export var initial_state: DoorState = DoorState.CLOSED
@export var is_locked: bool = false
@export var required_keys: int = 0
@export var auto_close_delay: float = 0.0  # 0表示不自动关闭
@export var open_height: float = 32.0  # 开门时向上的移动距离
@export var door_scale: Vector2 = Vector2(1, 0.5)  # 透视效果的比例缩放
@export var animation_duration: float = 0.5  # 动画持续时间

var current_state: DoorState = DoorState.CLOSED
var is_animating: bool = false
var linked_switches: Array = []
var keys_collected: int = 0
var close_timer: SceneTreeTimer = null
var original_position: Vector2  # 记录原始位置
var original_scale: Vector2    # 记录原始缩放

# 添加物理属性
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var door_visual: Node2D = $VisualNode  # 用于动画的视觉节点

func _ready():
	mechanism_type = "door"
	text = "门"
	
	# 记录初始位置和缩放
	original_position = position
	original_scale = scale if door_visual else Vector2.ONE
	
	# 先调用父类初始化
	super._ready()
	
	# 应用颜色方案
	apply_color_scheme(door_color)
	
	# 禁用物理处理，防止下坠
	set_physics_process(false)
	
	# 确保静态体存在
	if not static_body:
		static_body = get_node_or_null("StaticBody2D")
		if not static_body:
			# 如果没有，创建一个
			static_body = StaticBody2D.new()
			static_body.name = "StaticBody2D"
			add_child(static_body)
	
	# 设置静态体属性
	static_body.collision_layer = 2  # 障碍层
	static_body.collision_mask = 3   # 玩家和子弹层
	
	current_state = initial_state
	
	# 根据初始状态设置
	match current_state:
		DoorState.CLOSED:
			_apply_closed_state()
		DoorState.OPEN:
			_apply_open_state()
		DoorState.LOCKED:
			_apply_locked_state()

func _apply_closed_state():
	"""应用关闭状态（不播放动画）"""
	current_state = DoorState.CLOSED
	text = "门"
	
	# 启用碰撞
	if static_body:
		static_body.set_collision_layer_value(2, true)
		static_body.set_collision_mask_value(1, true)
		static_body.set_collision_mask_value(4, true)
	
	# 视觉：重置到原始状态
	if door_visual:
		door_visual.position = Vector2.ZERO
		door_visual.scale = Vector2.ONE
	else:
		position = original_position
		scale = Vector2.ONE
	
	# 设置文字颜色
	if label and is_instance_valid(label):
		label.modulate = text_color
	else:
		call_deferred("_deferred_set_closed_color")

func _apply_open_state():
	"""应用开启状态（不播放动画）"""
	current_state = DoorState.OPEN
	text = "开"
	
	# 禁用碰撞
	if static_body:
		static_body.set_collision_layer_value(2, false)
		static_body.set_collision_mask_value(1, false)
		static_body.set_collision_mask_value(4, false)
	
	# 视觉：透视（菱形）效果
	if door_visual:
		door_visual.position = Vector2(0, -open_height)
		door_visual.scale = door_scale
	else:
		position = original_position + Vector2(0, -open_height)
		scale = door_scale
	
	# 设置文字颜色
	if label and is_instance_valid(label):
		label.modulate = text_color * Color(1, 1, 1, 0.5)
	
	# 如果需要自动关闭
	if auto_close_delay > 0:
		start_auto_close_timer()

func _apply_locked_state():
	"""应用锁定状态（不播放动画）"""
	current_state = DoorState.LOCKED
	text = "锁"
	
	# 启用碰撞
	if static_body:
		static_body.set_collision_layer_value(2, true)
		static_body.set_collision_mask_value(1, true)
		static_body.set_collision_mask_value(4, true)
	
	# 视觉：深色
	if label and is_instance_valid(label):
		label.modulate = text_color * Color(0.5, 0.5, 0.5, 1.0)
	
	# 视觉状态保持关闭
	if door_visual:
		door_visual.position = Vector2.ZERO
		door_visual.scale = Vector2.ONE
	else:
		position = original_position
		scale = Vector2.ONE

func set_closed():
	"""设置门为关闭状态（带动画）"""
	if current_state == DoorState.CLOSED or is_animating:
		return
	
	print("门关闭: %s" % door_color)
	
	current_state = DoorState.CLOSED
	text = "门"
	
	# 启用碰撞
	if static_body:
		static_body.set_collision_layer_value(2, true)
		static_body.set_collision_mask_value(1, true)
		static_body.set_collision_mask_value(4, true)
	
	# 播放关门动画
	play_close_animation()

func set_open():
	"""设置门为开启状态（带动画）"""
	if current_state == DoorState.OPEN or is_animating:
		return
	
	print("门开启: %s" % door_color)
	
	current_state = DoorState.OPEN
	text = "开"
	
	# 播放开门动画
	play_open_animation()

func set_locked():
	"""设置门为锁定状态（带动画）"""
	if current_state == DoorState.LOCKED or is_animating:
		return
	
	print("门锁定: %s" % door_color)
	
	current_state = DoorState.LOCKED
	text = "锁"
	
	# 启用碰撞
	if static_body:
		static_body.set_collision_layer_value(2, true)
		static_body.set_collision_mask_value(1, true)
		static_body.set_collision_mask_value(4, true)
	
	# 播放锁定动画
	play_lock_animation()

func toggle(switch: Node2D = null):
	"""切换门状态"""
	if is_locked:
		print("门被锁定，无法切换")
		play_locked_effect()
		return
	
	if is_animating:
		return
	
	match current_state:
		DoorState.CLOSED:
			open(switch)
		DoorState.OPEN:
			close(switch)
		DoorState.LOCKED:
			# 如果锁定，尝试解锁
			try_unlock(switch)

func open(switch: Node2D = null):
	"""开门"""
	if current_state == DoorState.OPEN or is_locked or is_animating:
		return
	
	print("开门: %s, 触发者: %s" % [door_color, switch])
	
	# 播放开门动画
	set_open()
	
	# 播放音效
	play_open_sound()
	
	# 发射信号
	mechanism_triggered.emit(self, switch)
	
	# 停止之前的自动关闭计时器
	stop_auto_close_timer()
	
	# 开始新的自动关闭计时器
	if auto_close_delay > 0:
		start_auto_close_timer()

func close(switch: Node2D = null):
	"""关门"""
	if current_state == DoorState.CLOSED or is_animating:
		return
	
	print("关门: %s, 触发者: %s" % [door_color, switch])
	
	# 播放关门动画
	set_closed()
	
	# 播放音效
	play_close_sound()
	
	# 发射信号
	mechanism_triggered.emit(self, switch)
	
	# 停止自动关闭计时器
	stop_auto_close_timer()

func play_open_animation():
	"""播放开门动画 - 带透视效果"""
	is_animating = true
	
	# 先播放声音
	play_open_sound()
	
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
		await anim_player.animation_finished
	else:
		# 自定义动画：向上移动并变为菱形
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		
		# 禁用碰撞（在动画开始后）
		if static_body:
			static_body.set_collision_layer_value(2, false)
			static_body.set_collision_mask_value(1, false)
			static_body.set_collision_mask_value(4, false)
		
		# 动画目标节点
		var target_node = door_visual if door_visual else self
		
		# 向上移动
		tween.parallel().tween_property(target_node, "position:y", 
			target_node.position.y - open_height, 
			animation_duration)
		
		# 缩放为菱形（透视效果）
		tween.parallel().tween_property(target_node, "scale", 
			door_scale, 
			animation_duration)
		
		# 淡出效果
		if label and is_instance_valid(label):
			tween.parallel().tween_property(label, "modulate:a", 
				0.5, 
				animation_duration)
		
		await tween.finished
	
	is_animating = false
	
	# 更新文字透明度
	if label and is_instance_valid(label):
		label.modulate = text_color * Color(1, 1, 1, 0.5)

func play_close_animation():
	"""播放关门动画"""
	is_animating = true
	
	# 先播放声音
	play_close_sound()
	
	if anim_player and anim_player.has_animation("close"):
		anim_player.play("close")
		await anim_player.animation_finished
	else:
		# 自定义动画：向下移动并恢复原形
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		
		# 动画目标节点
		var target_node = door_visual if door_visual else self
		
		# 向下移动回原位
		tween.parallel().tween_property(target_node, "position:y", 
			0 if door_visual else original_position.y, 
			animation_duration)
		
		# 恢复原始缩放
		tween.parallel().tween_property(target_node, "scale", 
			Vector2.ONE, 
			animation_duration)
		
		# 淡入效果
		if label and is_instance_valid(label):
			tween.parallel().tween_property(label, "modulate:a", 
				1.0, 
				animation_duration)
		
		await tween.finished
		
		# 动画结束后启用碰撞
		if static_body:
			static_body.set_collision_layer_value(2, true)
			static_body.set_collision_mask_value(1, true)
			static_body.set_collision_mask_value(4, true)
	
	is_animating = false
	
	# 更新文字颜色
	if label and is_instance_valid(label):
		label.modulate = text_color

func play_lock_animation():
	"""播放锁定动画"""
	if is_animating:
		return
	
	is_animating = true
	
	if anim_player and anim_player.has_animation("lock"):
		anim_player.play("lock")
		await anim_player.animation_finished
	else:
		# 闪烁效果
		var tween = get_tree().create_tween()
		for i in range(3):
			tween.tween_property(label, "modulate", Color.RED, 0.1)
			tween.tween_property(label, "modulate", text_color * Color(0.5, 0.5, 0.5, 1.0), 0.1)
		
		await tween.finished
	
	is_animating = false

func _deferred_set_closed_color():
	"""延迟设置关闭颜色"""
	if label and is_instance_valid(label):
		label.modulate = text_color

func _deferred_set_open_color():
	"""延迟设置开启颜色"""
	if label and is_instance_valid(label):
		label.modulate = text_color * Color(1, 1, 1, 0.5)
func play_open_sound():
	"""播放开门音效"""
	if audio_player:
		var sound = load("res://assets/sounds/door_open.wav")
		if sound:
			audio_player.stream = sound
			audio_player.play()

func play_close_sound():
	"""播放关门音效"""
	if audio_player:
		var sound = load("res://assets/sounds/door_close.wav")
		if sound:
			audio_player.stream = sound
			audio_player.play()

func start_auto_close_timer():
	"""开始自动关门计时器"""
	stop_auto_close_timer()
	
	close_timer = get_tree().create_timer(auto_close_delay)
	close_timer.timeout.connect(_on_auto_close_timeout)

func stop_auto_close_timer():
	"""停止自动关门计时器"""
	if close_timer and not close_timer.is_stopped():
		close_timer.stop()

func _on_auto_close_timeout():
	"""自动关门"""
	if current_state == DoorState.OPEN:
		close()

func try_unlock(switch: Node2D = null):
	"""尝试解锁"""
	if keys_collected >= required_keys:
		print("门解锁: %s" % door_color)
		is_locked = false
		set_closed()
		
		# 播放解锁效果
		play_unlock_effect()
	else:
		print("需要 %d 把钥匙，当前: %d" % [required_keys, keys_collected])
		
		# 播放锁定提示
		play_locked_effect()

func add_key():
	"""添加钥匙"""
	keys_collected += 1
	print("获得钥匙: %d/%d" % [keys_collected, required_keys])
	
	# 如果收集足够钥匙，解锁
	if keys_collected >= required_keys and current_state == DoorState.LOCKED:
		try_unlock()

func play_unlock_effect():
	"""播放解锁效果"""
	# 播放动画
	if anim_player and anim_player.has_animation("unlock"):
		anim_player.play("unlock")
	
	# 播放音效
	if audio_player:
		var sound = load("res://assets/sounds/unlock.wav")
		if sound:
			audio_player.stream = sound
			audio_player.play()
	
	# 粒子效果
	var particles = GPUParticles2D.new()
	particles.amount = 30
	particles.lifetime = 1.0
	particles.process_material = ParticleProcessMaterial.new()
	particles.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particles.process_material.emission_sphere_radius = 20.0
	particles.process_material.gravity = Vector3(0, 0, 0)
	particles.process_material.initial_velocity = 50.0
	particles.process_material.initial_velocity_random = 0.3
	particles.process_material.color = Color.GOLD
	
	add_child(particles)
	particles.emitting = true
	
	# 延迟后销毁
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func play_locked_effect():
	"""播放锁定效果"""
	# 闪烁红色
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate", Color.RED, 0.1)
	tween.tween_property(label, "modulate", text_color * Color(0.5, 0.5, 0.5, 1.0), 0.1)
	tween.set_loops(3)
	
	# 播放音效
	if audio_player:
		var sound = load("res://assets/sounds/locked.wav")
		if sound:
			audio_player.stream = sound
			audio_player.play()

func link_switch(switch: Node2D):
	"""连接开关"""
	if switch and switch not in linked_switches:
		linked_switches.append(switch)
		print("门连接到开关: %s" % switch.name)

func get_door_data() -> Dictionary:
	"""获取门数据"""
	var data = get_mechanism_data()
	data["state"] = current_state
	data["is_locked"] = is_locked
	data["keys_collected"] = keys_collected
	data["required_keys"] = required_keys
	return data
