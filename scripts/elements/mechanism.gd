extends Area2D
class_name Mechanism

# 导出变量
@export var mechanism_type: String = "switch"
@export var text: String = "开"
@export var text_color: Color = Color.WHITE
@export var mechanism_color: String = ""  # 红、绿、蓝等
@export var is_active: bool = true
@export var can_be_triggered: bool = true
@export var cooldown_time: float = 1.0

# 常量
const CHARACTER_SIZE: int = 24

# 节点引用
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# 状态变量
var is_triggered: bool = false
var is_in_cooldown: bool = false
var linked_objects: Array = []  # 关联的机关
var trigger_count: int = 0
var max_trigger_count: int = 0  # 0表示无限
const grid_width = 1
const grid_height = 1

signal mechanism_triggered(mechanism: Mechanism, triggerer: Node2D)
signal mechanism_reset(mechanism: Mechanism)
signal mechanism_state_changed(mechanism: Mechanism, new_state: bool)

func _ready():
	"""初始化"""
	print("机关初始化: %s[%s]" % [text, mechanism_color])
	setup_appearance()
	setup_signals()
	setup_collision()

func setup_appearance():
	"""设置外观"""
	if label:
		# 设置文字
		label.text = text
		
		# 设置字体
		var font_config = LabelSettings.new()
		font_config.font_size = CHARACTER_SIZE
		
		var chinese_font = load("res://assets/fonts/NotoSansSC-Regular.ttf")
		if chinese_font:
			font_config.font = chinese_font
		
		label.label_settings = font_config
		label.modulate = text_color
		
		# 根据颜色设置颜色
		if mechanism_color:
			apply_color_scheme(mechanism_color)
		
		print("机关文字: %s, 颜色: %s" % [text, text_color])

func apply_color_scheme(color_name: String):
	"""应用颜色方案"""
	var colors = {
		"红": Color(1.0, 0.2, 0.2),
		"绿": Color(0.2, 1.0, 0.2),
		"蓝": Color(0.2, 0.4, 1.0),
		"黄": Color(1.0, 1.0, 0.2),
		"紫": Color(0.8, 0.2, 1.0),
		"青": Color(0.2, 1.0, 1.0),
		"白": Color.WHITE,
		"黑": Color(0.1, 0.1, 0.1)
	}
	
	if colors.has(color_name):
		text_color = colors[color_name]
		if label:
			label.modulate = text_color

func setup_signals():
	"""设置信号"""
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup_collision():
	"""设置碰撞"""
	if collision_shape:
		# 根据机关类型设置碰撞层
		match mechanism_type:
			"switch", "dirt":
				# 开关和灰尘源可被攻击
				set_collision_layer_value(5, true)  # 机关层
				set_collision_mask_value(4, true)     # 子弹层
			
			"door":
				# 门可被穿过或被阻挡
				if is_active:
					# 开启状态：可穿过
					set_collision_layer(0)
				else:
					# 关闭状态：阻挡
					set_collision_layer_value(2, true)  # 障碍层
			
			"teleporter", "fire", "goal":
				# 传送门、火、终点：可穿过
				set_collision_layer(0)
			
			"bow", "arrow", "dust":
				# 弓箭系统
				set_collision_layer_value(6, true)  # 投射物层

func _on_area_entered(area: Area2D):
	"""区域进入"""
	# 子弹进入
	if area.is_in_group("bullet") and can_be_triggered and not is_in_cooldown:
		on_bullet_hit(area)
	
	# 灰尘进入
	if area.is_in_group("dust") and can_be_triggered and not is_in_cooldown:
		on_dust_hit(area)

func _on_area_exited(area: Area2D):
	"""区域离开"""
	pass

func _on_body_entered(body: Node2D):
	"""物体进入"""
	# 玩家进入
	if body.is_in_group("player"):
		on_player_entered(body)
	
	# 敌人进入
	if body.is_in_group("enemy"):
		on_enemy_entered(body)

func _on_body_exited(body: Node2D):
	"""物体离开"""
	# 玩家离开
	if body.is_in_group("player"):
		on_player_exited(body)

