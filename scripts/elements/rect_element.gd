# res://scripts/elements/base_rect_element.gd
extends Node2D
class_name RectElement

# 导出变量
@export var element_type: String = "wall"
@export var grid_width: int = 3
@export var grid_height: int = 3
@export var text: String = "墙"
@export var text_color: Color = Color.WHITE
@export var has_collision: bool = true
@export var collision_layer: int = 2  # 默认地面层
@export var collision_mask: int = 3  # 默认玩家和子弹层
@export var is_destructible: bool = false
@export var health: int = 1

# 常量
const GRID_SIZE: int = 32
const CHARACTER_SIZE: int = 24

# 节点引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var text_container: Node2D = $TextContainer
@onready var area: Area2D = $Area2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# 内部变量
var characters: Array = []  # 存储文字节点
var original_text: String
var is_active: bool = true

func _ready():
	"""初始化"""
	print("矩形元素初始化: %s (%d×%d)" % [element_type, grid_width, grid_height])
	setup_collision()
	setup_texts()
	setup_signals()

func setup_collision():
	"""设置碰撞"""
	if collision_shape and collision_shape.shape is RectangleShape2D:
		# 计算矩形大小（基于格子数）
		var rect_size = Vector2(grid_width * GRID_SIZE, grid_height * GRID_SIZE)
		collision_shape.shape.size = rect_size
		
		# 设置碰撞层和掩码
		if collision_shape.get_parent() is StaticBody2D:
			var body = collision_shape.get_parent() as StaticBody2D
			body.collision_layer = collision_layer
			body.collision_mask = collision_mask
		
		print("碰撞大小: %s" % rect_size)

func setup_texts():
	"""设置文字显示"""
	original_text = text
	
	# 清理现有文字
	for child in text_container.get_children():
		child.queue_free()
	characters.clear()
	
	# 创建中心文字
	create_character(Vector2.ZERO, text, text_color)
	
	# 如果宽度或高度大于1，创建填充文字
	if grid_width > 1 or grid_height > 1:
		create_fill_characters()
	
	print("创建了 %d 个文字" % characters.size())

func create_character(position: Vector2, char_text: String, color: Color):
	"""创建单个文字节点"""
	var label = Label.new()
	label.name = "Char_%s" % char_text
	
	# 创建字体设置
	var font_config = LabelSettings.new()
	font_config.font_size = CHARACTER_SIZE
	
	# 尝试加载中文字体
	var chinese_font = load("res://assets/fonts/NotoSansSC-Regular.ttf")
	if chinese_font:
		font_config.font = chinese_font
	
	label.label_settings = font_config
	label.text = char_text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 添加到容器
	text_container.add_child(label)
	label.position = position
	characters.append(label)
	
	return label

func create_fill_characters():
	"""创建填充文字（用于大墙）"""
	var padding = 1.2  # 文字间距因子
	var start_x = -(grid_width - 1) * GRID_SIZE * 0.5
	var start_y = -(grid_height - 1) * GRID_SIZE * 0.5
	
	for x in range(grid_width):
		for y in range(grid_height):
			# 跳过中心位置（已创建）
			if x == grid_width / 2 and y == grid_height / 2:
				continue
			
			var pos = Vector2(
				start_x + x * GRID_SIZE * padding,
				start_y + y * GRID_SIZE * padding
			)
			
			# 随机选择是否显示文字（避免太密集）
			if randf() < 0.7:  # 70%的概率显示文字
				# 稍微随机化文字
				var char_text = get_random_char_variant()
				# 稍微随机化颜色
				var color_variation = Color(
					clamp(text_color.r + randf_range(-0.1, 0.1), 0, 1),
					clamp(text_color.g + randf_range(-0.1, 0.1), 0, 1),
					clamp(text_color.b + randf_range(-0.1, 0.1), 0, 1),
					clamp(text_color.a + randf_range(-0.2, 0.1), 0.3, 1)
				)
				
				create_character(pos, char_text, color_variation)

func get_random_char_variant() -> String:
	"""获取随机变化的文字"""
	var variants = {
		"墙": ["墙", "壁", "障", "阻", "隔"],
		"地": ["地", "土", "陆", "场", "坪"],
		"台": ["台", "阶", "台", "坛", "基"],
		"洞": ["洞", "穴", "孔", "窟", "空"]
	}
	
	if variants.has(original_text):
		var options = variants[original_text]
		return options[randi() % options.size()]
	
	return original_text

func setup_signals():
	"""设置信号连接"""
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		area.area_entered.connect(_on_area_entered)
		area.area_exited.connect(_on_area_exited)

func _on_body_entered(body: Node2D):
	"""物体进入"""
	if body.is_in_group("player"):
		on_player_entered(body)
	elif body.is_in_group("enemy"):
		on_enemy_entered(body)
	elif body.is_in_group("bullet"):
		on_bullet_hit(body)

func _on_body_exited(body: Node2D):
	"""物体离开"""
	if body.is_in_group("player"):
		on_player_exited(body)

func _on_area_entered(area: Area2D):
	"""区域进入"""
	# 可以处理其他机关
	pass

func _on_area_exited(area: Area2D):
	"""区域离开"""
	pass

# 虚方法，子类重写
func on_player_entered(player: Node2D):
	pass

func on_player_exited(player: Node2D):
	pass

func on_enemy_entered(enemy: Node2D):
	pass

func on_bullet_hit(bullet: Node2D):
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
		for char_node in characters:
			char_node.modulate = Color.RED
			var tween = get_tree().create_tween()
			tween.tween_property(char_node, "modulate", Color.WHITE, 0.2)

func destroy():
	"""销毁元素"""
	print("销毁元素: %s" % element_type)
	
	# 播放销毁动画
	if anim_player and anim_player.has_animation("destroy"):
		anim_player.play("destroy")
		await anim_player.animation_finished
	else:
		# 淡出效果
		var tween = get_tree().create_tween()
		for char_node in characters:
			tween.parallel().tween_property(char_node, "modulate:a", 0.0, 0.3)
		
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
