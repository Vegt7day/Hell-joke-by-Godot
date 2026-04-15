# res://scripts/elements/base_rect_element.gd
extends Area2D
class_name RectElement

# 导出变量
@export var element_type: String = "wall"
@export var text: String = "墙"
@export var text_color: Color = Color.WHITE
@export var element_color: String = "白"  # 红、绿、蓝等
@export var has_collision: bool = true
@export var collision_layer: int = 2
@export var collision_mask: int = 3
@export var is_destructible: bool = false
@export var health: int = 1
@export var can_be_triggered: bool = false
@export var cooldown_time: float = 1.0
@export var grid_width: int = 1
@export var grid_height: int = 1

# 常量
const GRID_SIZE: int = 32
const CHARACTER_SIZE: int = 24

# 节点引用
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var visual_node: Node2D = $VisualNode
@onready var static_body: StaticBody2D = $StaticBody2D

# 内部变量
var characters: Array = []
var original_text: String
var is_active: bool = true
var is_triggered: bool = false
var is_in_cooldown: bool = false
var linked_objects: Array = []
var trigger_count: int = 0
var max_trigger_count: int = 0

func _ready():
	"""初始化"""
	print("矩形元素初始化: %s (%d×%d) 位置: %s" % [element_type, grid_width, grid_height, global_position])
	
	setup_visual_size()
	setup_appearance()
	setup_signals()
	setup_collision()

func setup_visual_size():
	"""设置视觉效果的大小"""
	# 如果没有视觉节点，尝试查找
	if not visual_node:
		visual_node = get_node_or_null("ColorRect")
		if not visual_node:
			visual_node = get_node_or_null("Sprite2D")
	
	# 设置视觉节点大小
	if visual_node:
		# 根据网格尺寸计算实际大小
		var actual_size = Vector2(grid_width * GRID_SIZE, grid_height * GRID_SIZE)
		
		if visual_node is ColorRect:
			visual_node.size = actual_size
			# 调整位置使其居中
			visual_node.position = Vector2(-actual_size.x/2, -actual_size.y/2)
			print("设置 ColorRect 尺寸: %s" % actual_size)
		
		elif visual_node is Sprite2D:
			# 计算缩放
			if visual_node.texture:
				var tex_size = visual_node.texture.get_size()
				visual_node.scale = Vector2(
					actual_size.x / tex_size.x,
					actual_size.y / tex_size.y
				)
				print("设置 Sprite2D 缩放: %s, 原纹理大小: %s" % [visual_node.scale, tex_size])
	
	# 设置标签位置居中
	if label:
		label.position = Vector2.ZERO
		# 如果标签容器是单独的，也调整其位置
		if label.get_parent() and label.get_parent() != self:
			label.get_parent().position = Vector2.ZERO

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
		if element_color:
			apply_color_scheme(element_color)
		
		print("元素文字: %s, 颜色: %s, 尺寸: %dx%d" % [text, text_color, grid_width, grid_height])

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
	"""设置信号连接"""
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func setup_collision():
	"""设置碰撞"""
	if collision_shape and collision_shape.shape is RectangleShape2D:
		# 计算矩形大小（基于格子数）
		var rect_size = Vector2(grid_width * GRID_SIZE, grid_height * GRID_SIZE)
		collision_shape.shape.size = rect_size
		
		# 设置碰撞形状的位置，使其居中
		collision_shape.position = Vector2.ZERO
		
		# 设置碰撞层和掩码
		if static_body:
			static_body.collision_layer = collision_layer
			static_body.collision_mask = collision_mask
			static_body.position = Vector2.ZERO
		
		print("碰撞大小: %s, 位置: %s" % [rect_size, collision_shape.global_position])

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
		take_damage(1)

func on_dust_hit(dust: Node2D):
	"""被灰尘击中"""
	if can_be_triggered and not is_in_cooldown:
		take_damage(1)

func on_player_entered(player: Node2D):
	"""玩家进入"""
	pass

func on_player_exited(player: Node2D):
	"""玩家离开"""
	pass

func on_enemy_entered(enemy: Node2D):
	"""敌人进入"""
	pass

func take_damage(damage: int, damage_type: String = ""):
	"""受到伤害"""
	if is_destructible:
		health -= damage
		play_hit_effect()
		
		if health <= 0:
			destroy()

func play_hit_effect():
	"""播放受击效果"""
	if anim_player and anim_player.has_animation("hit"):
		anim_player.play("hit")
	else:
		# 简单的闪烁效果
		if label:
			var tween = get_tree().create_tween()
			tween.tween_property(label, "modulate", Color.RED, 0.1)
			tween.tween_property(label, "modulate", text_color, 0.2)

func destroy():
	"""销毁元素"""
	print("销毁元素: %s" % element_type)
	
	# 播放销毁动画
	if anim_player and anim_player.has_animation("destroy"):
		anim_player.play("destroy")
		await anim_player.animation_finished
	else:
		# 淡出效果
		if label:
			var tween = get_tree().create_tween()
			tween.tween_property(label, "modulate:a", 0.0, 0.3)
			await tween.finished
	
	queue_free()

func get_grid_rect() -> Rect2:
	"""获取元素占据的网格矩形"""
	var center = global_position
	var half_size = Vector2(grid_width, grid_height) * GRID_SIZE * 0.5
	return Rect2(center - half_size, half_size * 2)

func is_point_in_element(point: Vector2) -> bool:
	"""检查点是否在元素内"""
	var rect = get_grid_rect()
	return rect.has_point(point)

# 从Mechanism继承的触发机制
func trigger(triggerer: Node2D = null):
	"""触发元素"""
	if not is_active or is_in_cooldown:
		return
	
	if max_trigger_count > 0 and trigger_count >= max_trigger_count:
		return
	
	print("元素被触发: %s, 触发者: %s" % [text, triggerer])
	
	trigger_count += 1
	is_triggered = true
	
	# 播放效果
	play_trigger_effect()
	play_trigger_sound()
	
	# 触发关联对象
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
		if label:
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
	var sound_path = "res://assets/sounds/elements/%s_trigger.wav" % element_type
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
	
	print("元素冷却结束: %s" % text)

func reset():
	"""重置元素"""
	is_triggered = false
	trigger_count = 0
	
	# 重置效果
	if anim_player and anim_player.has_animation("reset"):
		anim_player.play("reset")
	
	print("元素重置: %s" % text)

func link_to(obj: Node):
	"""连接到另一个对象"""
	if obj and not obj in linked_objects:
		linked_objects.append(obj)
		print("元素连接: %s -> %s" % [text, obj.name if obj.has_method("get_text") else obj.name])

func unlink_from(obj: Node):
	"""断开对象连接"""
	if obj in linked_objects:
		linked_objects.erase(obj)
		print("元素断开: %s -> %s" % [text, obj.name if obj.has_method("get_text") else obj.name])

func set_active(active: bool):
	"""设置激活状态"""
	if is_active != active:
		is_active = active
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

func get_element_data() -> Dictionary:
	"""获取元素数据（用于保存）"""
	var linked_data = []
	for obj in linked_objects:
		if obj:
			linked_data.append({"path": obj.get_path()})
	
	return {
		"type": element_type,
		"text": text,
		"color": element_color,
		"position": {"x": global_position.x, "y": global_position.y},
		"grid_width": grid_width,
		"grid_height": grid_height,
		"is_active": is_active,
		"health": health
	}
