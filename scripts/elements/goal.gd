extends "res://scripts/elements/mechanism.gd"

class_name Goal

@export var level_to_load: String = ""  # 下一关场景路径
@export var win_message: String = "过关！"

func _ready():
	mechanism_type = "goal"
	text = "终"
	text_color = Color(1.0, 0.8, 0.0)  # 金色
	
	can_be_triggered = false
	
	super._ready()
	
	# 开始闪烁动画
	start_glow_animation()

func on_player_entered(player: Node2D):
	"""玩家到达终点"""
	print("玩家到达终点")
	
	# 播放胜利效果
	play_victory_effect()
	
	# 显示过关消息
	show_win_message()
	
	# 加载下一关或返回菜单
	load_next_level()

func play_victory_effect():
	"""播放胜利效果"""
	# 播放动画
	if anim_player and anim_player.has_animation("victory"):
		anim_player.play("victory")
	
	# 播放音效
	play_victory_sound()
	
	# 粒子效果
	create_victory_particles()

func play_victory_sound():
	"""播放胜利音效"""
	if audio_player:
		var sound = load("res://assets/sounds/victory.wav")
		if sound:
			audio_player.stream = sound
			audio_player.play()

func create_victory_particles():
	"""创建胜利粒子"""
	var particles = GPUParticles2D.new()
	particles.amount = 50
	particles.lifetime = 1.0
	particles.process_material = ParticleProcessMaterial.new()
	particles.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particles.process_material.emission_sphere_radius = 20.0
	particles.process_material.gravity = Vector3(0, -98, 0)
	particles.process_material.initial_velocity = 100.0
	particles.process_material.initial_velocity_random = 0.5
	particles.process_material.color = Color(1.0, 0.8, 0.0)
	
	add_child(particles)
	particles.emitting = true
	
	# 延迟后销毁
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func show_win_message():
	"""显示过关消息"""
	var label = Label.new()
	label.text = win_message
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 48
	label.label_settings.font_color = Color.GOLD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 添加到屏幕中心
	get_tree().root.add_child(label)
	label.position = get_viewport().size * 0.5 - Vector2(100, 25)
	
	# 动画效果
	var tween = get_tree().create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_interval(1.0)
	tween.tween_callback(label.queue_free)

func start_glow_animation():
	"""开始发光动画"""
	if anim_player and anim_player.has_animation("glow"):
		anim_player.play("glow")
	else:
		var tween = get_tree().create_tween().set_loops()
		tween.tween_property(label, "modulate:a", 0.5, 0.8)
		tween.tween_property(label, "modulate:a", 1.0, 0.8)

func load_next_level():
	"""加载下一关"""
	if level_to_load and ResourceLoader.exists(level_to_load):
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file(level_to_load)
	else:
		print("没有指定下一关，或场景不存在")