# 虚方法，子类重写
func on_bullet_hit(bullet: Node2D):
	"""被子弹击中"""
	if can_be_triggered and not is_in_cooldown:
		trigger(bullet.get_parent())  # bullet.get_parent() 应该是发射者

func on_dust_hit(dust: Node2D):
	"""被灰尘击中"""
	if can_be_triggered and not is_in_cooldown:
		trigger(dust)

func on_player_entered(player: Node2D):
	"""玩家进入"""
	pass

func on_player_exited(player: Node2D):
	"""玩家离开"""
	pass

func on_enemy_entered(enemy: Node2D):
	"""敌人进入"""
	pass

func trigger(triggerer: Node2D = null):
	"""触发机关"""
	if not is_active or is_in_cooldown:
		return
	
	if max_trigger_count > 0 and trigger_count >= max_trigger_count:
		return
	
	print("机关被触发: %s, 触发者: %s" % [text, triggerer])
	
	trigger_count += 1
	is_triggered = true
	
	# 播放效果
	play_trigger_effect()
	play_trigger_sound()
	
	# 发射信号
	mechanism_triggered.emit(self, triggerer)
	
	# 触发关联机关
	for obj in linked_objects:
		if obj and obj.has_method("trigger"):
			obj.trigger(self)
	
	# 冷却
	if cooldown_time > 0:
		start_cooldown()

func play_trigger_effect():
	"""播放触发效果"""
	if anim_player and anim_player.has_animation("trigger"):
		anim_player.play("trigger")
	else:
		# 默认的闪烁效果
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate", Color.YELLOW, 0.1)
		tween.tween_property(label, "modulate", text_color, 0.2)

func play_trigger_sound():
	"""播放触发音效"""
	if audio_player:
		# 加载音效
		var sound_effect = load_trigger_sound()
		if sound_effect:
			audio_player.stream = sound_effect
			audio_player.play()

func load_trigger_sound() -> AudioStream:
	"""加载触发音效"""
	var sound_path = "res://assets/sounds/mechanisms/%s_trigger.wav" % mechanism_type
	if ResourceLoader.exists(sound_path):
		return load(sound_path)
	
	# 默认音效
	return null

func start_cooldown():
	"""开始冷却"""
	is_in_cooldown = true
	
	if cooldown_time > 0:
		await get_tree().create_timer(cooldown_time).timeout
		is_in_cooldown = false
	
	print("机关冷却结束: %s" % text)

func reset():
	"""重置机关"""
	is_triggered = false
	trigger_count = 0
	
	# 重置效果
	if anim_player and anim_player.has_animation("reset"):
		anim_player.play("reset")
	
	mechanism_reset.emit(self)
	print("机关重置: %s" % text)

func link_to(mechanism: Mechanism):
	"""连接到另一个机关"""
	if mechanism and not mechanism in linked_objects:
		linked_objects.append(mechanism)
		print("机关连接: %s -> %s" % [text, mechanism.text])

func unlink_from(mechanism: Mechanism):
	"""断开机关连接"""
	if mechanism in linked_objects:
		linked_objects.erase(mechanism)
		print("机关断开: %s -> %s" % [text, mechanism.text])

func set_active(active: bool):
	"""设置激活状态"""
	if is_active != active:
		is_active = active
		mechanism_state_changed.emit(self, active)
		setup_collision()  # 重新设置碰撞
		
		if active:
			play_activate_effect()
		else:
			play_deactivate_effect()

func play_activate_effect():
	"""播放激活效果"""
	if anim_player and anim_player.has_animation("activate"):
		anim_player.play("activate")

func play_deactivate_effect():
	"""播放失活效果"""
	if anim_player and anim_player.has_animation("deactivate"):
		anim_player.play("deactivate")

func get_mechanism_data() -> Dictionary:
	"""获取机关数据（用于保存）"""
	var linked_data = []
	for obj in linked_objects:
		if obj:
			linked_data.append({"path": obj.get_path()})
	
	return {
		"type": mechanism_type,
		"text": text,
		"color": mechanism_color,
		"position": {"x": global_position.x, "y": global_position.y},
		"is_active": is_active,
		"is_triggered": is_triggered,
		"trigger_count": trigger_count,
		"linked_to": linked_data
	}
