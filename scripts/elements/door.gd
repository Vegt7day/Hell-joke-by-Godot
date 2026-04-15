# Door.gd
extends Mechanism
class_name Door

# 添加颜色属性
@export var color: String = ""  # 颜色名称
# 定义颜色到标签的映射字典
var color_to_label = {
	"红": {
		"text": "门",  # 门的文本
		"color": Color.RED
	},
	"绿": {
		"text": "门",
		"color": Color.GREEN
	},
	"蓝": {
		"text": "门",
		"color": Color.BLUE
	},
	"黄": {
		"text": "门",
		"color": Color.YELLOW
	},
	"紫": {
		"text": "门",
		"color": Color.PURPLE
	},
	"青": {
		"text": "门",
		"color": Color.CYAN
	},
	"白": {
		"text": "门",
		"color": Color.WHITE
	},
	"黑": {
		"text": "门",
		"color": Color.BLACK
	}
}


enum DoorState { CLOSED, OPEN }

@export var open_height: float = 32.0
@export var door_scale: Vector2 = Vector2(1, 0.5)
@export var animation_duration: float = 0.5

var current_state: DoorState = DoorState.CLOSED
var is_animating: bool = false
var original_position: Vector2
var original_scale: Vector2
var linked_switches: Array = []
var all_switches_off: bool = true  # 默认认为所有开关都是关的，直到检查

@onready var static_body: StaticBody2D = $StaticBody2D
@onready var door_visual: Node2D = $VisualNode

func _ready():
	mechanism_type = "door"
	text = "门"
	
	# 在父类初始化前获取节点引用
	if not door_visual:
		door_visual = get_node_or_null("VisualNode")
		if not door_visual:
			# 如果找不到 VisualNode，尝试获取 Sprite2D
			door_visual = get_node_or_null("Sprite2D")
	
	if not label or not is_instance_valid(label):
		label = get_node_or_null("label")
		if label:
			print("门获取到Label节点: %s" % label.name)
		else:
			print("门未找到Label节点")
	
	# 在调用父类之前设置颜色
	if color != "":
		mechanism_color = color
	else:
		color = mechanism_color
	
	# 记录初始位置
	original_position = position
	if door_visual:
		original_scale = door_visual.scale
	else:
		original_scale = scale
	
	print("门初始化: 名称=%s, 颜色='%s', mechanism_color='%s'" % [name, color, mechanism_color])
	
	# 先调用父类
	super._ready()
	
	# 确保颜色设置正确
	if color != "":
		update_door_color()
	
	set_physics_process(false)
	
	if not static_body:
		static_body = get_node_or_null("StaticBody2D")
		if not static_body:
			static_body = StaticBody2D.new()
			static_body.name = "StaticBody2D"
			add_child(static_body)
	
	static_body.collision_layer = 1
	
	static_body.collision_mask =2 | 3 
	
	current_state = DoorState.CLOSED
	_apply_closed_state()
	
	# 初始化时检查开关状态
	if linked_switches.size() > 0:
		call_deferred("check_switches_state")
	
	print("门初始化完成: 颜色=%s, mechanism_color=%s" % [color, mechanism_color])

# 添加颜色设置方法
func set_color(color_name: String):
	"""设置门颜色"""
	color = color_name
	mechanism_color = color_name
	update_door_color()

func get_color_from_name(color_name: String) -> Color:
	"""根据颜色名称获取颜色值"""
	var color_map = {
		"红": Color.RED,
		"绿": Color.GREEN,
		"蓝": Color.BLUE,
		"黄": Color.YELLOW,
		"紫": Color.PURPLE,
		"青": Color.CYAN,
		"白": Color.WHITE,
		"黑": Color.BLACK
	}
	
	return color_map.get(color_name, Color.WHITE)

func update_door_color():
	"""更新门的外观颜色 - 专注设置标签颜色"""
	print("=== 更新门标签颜色开始 ===")
	print("门当前颜色: '%s'" % color)
	
	# 确保获取到标签节点
	if not label or not is_instance_valid(label):
		label = get_node_or_null("label")
		print("重新获取标签节点: %s" % label)
	
	if label:
		# 检查颜色映射
		if color in color_to_label:
			var color_info = color_to_label[color]
			print("找到颜色映射: %s -> 文本: %s, 颜色: %s" % [color, color_info.text, str(color_info.color)])
			
			# 设置标签文本
			label.text = color_info.text
			print("设置标签文本: %s" % color_info.text)
			
			# 设置标签颜色
			label.modulate = color_info.color
			print("设置标签颜色: %s" % str(color_info.color))
			
			# 确保视觉节点颜色
			if door_visual:
				door_visual.modulate = color_info.color
				print("设置视觉节点颜色")
		else:
			print("警告: 颜色 '%s' 不在映射表中, 可用颜色: %s" % [color, str(color_to_label.keys())])
			
			# 默认颜色
			label.text = "?"
			label.modulate = Color.WHITE
			if door_visual:
				door_visual.modulate = Color.WHITE
	else:
		print("错误: 没有找到标签节点!")
	
	print("=== 更新门标签颜色结束 ===")

func _process(delta):
	"""每帧更新，检查连接的开关状态"""
	# 移除每帧检查，改为通过信号触发
	pass

func _on_switch_state_changed(state: bool):
	"""开关状态变化时的回调"""
	print("门 %s 接收到开关状态变化信号: %s" % [name, ("开" if state else "关")])
	check_switches_state()

