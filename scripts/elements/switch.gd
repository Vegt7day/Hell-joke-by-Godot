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


# 在Switch类中添加以下变量
var linked_teleporters: Array = []


func link_teleporter(teleporter: Teleporter):
	"""连接传送门"""
	if not teleporter:
		print("错误: 尝试连接空的传送门")
		return
	
	if teleporter in linked_teleporters:
		print("开关 %s 已连接传送门: %s" % [name, teleporter.name])
		return
	
	# 检查颜色匹配
	if teleporter.color != color:
		print("警告: 传送门 %s 颜色不匹配 (传送门: %s, 开关: %s)" % [
			teleporter.name, 
			teleporter.color, 
			color
		])
		return
	
	linked_teleporters.append(teleporter)
	print("开关 %s 成功连接传送门: %s" % [name, teleporter.name])
	
	# 更新传送门的颜色
	teleporter.set_teleporter_color(color)

func unlink_teleporter(teleporter: Teleporter):
	"""断开传送门连接"""
	if teleporter in linked_teleporters:
		linked_teleporters.erase(teleporter)
		print("开关 %s 断开传送门连接: %s" % [name, teleporter.name])
	else:
		print("开关 %s 未连接传送门: %s" % [name, teleporter.name])

func get_linked_teleporters_by_color(color_filter: String) -> Array:
	"""根据颜色筛选连接的传送门"""
	var filtered_teleporters = []
	
	for teleporter in linked_teleporters:
		if is_instance_valid(teleporter) and teleporter.color == color_filter:
			filtered_teleporters.append(teleporter)
	
	return filtered_teleporters

func get_all_teleporters_by_color(color_filter: String) -> Array:
	"""获取场景中指定颜色的所有传送门（包括未连接的）"""
	var all_teleporters = []
	
	# 查找场景中所有传送门
	var teleporters = get_tree().get_nodes_in_group("teleporters")
	
	for teleporter in teleporters:
		if is_instance_valid(teleporter) and teleporter.color == color_filter:
			all_teleporters.append(teleporter)
	
	return all_teleporters

func toggle_linked_teleporters():
	"""切换所有连接的传送门状态"""
	print("开关 %s 开始切换连接的传送门状态" % name)
	
	for teleporter in linked_teleporters:
		if is_instance_valid(teleporter):
			teleporter.toggle_entrance_state()
	
	print("开关 %s 已切换 %d 个传送门状态" % [name, linked_teleporters.size()])

func notify_linked_teleporters():
	"""通知连接的传送门检查状态"""
	print("开关 %s 通知连接的传送门" % name)
	
	for teleporter in linked_teleporters:
		if is_instance_valid(teleporter) and teleporter.has_method("validate_pairing"):
			teleporter.validate_pairing()

func swap_teleporter_states(color_to_swap: String):
	"""交换指定颜色传送门的状态"""
	print("开关 %s 开始交换颜色为 %s 的传送门状态" % [name, color_to_swap])
	
	# 获取该颜色的所有传送门
	var teleporters = get_all_teleporters_by_color(color_to_swap)
	
	if teleporters.size() < 2:
		print("错误: 颜色 %s 的传送门数量不足2个，无法交换" % color_to_swap)
		return
	
	# 记录原始状态
	var state_map = {}
	for teleporter in teleporters:
		if is_instance_valid(teleporter):
			state_map[teleporter] = teleporter.is_entrance
	
	# 交换状态
	var entrance_count = 0
	var exit_count = 0
	
	for teleporter in teleporters:
		if is_instance_valid(teleporter):
			if teleporter.is_entrance:
				entrance_count += 1
			else:
				exit_count += 1
	
	# 确保至少有一个入口和一个出口
	if entrance_count > 0 and exit_count > 0:
		# 遍历并交换状态
		for teleporter in teleporters:
			if is_instance_valid(teleporter):
				# 切换状态
				teleporter.is_entrance = not teleporter.is_entrance
				teleporter.update_teleporter_label()
				
				print("传送门 %s 状态切换为: %s" % [
					teleporter.name, 
					("传" if teleporter.is_entrance else "送")
				])
	
	# 重新配对传送门
	pair_teleporters_by_color(color_to_swap)
	
	print("开关 %s 完成传送门状态交换" % name)

