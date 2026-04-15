# Switch.gd
extends Mechanism
class_name Switch

# 添加颜色属性
@export var color: String = ""  # 颜色名称
@export var is_toggle: bool = true  # 是否切换

var linked_doors: Array = []
var switch_state: bool = true  # false=关, true=开
var label_node: Label
var is_processing_hit: bool = false
signal switch_state_changed(state: bool)

func _ready():
	mechanism_type = "switch"
	mechanism_color = color  # 同步机制颜色
	switch_state = true
	text = "开"
	
	# 获取label节点
	label_node = get_node("label") as Label
	if label_node:
		print("开关初始化: 颜色=%s, 状态=%s" % [color, text])
		# 根据颜色设置标签颜色
		update_label_color()
	else:
		print("错误：无法找到label节点")
	
	super._ready()

# 添加颜色设置方法
func set_color(color_name: String):
	"""设置开关颜色"""
	color = color_name
	mechanism_color = color_name
	if label_node:
		update_label_color()

func apply_color_scheme(color_name: String):
	"""应用颜色方案"""
	color = color_name
	set_color(color_name)
	print("开关应用颜色方案: %s" % color_name)

func update_label_color():
	"""更新标签颜色"""
	if label_node and color:
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
		if color_map.has(color):
			label_node.modulate = color_map[color]
			print("开关 %s 设置标签颜色为: %s" % [name, color])
		else:
			# 如果没有匹配的颜色，使用默认颜色
			label_node.modulate = Color.WHITE
			print("开关 %s 颜色未匹配，使用默认白色" % [name])
	elif label_node:
		# 如果没有颜色属性，也使用白色
		label_node.modulate = Color.WHITE
		print("开关 %s 没有颜色属性，使用白色" % [name])

func on_bullet_hit(bullet: Node2D):
	"""被子弹击中 - 由基类机制触发"""
	super.on_bullet_hit(bullet)
	# 不在这里切换状态，交给take_damage处理
	print("Switch被子弹击中（基类机制）")

func on_dust_hit(dust: Node2D):
	"""被灰尘击中"""
	super.on_dust_hit(dust)
	# 不在这里切换状态，交给take_damage处理
	print("Switch被灰尘击中（基类机制）")

func take_damage(damage: int, attacker: Variant = null):
	"""接收伤害（用于处理子弹碰撞）"""
	print("开关 %s 接收到伤害: %d, 攻击者: %s" % [name, damage, attacker])
	
	# 防止重复处理
	if is_processing_hit:
		print("开关 %s 已经在处理击中，跳过" % name)
		return
	
	is_processing_hit = true
	
	# 切换状态
	toggle_switch()
	
	# 重置标记
	is_processing_hit = false

func get_switch_state() -> bool:
	"""获取开关状态 - 为门提供查询接口"""
	return switch_state

func toggle_switch():
	"""切换开关状态和文字"""
	print("开始切换开关状态: %s" % name)
	
	# 切换状态
	switch_state = !switch_state
	
	# 更新文字
	if switch_state:
		text = "开"
		print("开关 %s 状态: 开" % name)
	else:
		text = "关"
		print("开关 %s 状态: 关" % name)
	
	# 更新文字显示
	if label_node:
		print("更新标签文字为: ", text)
		label_node.text = text
	else:
		# 如果label_node为null，尝试重新获取
		label_node = get_node("label") as Label
		if label_node:
			label_node.text = text
			print("重新获取label节点并更新文字为: ", text)
		else:
			print("错误：无法获取label节点，文字无法更新！")
	
	# 播放切换效果
	play_switch_effect()
	
	# 通知所有连接的门检查开关状态
	notify_doors()
	
	# 发射状态变化信号
	switch_state_changed.emit(switch_state)
	
	print("开关 %s 状态切换完成，新状态: %s" % [name, ("开" if switch_state else "关")])

func play_switch_effect():
	"""播放开关切换效果"""
	if label_node:
		var tween = get_tree().create_tween()
		
		# 保存当前颜色
		var original_color = label_node.modulate
		
		# 缩放效果
		tween.tween_property(label_node, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(label_node, "scale", Vector2(1.0, 1.0), 0.1)
		
		# 颜色闪烁效果（不改变最终颜色）
		tween.tween_property(label_node, "modulate", Color(1, 0.8, 0.8), 0.1)
		tween.tween_property(label_node, "modulate", original_color, 0.1)
		
		print("播放开关效果，最终颜色恢复为: ", original_color)

func notify_doors():
	"""通知所有连接的门检查开关状态"""
	print("开关 %s 通知门检查开关状态: 连接的门数量: %d" % [name, linked_doors.size()])
	
	for i in range(linked_doors.size()):
		var door = linked_doors[i]
		if door and is_instance_valid(door):
			print("  [%d] 检查门: %s, 有效: %s" % [i, door.name, is_instance_valid(door)])
			if door.has_method("check_switches_state"):
				print("  通知门 %s 检查开关状态" % door.name)
				door.check_switches_state()
			else:
				print("  门 %s 没有 check_switches_state 方法" % door.name)
		else:
			print("  [%d] 门: 无效或已删除" % i)
	
	mechanism_triggered.emit(self, null)
	
func link_door(door: Node2D):
	"""连接门"""
	if door and door not in linked_doors:
		linked_doors.append(door)
		print("开关 %s 连接到门: %s" % [name, door.name])

func unlink_door(door: Node2D):
	"""断开门连接"""
	if door in linked_doors:
		linked_doors.erase(door)
		print("开关 %s 断开连接: %s" % [name, door.name])

func get_switch_data() -> Dictionary:
	"""获取开关数据"""
	var data = get_mechanism_data()
	data["color"] = mechanism_color
	data["switch_state"] = switch_state
	data["text"] = text
	data["linked_doors_count"] = linked_doors.size()
	return data
