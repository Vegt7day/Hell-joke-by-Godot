extends Mechanism
class_name Door

enum DoorState { CLOSED, OPEN, LOCKED }

@export var door_color: String = ""
@export var initial_state: DoorState = DoorState.CLOSED
@export var is_locked: bool = false
@export var required_keys: int = 0
@export var auto_close_delay: float = 0.0  # 0表示不自动关闭
@export var slide_distance: float = 32.0  # 滑动距离

var current_state: DoorState = DoorState.CLOSED
var is_sliding: bool = false
var linked_switches: Array = []
var keys_collected: int = 0
var close_timer: SceneTreeTimer = null

func _ready():
	mechanism_type = "door"
	text = "门"
	apply_color_scheme(door_color)
	
	current_state = initial_state
	
	# 根据状态设置
	match current_state:
		DoorState.CLOSED:
			set_closed()
		DoorState.OPEN:
			set_open()
		DoorState.LOCKED:
			set_locked()
	
	super._ready()

func set_closed():
	"""设置门为关闭状态"""
	print("门关闭: %s" % door_color)
	
	current_state = DoorState.CLOSED
	text = "门"
	
	# 启用碰撞
	set_collision_layer_value(2, true)  # 障碍层
	set_collision_mask_value(1, true)    # 玩家层
	set_collision_mask_value(4, true)    # 子弹层
	
	# 视觉：实心颜色
	label.modulate = text_color
	
	# 播放关闭动画
	play_close_animation()

func set_open():
	"""设置门为开启状态"""
	print("门开启: %s" % door_color)
	
	current_state = DoorState.OPEN
	text = "开"
	
	# 禁用碰撞
	set_collision_layer(0)
	set_collision_mask(0)
	
	# 视觉：半透明
	label.modulate = text_color * Color(1, 1, 1, 0.5)
	
	# 播放开启动画
	play_open_animation()
	
	# 如果需要自动关闭
	if auto_close_delay > 0:
		start_auto_close_timer()

func set_locked():
	"""设置门为锁定状态"""
	print("门锁定: %s" % door_color)
	
	current_state = DoorState.LOCKED
	text = "锁"
	
	# 启用碰撞
	set_collision_layer_value(2, true)  # 障碍层
	set_collision_mask_value(1, true)    # 玩家层
	set_collision_mask_value(4, true)    # 子弹层
	
	# 视觉：深色
	label.modulate = text_color * Color(0.5, 0.5, 0.5, 1.0)
	
	# 播放锁定动画
	play_lock_animation()

func toggle(switch: Node2D = null):
	"""切换门状态"""
	if is_locked:
		print("门被锁定，无法切换")
		return
	
	if is_sliding:
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
	if current_state == DoorState.OPEN or is_locked:
		return
	
	print("开门: %s, 触发者: %s" % [door_color, switch])
	
	set_open()
	
	# 播放音效
	play_open_sound()
	
	# 发射信号
	mechanism_triggered.emit(self, switch)
	
	# 停止自动关闭计时器
	stop_auto_close_timer()
	
	# 开始自动关闭计时器
	if auto_close_delay > 0:
		start_auto_close_timer()

func close(switch: Node2D = null):
	"""关门"""
	if current_state == DoorState.CLOSED:
		return
	
	print("关门: %s, 触发者: %s" % [door_color, switch])
	
	set_closed()
	
	# 播放音效
	play_close_sound()
	
	# 发射信号
	mechanism_triggered.emit(self, switch)

func play_open_animation():
	"""播放开门动画"""
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
	else:
		# 滑动动画
		is_sliding = true
		var target_pos = position + Vector2(0, -slide_distance)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", target_pos, 0.3)
		tween.tween_callback(func(): is_sliding = false)

func play_close_animation():
	"""播放关门动画"""
	if anim_player and anim_player.has_animation("close"):
		anim_player.play("close")
	else:
		# 滑动动画
		is_sliding = true
		var target_pos = position + Vector2(0, slide_distance)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", target_pos, 0.3)
		tween.tween_callback(func(): is_sliding = false)

func play_lock_animation():
	"""播放锁定动画"""
	if anim_player and anim_player.has_animation("lock"):
		anim_player.play("lock")
	else:
		# 闪烁效果
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate", Color.RED, 0.2)
		tween.tween_property(label, "modulate", text_color * Color(0.5, 0.5, 0.5, 1.0), 0.2)

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