func pair_teleporters_by_color(color_to_pair: String):
	"""按颜色配对传送门（一个"传"配对一个"送"）"""
	var teleporters = get_all_teleporters_by_color(color_to_pair)
	
	if teleporters.size() < 2:
		print("警告: 颜色 %s 的传送门数量不足2个，无法配对" % color_to_pair)
		return
	
	# 分离入口和出口
	var entrances = []
	var exits = []
	
	for teleporter in teleporters:
		if is_instance_valid(teleporter):
			if teleporter.is_entrance:
				entrances.append(teleporter)
			else:
				exits.append(teleporter)
	
	# 确保至少有入口和出口
	if entrances.size() == 0 or exits.size() == 0:
		print("警告: 颜色 %s 的传送门缺少入口或出口" % color_to_pair)
		return
	
	# 配对（简单的1对1配对）
	for i in range(min(entrances.size(), exits.size())):
		var entrance = entrances[i]
		var exit = exits[i]
		
		if is_instance_valid(entrance) and is_instance_valid(exit):
			entrance.set_paired_target(exit)
			exit.set_paired_target(entrance)
			
			print("配对: %s(传) ↔ %s(送)" % [entrance.name, exit.name])
	
	# 处理剩余未配对的传送门
	var unpaired = []
	if entrances.size() > exits.size():
		for i in range(exits.size(), entrances.size()):
			unpaired.append(entrances[i])
	elif exits.size() > entrances.size():
		for i in range(entrances.size(), exits.size()):
			unpaired.append(exits[i])
	
	for teleporter in unpaired:
		teleporter.clear_paired_target()
		print("警告: 传送门 %s 未配对" % teleporter.name)

func auto_link_teleporters_by_color():
	"""自动连接同颜色的传送门"""
	print("开关 %s 开始自动连接同色传送门" % name)
	
	# 清空现有连接
	linked_teleporters.clear()
	
	# 获取场景中所有传送门
	var all_teleporters = get_tree().get_nodes_in_group("teleporters")
	
	for teleporter in all_teleporters:
		if is_instance_valid(teleporter) and teleporter.color == color:
			link_teleporter(teleporter)
	
	print("开关 %s 自动连接完成，已连接 %d 个传送门" % [name, linked_teleporters.size()])

func clear_teleporter_links():
	"""清除所有传送门连接"""
	print("开关 %s 清除所有传送门连接" % name)
	linked_teleporters.clear()

func get_teleporter_connection_info() -> Dictionary:
	"""获取传送门连接信息"""
	var info = {
		"switch_name": name,
		"switch_color": color,
		"total_linked": linked_teleporters.size(),
		"teleporters": []
	}
	
	for i in range(linked_teleporters.size()):
		var teleporter = linked_teleporters[i]
		if is_instance_valid(teleporter):
			info["teleporters"].append({
				"name": teleporter.name,
				"color": teleporter.color,
				"is_entrance": teleporter.is_entrance,
				"is_paired": teleporter.paired_target != null
			})
	
	return info

func print_teleporter_connections():
	"""打印传送门连接信息（调试用）"""
	var info = get_teleporter_connection_info()
	print("=== 开关 %s 传送门连接信息 ===" % name)
	print("颜色: %s" % info["switch_color"])
	print("连接数: %d" % info["total_linked"])
	
	for i in range(info["teleporters"].size()):
		var tp_info = info["teleporters"][i]
		var state_text = "传" if tp_info["is_entrance"] else "送"
		var paired_text = "已配对" if tp_info["is_paired"] else "未配对"
		print("  [%d] %s (%s, %s, %s)" % [
			i, tp_info["name"], state_text, tp_info["color"], paired_text
		])
	print("==============================")

# 3. 扩展原有的函数，加入传送门控制

func toggle_switch():
	"""切换开关状态和文字（重写以包含传送门控制）"""
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
	

	swap_teleporter_states(color)
	
	# 发射状态变化信号
	switch_state_changed.emit(switch_state)
	
	print("开关 %s 状态切换完成，新状态: %s" % [name, ("开" if switch_state else "关")])