func check_switches_state():
	"""检查所有连接开关的状态 - 只有所有开关都是'关'时，门才会打开"""
	print("=== 门 %s 开始检查开关状态 ===" % name)
	print("门当前颜色: %s, 连接开关数: %d" % [mechanism_color, linked_switches.size()])
	
	# 如果没有连接开关，保持当前状态
	if linked_switches.size() == 0:
		print("没有连接开关，门保持当前状态")
		all_switches_off = true
		# 如果没有开关连接，默认打开门
		if current_state == DoorState.CLOSED and not is_animating:
			open()
		return
	
	var all_off = true
	var switch_count = 0
	
	# 检查所有开关是否都是"关"状态
	for i in range(linked_switches.size()):
		var switch = linked_switches[i]
		if switch and is_instance_valid(switch) and switch.has_method("get_switch_state"):
			var switch_state = switch.get_switch_state()
			switch_count += 1
			print("  [%d] 开关 %s 状态: %s" % [i, switch.name, "开" if switch_state else "关"])
			
			# 如果有一个开关是"开"状态，则不满足开门条件
			if switch_state:  # 如果开关是"开"状态
				all_off = false
				print("  [%d] 发现开关 %s 是'开'状态，不满足开门条件" % [i, switch.name])
				break
		else:
			# 如果开关无效或已删除，从列表中移除
			if not switch or not is_instance_valid(switch):
				print("  [%d] 开关无效或已删除，从列表中移除" % i)
				linked_switches.remove_at(i)
				i -= 1
				continue
			else:
				print("  [%d] 开关没有 get_switch_state 方法" % i)
				all_off = false
				break
	
	print("检查了 %d 个开关，所有开关都关闭: %s" % [switch_count, all_off])
	
	# 如果状态发生变化
	if all_off != all_switches_off:
		print("开关状态变化: 所有开关都关闭? %s -> %s" % [all_switches_off, all_off])
		all_switches_off = all_off
		
		# 只有当所有开关都是"关"时，门才打开
		if all_switches_off:  # 所有开关都关闭
			# 门应该打开
			if current_state == DoorState.CLOSED and not is_animating:
				print("所有开关关闭，开门")
				open()
		else:  # 有一个或多个开关是"开"状态
			# 门应该关闭
			if current_state == DoorState.OPEN and not is_animating:
				print("有开关打开，关门")
				close()
	else:
		print("开关状态未变化")
	
	print("=== 门 %s 结束检查开关状态 ===" % name)

func _apply_closed_state():
	"""应用关闭状态（不播放动画）"""
	current_state = DoorState.CLOSED
	text = "门"
	
	# 启用碰撞
	if static_body:
		static_body.set_collision_layer_value(1, true)
		static_body.set_collision_mask_value(2, true)  # 玩家
		static_body.set_collision_mask_value(3, true)  # 子弹
	
	print("门关闭: %s, 启用碰撞" % mechanism_color)
	
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
		static_body.set_collision_layer_value(1, false)
		static_body.set_collision_mask_value(2, false)  # 玩家
		static_body.set_collision_mask_value(3, false)  # 子弹
	
	print("门打开: %s, 禁用碰撞" % mechanism_color)
	
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

# 修改后的 toggle 函数
func toggle(_attacker = null):  # 添加一个可选参数
	print("门 %s 接收到切换命令" % name)
	
	# 修正：toggle 应该切换门的当前状态
	if current_state == DoorState.CLOSED:
		open()
	else:
		
		close()

func open():
	print("门 %s 正在打开..." % name)
	if not is_animating and current_state != DoorState.OPEN:
		play_open_animation()

func close():
	print("门 %s 正在关闭..." % name)
	if not is_animating and current_state != DoorState.CLOSED:
		play_close_animation()

func play_open_animation():
	"""播放开门动画 - 带透视效果"""
	is_animating = true
	
	# 播放音效
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
			static_body.set_collision_layer_value(1, false)
			static_body.set_collision_mask_value(2, false)
			static_body.set_collision_mask_value(3, false)
		
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
	
	# 应用打开状态
	_apply_open_state()

func play_close_animation():
	"""播放关门动画"""
	is_animating = true
	
	# 播放音效
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
			static_body.set_collision_layer_value(1, true)
			static_body.set_collision_mask_value(2, true)
			static_body.set_collision_mask_value(3, true)
	
	is_animating = false
	
	# 应用关闭状态
	_apply_closed_state()

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

func link_switch(switch: Node2D):
	"""连接开关"""
	if switch and switch not in linked_switches:
		linked_switches.append(switch)
		print("门 %s 连接到开关: %s" % [name, switch.name])
		
		# 连接开关状态变化信号
		if switch.has_signal("switch_state_changed"):
			print("门 %s 正在连接开关信号..." % name)
			switch.switch_state_changed.connect(_on_switch_state_changed.bind(), CONNECT_DEFERRED)
			print("已连接开关信号")
		
		# 立即检查一次状态
		check_switches_state()

func unlink_switch(switch: Node2D):
	"""断开开关连接"""
	if switch in linked_switches:
		linked_switches.erase(switch)
		print("门 %s 断开连接开关: %s" % [name, switch.name])
		
		# 检查开关状态
		check_switches_state()

func get_switch_state() -> bool:
	"""获取门状态（用于调试）"""
	return current_state == DoorState.OPEN

func get_door_data() -> Dictionary:
	"""获取门数据"""
	var data = get_mechanism_data()
	data["state"] = current_state
	data["color"] = mechanism_color
	data["linked_switches_count"] = linked_switches.size()
	data["all_switches_off"] = all_switches_off
	return data
