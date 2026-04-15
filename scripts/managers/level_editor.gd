extends Node2D
class_name LevelEditor

# 导出变量
@export var level_width: int = 20
@export var level_height: int = 15
@export var grid_size: int = 32

# 场景引用
@export var wall_scene: PackedScene
@export var ground_scene: PackedScene
@export var fire_scene: PackedScene
@export var goal_scene: PackedScene
@export var switch_scene: PackedScene
@export var door_scene: PackedScene
@export var teleporter_in_scene: PackedScene
@export var teleporter_out_scene: PackedScene
@export var bow_scene: PackedScene
@export var dirt_scene: PackedScene
@export var player_scene: PackedScene

var is_left_dragging: bool = false
var is_right_dragging: bool = false


@export var current_element_type: String = "wall"

# 关卡数据
var level_data: Dictionary = {}
var elements: Array = []
var grid: Array = []
var player_start_position: Vector2 = Vector2(64, 384)
var current_dragging_element: Node2D = null
var drag_offset: Vector2
var is_dragging: bool = false
var selected_element: Node2D = null
# 在类的变量定义部分添加：
var mouse_pressed_last_frame = false
var right_mouse_pressed_last_frame = false

# 区域拖动相关变量
var is_area_dragging: bool = false
var area_drag_start: Vector2
var area_drag_end: Vector2
var area_rect: Rect2

# 元素类型列表
var element_types: Array = ["wall", "ground", "switch", "door", "fire", "player", "goal", "teleporter_in", "teleporter_out", "bow", "dirt"]
var current_element_index: int = 0

# 颜色定义
var colors: Array = ["红", "绿", "蓝", "黄", "紫", "青", "白", "黑"]
var current_color: String = "红"
var current_color_index: int = 0

# 测试模式相关
var test_mode_active: bool = false
var test_player: CharacterBody2D = null
var test_camera: Camera2D = null
var test_attack_range: float = 100.0
var test_attack_cooldown: float = 0.5
var last_attack_time: float = 0.0

# UI相关
var info_label: Label
var test_mode_label: Label

func _ready():
	"""初始化编辑器"""
	print("地图编辑器初始化")
	load_scenes()
	init_grid()
	
	# 创建UI元素
	create_ui()
	
	# 设置输入映射
	setup_input_map()
	
	# 确保能接收输入
	set_process_input(true)
	set_process(true)
	
	print("地图编辑器准备就绪")

func _on_gui_focus_changed(control: Control):
	"""GUI焦点变化时处理"""
	if control and control.get_parent() and control.get_parent().name == "PropertyPanel":
		is_dragging = false
		current_dragging_element = null
		print("焦点变化，暂停拖拽操作")

func load_scenes():
	"""加载场景"""
	# 如果没有设置，尝试自动加载
	if not wall_scene:
		wall_scene = load("res://scenes/elements/wall.tscn")
	if not ground_scene:
		ground_scene = load("res://scenes/elements/ground.tscn")
	if not fire_scene:
		fire_scene = load("res://scenes/elements/fire.tscn")
	if not goal_scene:
		goal_scene = load("res://scenes/elements/goal.tscn")
	if not switch_scene:
		switch_scene = load("res://scenes/elements/switch.tscn")
	if not door_scene:
		door_scene = load("res://scenes/elements/door.tscn")
	if not teleporter_in_scene:
		teleporter_in_scene = load("res://scenes/elements/teleporter_in.tscn")
	if not teleporter_out_scene:
		teleporter_out_scene = load("res://scenes/elements/teleporter_out.tscn")
	if not bow_scene:
		bow_scene = load("res://scenes/elements/bow.tscn")
	if not dirt_scene:
		dirt_scene = load("res://scenes/elements/dirt.tscn")
	if not player_scene:
		player_scene = load("res://scenes/elements/player.tscn")

func init_grid():
	"""初始化网格"""
	grid = []
	for x in range(level_width):
		grid.append([])
		for y in range(level_height):
			grid[x].append(null)

func create_ui():
	"""创建UI元素"""
	# 信息标签
	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "编辑器已就绪"
	info_label.position = Vector2(10, 10)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 2)
	add_child(info_label)
	
	# 测试模式标签
	test_mode_label = Label.new()
	test_mode_label.name = "TestModeLabel"
	test_mode_label.text = "测试模式: 关闭"
	test_mode_label.position = Vector2(10, 40)
	test_mode_label.add_theme_color_override("font_color", Color.RED)
	test_mode_label.add_theme_color_override("font_outline_color", Color.BLACK)
	test_mode_label.add_theme_constant_override("outline_size", 2)
	test_mode_label.visible = false
	add_child(test_mode_label)
	
	update_ui_info()
func update_ui_info():
	"""更新UI信息"""
	if not info_label:
		return
	
	# 简化的UI信息
	var action_text = ""
	if is_left_dragging:
		action_text = "左键拖拽放置"
	elif is_right_dragging:
		action_text = "右键拖拽删除"
	elif is_dragging:
		action_text = "拖拽元素"
	else:
		action_text = "编辑模式"
	
	info_label.text = "%s | 元素: %s | 颜色: %s" % [action_text, element_types[current_element_index], colors[current_color_index]]
func _input(event):
	"""处理输入（只处理键盘）"""
	# 鼠标按钮事件
	if event is InputEventMouseButton:
		if test_mode_active:
			# 测试模式下的鼠标事件
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				handle_test_attack()
		else:
			# 编辑器模式下的鼠标事件
			handle_editor_mouse(event)
		
		# 鼠标滚轮切换元素类型
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				handle_mouse_wheel_up(event)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				handle_mouse_wheel_down(event)
	
	# 切换元素类型
	elif event.is_action_pressed("element_wall"):
		select_element_type("wall")
	elif event.is_action_pressed("element_ground"):
		select_element_type("ground")
	elif event.is_action_pressed("element_switch"):
		select_element_type("switch")
	elif event.is_action_pressed("element_door"):
		select_element_type("door")
	elif event.is_action_pressed("element_fire"):
		select_element_type("fire")
	elif event.is_action_pressed("element_player"):
		select_element_type("player")
	elif event.is_action_pressed("element_goal"):
		select_element_type("goal")
	elif event.is_action_pressed("element_teleporter_in"):
		select_element_type("teleporter_in")
	elif event.is_action_pressed("element_teleporter_out"):
		select_element_type("teleporter_out")
	elif event.is_action_pressed("element_bow"):
		select_element_type("bow")
	elif event.is_action_pressed("element_dirt"):
		select_element_type("dirt")
	
	# 保存/加载
	elif event.is_action_pressed("editor_save"):
		save_level("user://custom_level.json")
	elif event.is_action_pressed("editor_load"):
		load_level("user://custom_level.json")
	elif event.is_action_pressed("editor_clear"):
		clear_level()
		
func select_element_type(type_name: String):
	"""选择元素类型"""
	current_element_index = element_types.find(type_name)
	if current_element_index != -1:
		current_element_type = element_types[current_element_index]
		update_ui_info()
		print("选择元素: %s" % current_element_type)
		queue_redraw()

func handle_mouse_wheel_up(event: InputEventMouseButton):
	"""处理鼠标滚轮上滚"""
	if event.shift_pressed:
		# Shift+滚轮：切换颜色
		current_color_index = (current_color_index - 1) % colors.size()
		current_color = colors[current_color_index]
		print("切换到颜色: %s" % current_color)
	else:
		# 向上滚轮：切换到上一个元素类型
		current_element_index = (current_element_index - 1) % element_types.size()
		current_element_type = element_types[current_element_index]
		print("切换到元素: %s" % current_element_type)
	update_ui_info()
	queue_redraw()

func handle_mouse_wheel_down(event: InputEventMouseButton):
	"""处理鼠标滚轮下滚"""
	if event.shift_pressed:
		# Shift+滚轮：切换颜色
		current_color_index = (current_color_index + 1) % colors.size()
		current_color = colors[current_color_index]
		print("切换到颜色: %s" % current_color)
	else:
		# 向下滚轮：切换到下一个元素类型
		current_element_index = (current_element_index + 1) % element_types.size()
		current_element_type = element_types[current_element_index]
		print("切换到元素: %s" % current_element_type)
	update_ui_info()
	queue_redraw()



func save_level(path: String):
	"""保存关卡"""
	print("保存关卡到: %s" % path)
	
	var save_data = {
		"version": "1.0",
		"level_width": level_width,
		"level_height": level_height,
		"grid_size": grid_size,
		"player_start": {"x": player_start_position.x, "y": player_start_position.y},
		"elements": []
	}
	
	# 保存所有元素
	for element in elements:
		if is_instance_valid(element):
			var element_data = get_element_data(element)
			if element_data:
				save_data["elements"].append(element_data)
	
	# 保存为JSON
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		print("关卡保存成功: %s" % path)
		return true
	else:
		print("保存关卡失败")
		return false

func load_level(path: String) -> bool:
	"""加载关卡"""
	print("加载关卡: %s" % path)
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path):
		print("错误: 关卡文件不存在: %s" % path)
		return false
	
	# 打开文件
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			var json_data = json.get_data()
			if json_data:
				# 清空现有关卡
				clear_level()
				
				# 设置关卡参数
				level_width = json_data.get("level_width", 20)
				level_height = json_data.get("level_height", 15)
				grid_size = json_data.get("grid_size", 32)
				
				var player_start = json_data.get("player_start", {"x": 64, "y": 384})
				player_start_position = Vector2(player_start.x, player_start.y)
				
				# 重新初始化网格
				init_grid()
				
				# 加载元素
				var element_count = 0
				for element_data in json_data.get("elements", []):
					var element = create_element_from_data(element_data)
					if element:
						element_count += 1
				
				print("关卡加载完成，共 %d 个元素" % element_count)
				
				# 刷新UI
				update_ui_info()
				queue_redraw()
				
				return true
			else:
				print("错误: JSON数据为空")
		else:
			print("错误: JSON解析失败: %s" % json.get_error_message())
	else:
		print("错误: 无法打开关卡文件")
	
	print("加载关卡失败")
	return false

func clear_level():
	"""清空关卡"""
	print("清空关卡...")
	
	# 删除所有元素
	for element in elements:
		if is_instance_valid(element):
			element.queue_free()
	
	# 清空元素列表
	elements.clear()
	
	# 清空网格
	init_grid()
	
	# 重置玩家起始位置
	player_start_position = Vector2(64, 384)
	
	# 清空level_data字典
	level_data.clear()
	
	# 刷新显示
	queue_redraw()
	
	print("关卡已清空")
func fill_area(start: Vector2, end: Vector2):
	"""填充区域"""
	print("开始填充区域: 从 %s 到 %s" % [start, end])
	
	# 计算区域边界
	var start_x = int(min(start.x, end.x))
	var end_x = int(max(start.x, end.x))
	var start_y = int(min(start.y, end.y))
	var end_y = int(max(start.y, end.y))
	
	print("区域范围: x[%d-%d], y[%d-%d]" % [start_x, end_x, start_y, end_y])
	
	var filled_count = 0
	
	# 遍历区域内的所有网格
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var grid_pos = Vector2(x, y)
			
			# 检查位置是否有效
			if is_valid_grid_position(grid_pos):
				# 检查位置是否已被占用
				if grid[x][y] == null:
					# 创建元素
					var element = create_element(current_element_type, grid_pos)
					if element:
						# 添加到网格
						grid[x][y] = element
						filled_count += 1
						print("✓ 在 %s 放置了 %s" % [grid_pos, current_element_type])
					else:
						print("✗ 在 %s 创建元素失败" % grid_pos)
				else:
					print("✗ 位置 %s 已被占用" % grid_pos)
			else:
				print("✗ 无效的网格位置: %s" % grid_pos)
	
	print("区域填充完成，共放置 %d 个元素" % filled_count)
	
	# 更新显示
	queue_redraw()
func clear_area(start: Vector2, end: Vector2):
	"""清除区域内的元素"""
	if not is_valid_grid_position(start) or not is_valid_grid_position(end):
		return
	
	# 计算区域边界
	var start_x = int(min(start.x, end.x))
	var end_x = int(max(start.x, end.x))
	var start_y = int(min(start.y, end.y))
	var end_y = int(max(start.y, end.y))
	
	var cleared_count = 0
	
	# 遍历区域内的所有网格
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var grid_pos = Vector2(x, y)
			
			# 检查位置是否有元素
			if is_valid_grid_position(grid_pos) and grid[x][y] != null:
				# 删除元素
				if delete_element_at(grid_pos):
					cleared_count += 1
	
	print("区域清除完成，共删除 %d 个元素" % cleared_count)

func toggle_test_mode():
	"""切换测试模式"""
	test_mode_active = !test_mode_active
	
	if test_mode_active:
		enter_test_mode()
	else:
		exit_test_mode()
	
	test_mode_label.visible = test_mode_active
	test_mode_label.text = "测试模式: %s" % ("激活" if test_mode_active else "关闭")
	update_ui_info()
	print("测试模式: %s" % ("激活" if test_mode_active else "关闭"))

func enter_test_mode():
	"""进入测试模式"""
	# 创建测试玩家
	create_test_player()
	# 设置测试控制
	InputMap.add_action("test_move_left")
	var event = InputEventKey.new()
	event.keycode = KEY_A
	InputMap.action_add_event("test_move_left", event)
	
	InputMap.add_action("test_move_right")
	event = InputEventKey.new()
	event.keycode = KEY_D
	InputMap.action_add_event("test_move_right", event)
	
	InputMap.add_action("test_jump")
	event = InputEventKey.new()
	event.keycode = KEY_W
	InputMap.action_add_event("test_jump", event)
	
	InputMap.add_action("test_attack")
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("test_attack", event)
	
	InputMap.add_action("test_exit")
	event = InputEventKey.new()
	event.keycode = KEY_TAB
	InputMap.action_add_event("test_exit", event)
	
	print("进入测试模式")

func exit_test_mode():
	"""退出测试模式"""
	# 删除测试玩家
	if test_player:
		test_player.queue_free()
		test_player = null
	
	if test_camera:
		test_camera.queue_free()
		test_camera = null
	
	# 恢复编辑器输入映射
	setup_input_map()
	
	print("退出测试模式")

func create_test_player():
	"""创建测试玩家"""
	# 如果已有玩家，使用现有玩家
	var existing_players = get_tree().get_nodes_in_group("player")
	if existing_players.size() > 0:
		test_player = existing_players[0]
		print("使用现有玩家进行测试")
		return
	
	# 创建新的测试玩家
	if player_scene:
		test_player = player_scene.instantiate() as CharacterBody2D
		if test_player:
			test_player.position = player_start_position
			add_child(test_player)
			
			# 创建测试相机
			test_camera = Camera2D.new()
			test_camera.name = "TestCamera"
			test_camera.make_current()
			test_player.add_child(test_camera)
			
			print("创建测试玩家在位置: %s" % player_start_position)
	else:
		print("错误: 无法加载玩家场景")

func get_element_data(element: Node2D) -> Dictionary:
	"""获取元素数据"""
	var data = {
		"type": "unknown",
		"position": {"x": element.position.x, "y": element.position.y}
	}
	
	if element is Wall:
		data["type"] = "wall"
	elif element is Ground:
		data["type"] = "ground"
	elif element is Switch:
		data["type"] = "switch"
		if element.has_property("door_color"):
			data["door_color"] = element.door_color

	elif element is Door:
		data["type"] = "door"
		if element.has_property("door_color"):
			data["door_color"] = element.door_color
		if element.has_property("current_state"):
			data["state"] = element.current_state
	
	elif element is FireTrap:
		data["type"] = "fire"
		if element.has_property("damage"):
			data["damage"] = element.damage
	
	elif element is Goal:
		data["type"] = "goal"
		if element.has_property("level_to_load"):
			data["level_to_load"] = element.level_to_load
	
	elif element is Mechanism:
		data["type"] = "mechanism"
		if element.has_property("mechanism_type"):
			data["mechanism_type"] = element.mechanism_type
		if element.has_property("text"):
			data["text"] = element.text
		if element.has_property("mechanism_color"):
			data["color"] = element.mechanism_color
		if element.has_property("is_active"):
			data["is_active"] = element.is_active
	
	# 尝试从元素名称推断类型
	var name_lower = element.name.to_lower()
	if "wall" in name_lower:
		data["type"] = "wall"
	elif "ground" in name_lower:
		data["type"] = "ground"
	elif "bow" in name_lower:
		data["type"] = "bow"
	elif "dirt" in name_lower:
		data["type"] = "dirt"
	elif "player" in name_lower:
		data["type"] = "player"
	elif "teleporter" in name_lower:
		if "in" in name_lower:
			data["type"] = "teleporter_in"
		else:
			data["type"] = "teleporter_out"
		if element.has_method("get_color"):
			data["color"] = element.get_color()
	
	return data

func create_element_from_data(data: Dictionary) -> Node2D:
	"""从数据创建元素"""
	var position = Vector2(data["position"]["x"], data["position"]["y"])
	var element = null
	var element_type = data.get("type", "unknown")
	
	match element_type:
		

		"fire":
			if fire_scene:
				element = fire_scene.instantiate() as Node2D
				if element and element.has_property("damage") and "damage" in data:
					element.damage = data["damage"]
		
		"goal":
			if goal_scene:
				element = goal_scene.instantiate() as Node2D
				if element and element.has_property("level_to_load") and "level_to_load" in data:
					element.level_to_load = data["level_to_load"]
		
		"switch":
			if switch_scene:
				element = switch_scene.instantiate() as Node2D
				if element and element.has_property("door_color") and "door_color" in data:
					element.door_color = data["door_color"]
		
		"door":
			if door_scene:
				element = door_scene.instantiate() as Node2D
				if element and element.has_property("door_color") and "door_color" in data:
					element.door_color = data["door_color"]
					if element.has_property("current_state") and "state" in data:
						element.current_state = data["state"]
		
		"teleporter_in":
			if teleporter_in_scene:
				element = teleporter_in_scene.instantiate() as Node2D
				if element and element.has_method("set_color") and "color" in data:
					element.set_color(data["color"])
		
		"teleporter_out":
			if teleporter_out_scene:
				element = teleporter_out_scene.instantiate() as Node2D
				if element and element.has_method("set_color") and "color" in data:
					element.set_color(data["color"])
		
		"player":
			if player_scene:
				element = player_scene.instantiate() as Node2D
				player_start_position = position
		
		"bow":
			if bow_scene:
				element = bow_scene.instantiate() as Node2D
		
		"dirt":
			if dirt_scene:
				element = dirt_scene.instantiate() as Node2D
		
		_:
			print("未知元素类型: %s" % element_type)
	
	if element:
		# 设置位置
		element.position = position
		
		# 添加到场景
		add_child(element)
		elements.append(element)
		
		# 计算网格位置
		var grid_pos = world_to_grid(element.position)
		if is_valid_grid_position(grid_pos):
			grid[grid_pos.x][grid_pos.y] = element
		
		# 设置其他属性
		if "color" in data and element.has_method("set_color"):
			element.call("set_color", data["color"])
		elif "color" in data and element.has_property("mechanism_color"):
			element.mechanism_color = data["color"]
		
		if "text" in data and element.has_property("text"):
			element.text = data["text"]
		
		return element
	
	return null

func world_to_grid(pos: Vector2) -> Vector2:
	"""将世界坐标转换为网格坐标"""
	# 确保坐标是相对于编辑器节点的局部坐标
	var local_pos = to_local(pos)
	return Vector2(floor(local_pos.x / grid_size), floor(local_pos.y / grid_size))

func grid_to_world(pos: Vector2) -> Vector2:
	"""将网格坐标转换为世界坐标"""
	return Vector2(pos.x * grid_size + grid_size / 2, pos.y * grid_size + grid_size / 2)

func is_valid_grid_position(pos: Vector2) -> bool:
	"""检查网格位置是否有效"""
	return pos.x >= 0 and pos.x < level_width and pos.y >= 0 and pos.y < level_height

func place_element_at(grid_pos: Vector2) -> void:
	"""在指定网格位置放置元素"""
	print("尝试在网格位置 %s 放置元素" % grid_pos)
	
	if not is_valid_grid_position(grid_pos):
		print("错误: 无效的网格位置: ", grid_pos)
		return
	
	# 检查位置是否已被占用
	if grid[grid_pos.x][grid_pos.y] != null:
		var element = grid[grid_pos.x][grid_pos.y]
		print("位置已被占用，元素: %s" % element.name)
		return
	
	# 特殊处理：玩家只能有一个
	if current_element_type == "player":
		# 删除现有的玩家
		for element in elements:
			if element.name == "Player":
				element.queue_free()
				elements.erase(element)
				break
	
	# 创建元素
	var element = create_element(current_element_type, grid_pos)
	if element:
		# 添加到网格
		grid[grid_pos.x][grid_pos.y] = element
		print("在 %s 放置了 %s" % [grid_pos, current_element_type])
		
		# 更新显示
		queue_redraw()
	else:
		print("创建元素失败，类型: %s" % current_element_type)
func create_element(element_type: String, grid_pos: Vector2) -> Node2D:
	"""创建新元素"""
	var element = null
	# 确保位置是格子中心
	var world_pos = Vector2(
		grid_pos.x * grid_size + grid_size / 2,
		grid_pos.y * grid_size + grid_size / 2
	)
	
	print("创建元素: 类型=%s, 网格位置=%s, 世界位置=%s" % [element_type, grid_pos, world_pos])
	
	match element_type:
		
		"wall":
			if wall_scene:
				element = wall_scene.instantiate()
				if element:
					element.name = "Wall_%d_%d" % [grid_pos.x, grid_pos.y]
		"ground":
			if ground_scene:
				element = ground_scene.instantiate()
				if element:
					element.name = "Ground%d_%d" % [grid_pos.x, grid_pos.y]
		
	
		
		
		"switch":
			if switch_scene:
				element = switch_scene.instantiate()
				if element:
					element.name = "Switch_%d_%d" % [grid_pos.x, grid_pos.y]
		
		"door":
			if door_scene:
				element = door_scene.instantiate()
				if element:
					element.name = "Door_%d_%d" % [grid_pos.x, grid_pos.y]
		
		"fire":
			if fire_scene:
				element = fire_scene.instantiate()
				if element:
					element.name = "FireTrap_%d_%d" % [grid_pos.x, grid_pos.y]
		
		"player":
			if player_scene:
				element = player_scene.instantiate()
				if element:
					element.name = "Player"
					player_start_position = world_pos
					print("设置玩家起始位置: %s" % world_pos)
		
		"goal":
			if goal_scene:
				element = goal_scene.instantiate()
				if element:
					element.name = "Goal_%d_%d" % [grid_pos.x, grid_pos.y]
		
		"teleporter_in":
			if teleporter_in_scene:
				element = teleporter_in_scene.instantiate()
				if element:
					element.name = "TeleporterIn_%d_%d" % [grid_pos.x, grid_pos.y]
					if element.has_method("set_color"):
						var color_index = colors.find(current_color)
						if color_index >= 0:
							element.set_color(color_index)
		
		"teleporter_out":
			if teleporter_out_scene:
				element = teleporter_out_scene.instantiate()
				if element:
					element.name = "TeleporterOut_%d_%d" % [grid_pos.x, grid_pos.y]
					if element.has_method("set_color"):
						var color_index = colors.find(current_color)
						if color_index >= 0:
							element.set_color(color_index)
		
		"bow":
			if bow_scene:
				element = bow_scene.instantiate()
				if element:
					element.name = "Bow_%d_%d" % [grid_pos.x, grid_pos.y]
		
		"dirt":
			if dirt_scene:
				element = dirt_scene.instantiate()
				if element:
					element.name = "Dirt_%d_%d" % [grid_pos.x, grid_pos.y]
			else:
				print("错误: 泥土场景未加载")
		
		_:  # 默认分支
			print("未知元素类型: %s" % element_type)
			return null  # 明确返回null
	
	if element:
		# 设置位置
		element.position = world_pos
		
		# 添加到场景
		add_child(element)
		elements.append(element)
		
		# 设置颜色
		if element.has_method("set_color"):
			var color_index = colors.find(current_color)
			if color_index >= 0:
				element.set_color(color_index)
		
		print("元素创建成功: %s" % element.name)
		return element
	
	print("元素实例化失败")
	return null
func select_element_at(grid_pos: Vector2) -> void:
	"""选择指定网格位置的元素"""
	if not is_valid_grid_position(grid_pos):
		return
	
	var element = grid[grid_pos.x][grid_pos.y]
	if element:
		selected_element = element
		print("选择了元素: %s 在位置: %s" % [element.name, grid_pos])
		
		# 更新显示
		queue_redraw()
	else:
		selected_element = null
		print("没有元素在位置: %s" % grid_pos)

func delete_element_at(grid_pos: Vector2) -> bool:
	"""删除指定网格位置的元素"""
	if not is_valid_grid_position(grid_pos):
		return false
	
	var element = grid[grid_pos.x][grid_pos.y]
	if element:
		# 从场景中移除
		if is_instance_valid(element):
			element.queue_free()
		
		# 从元素列表中移除
		var index = elements.find(element)
		if index != -1:
			elements.remove_at(index)
		
		# 从网格中移除
		grid[grid_pos.x][grid_pos.y] = null
		
		print("删除了元素: %s 在位置: %s" % [element.name, grid_pos])
		
		# 如果删除的是选中元素，清空选择
		if selected_element == element:
			selected_element = null
		
		# 更新显示
		queue_redraw()
		return true
	else:
		print("没有元素在位置: %s" % grid_pos)
		return false

func end_drag() -> void:
	"""结束拖拽元素"""
	if current_dragging_element:
		print("结束拖拽元素: %s" % current_dragging_element.name)
		
		# 对齐到网格
		var new_grid_pos = world_to_grid(current_dragging_element.position)
		
		# 检查新位置是否有效
		if is_valid_grid_position(new_grid_pos):
			# 检查新位置是否被占用
			if grid[new_grid_pos.x][new_grid_pos.y] != null and grid[new_grid_pos.x][new_grid_pos.y] != current_dragging_element:
				print("目标位置已被占用，元素位置已恢复")
				# 恢复原来的位置
				var old_grid_pos = world_to_grid(current_dragging_element.position - Vector2(1, 1))
				if is_valid_grid_position(old_grid_pos):
					current_dragging_element.position = grid_to_world(old_grid_pos)
			else:
				# 更新网格
				var old_grid_pos = world_to_grid(current_dragging_element.position - drag_offset)
				if is_valid_grid_position(old_grid_pos) and grid[old_grid_pos.x][old_grid_pos.y] == current_dragging_element:
					grid[old_grid_pos.x][old_grid_pos.y] = null
				
				if grid[new_grid_pos.x][new_grid_pos.y] != current_dragging_element:
					grid[new_grid_pos.x][new_grid_pos.y] = current_dragging_element
				
				# 对齐到网格
				current_dragging_element.position = grid_to_world(new_grid_pos)
		
		# 更新显示
		queue_redraw()
		
		# 重置拖拽状态
		is_dragging = false
		current_dragging_element = null
func get_element_bounds(element: Node2D) -> Rect2:
	"""获取元素的边界矩形"""
	var bounds = Rect2(element.position, Vector2(grid_size, grid_size))
	
	# 检查元素是否包含grid_width和grid_height属性
	if element is Wall or element is Ground or element is Mechanism:
		# 使用属性名直接检查
		var width = 1
		var height = 1
		
		# 尝试获取grid_width属性
		if element.has_property("grid_width"):
			width = element.grid_width
		elif element.has_meta("grid_width"):
			width = element.get_meta("grid_width")
		elif element.has_method("get_grid_width"):
			width = element.get_grid_width()
		
		# 尝试获取grid_height属性
		if element.has_property("grid_height"):
			height = element.grid_height
		elif element.has_meta("grid_height"):
			height = element.get_meta("grid_height")
		elif element.has_method("get_grid_height"):
			height = element.get_grid_height()
		
		bounds.size = Vector2(width * grid_size, height * grid_size)
	
	# 如果元素是 Sprite2D，使用纹理大小
	elif element is Sprite2D and element.texture:
		bounds.size = element.texture.get_size() * element.scale
	
	return bounds
	
	
func handle_test_attack():
	"""处理测试攻击"""
	if not test_player or not test_mode_active:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < test_attack_cooldown:
		return
	
	last_attack_time = current_time
	
	# 获取鼠标位置
	var mouse_pos = get_global_mouse_position()
	
	# 计算攻击方向
	var attack_direction = (mouse_pos - test_player.position).normalized()
	
	# 攻击范围
	var attack_start = test_player.position
	var attack_end = test_player.position + attack_direction * test_attack_range
	
	# 绘制攻击效果
	draw_attack_effect(attack_start, attack_end)
	
	# 检测攻击范围内的机关
	detect_and_trigger_mechanisms(attack_start, attack_end)
	
	print("玩家攻击: 从 %s 到 %s" % [attack_start, attack_end])

func draw_attack_effect(start: Vector2, end: Vector2):
	"""绘制攻击效果"""
	# 创建攻击效果节点
	var attack_line = Line2D.new()
	attack_line.width = 3.0
	attack_line.default_color = Color(1.0, 0.0, 0.0, 0.8)
	attack_line.points = [start, end]
	add_child(attack_line)
	
	# 创建定时器自动删除
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(func():
		attack_line.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func detect_and_trigger_mechanisms(start: Vector2, end: Vector2):
	"""检测并触发机关"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start, end)
	query.collision_mask = 1
	query.exclude = [test_player] if test_player else []
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		
		# 检查是否是机关
		if collider is Switch:
			collider.interact()
			print("攻击触发了开关")
		elif collider is Door:
			if collider.has_method("interact"):
				collider.interact()
				print("攻击触发了门")
		elif collider is Mechanism:
			if collider.has_method("activate"):
				collider.activate()
				print("攻击触发了机关")
		elif collider is FireTrap:
			if collider.has_method("activate"):
				collider.activate()
				print("攻击触发了火焰陷阱")
		elif "Teleporter" in collider.name:
			if collider.has_method("activate"):
				collider.activate()
				print("攻击触发了传送门")
		elif "Bow" in collider.name:
			if collider.has_method("shoot"):
				collider.shoot()
				print("攻击触发了弓箭")
func _draw():
	"""绘制网格和当前元素预览"""
	# 绘制网格背景
	var grid_color = Color(0.2, 0.2, 0.2, 0.1)
	for x in range(level_width):
		for y in range(level_height):
			var rect = Rect2(x * grid_size, y * grid_size, grid_size, grid_size)
			draw_rect(rect, grid_color, true)
			draw_rect(rect, Color(0.5, 0.5, 0.5, 0.2), false)
	
	# 绘制当前元素预览 - 常态显示
	# 只在没有拖拽和测试模式时显示
	if not test_mode_active and not is_dragging:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		
		if is_valid_grid_position(grid_pos):
			var preview_color = Color(0, 1, 0, 0.3)
			
			# 绘制单个格子预览
			var preview_rect = Rect2(
				grid_pos.x * grid_size + 2,
				grid_pos.y * grid_size + 2,
				grid_size - 4,
				grid_size - 4
			)
			draw_rect(preview_rect, preview_color, true)
			
			# 显示当前元素名称
			draw_string(
				ThemeDB.fallback_font,
				Vector2(grid_pos.x * grid_size + 5, grid_pos.y * grid_size + 15),
				current_element_type,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12
			)
			
			# 显示当前颜色
			draw_string(
				ThemeDB.fallback_font,
				Vector2(grid_pos.x * grid_size + 5, grid_pos.y * grid_size + 30),
				"颜色: " + current_color,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12
			)
	
	# 绘制区域拖拽预览
	if is_area_dragging:
		var area_color = Color.RED if is_right_dragging else Color.GREEN
		area_color.a = 0.3
		draw_rect(area_rect, area_color, true)
		draw_rect(area_rect, area_color, false, 2.0)
		
		# 显示区域信息
		var width = int(area_rect.size.x / grid_size)
		var height = int(area_rect.size.y / grid_size)
		var info_text = "区域: %d×%d" % [width, height]
		draw_string(
			ThemeDB.fallback_font,
			Vector2(area_rect.position.x + 5, area_rect.position.y - 5),
			info_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12
		)
	
	# 绘制玩家起始位置
	if player_start_position and not test_mode_active:
		draw_circle(player_start_position, 8, Color(0, 1, 0, 0.5))
		draw_string(
			ThemeDB.fallback_font,
			player_start_position + Vector2(-10, -20),
			"玩家",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12
		)
	
	# 绘制拖拽中的元素边框
	if current_dragging_element and not test_mode_active:
		var bounds = get_element_bounds(current_dragging_element)
		draw_rect(bounds, Color(1, 0, 0, 0.5), false, 2.0)
	
	# 在测试模式下绘制攻击范围
	if test_mode_active and test_player:
		var mouse_pos = get_global_mouse_position()
		var attack_range_circle = test_attack_range
		
		# 绘制攻击范围圆
		draw_arc(test_player.position, attack_range_circle, 0, TAU, 32, Color(1, 0, 0, 0.3), 2.0)
		
		# 绘制朝向鼠标的线
		var attack_direction = (mouse_pos - test_player.position).normalized()
		var attack_end = test_player.position + attack_direction * attack_range_circle
		draw_line(test_player.position, attack_end, Color(1, 0, 0, 0.5), 2.0)
		
		# 绘制鼠标位置
		draw_circle(mouse_pos, 5, Color(1, 1, 0, 0.8))
		
func _process(delta):
	"""主处理函数"""
	handle_mouse_motion()
	handle_debug_info()
	update_ui_info()  # 实时更新UI信息
	
	# 强制重绘，让预览持续更新
	queue_redraw()
	
	# 调试信息
	if is_area_dragging:
		print("区域拖拽状态: 从 %s 到 %s, 左键: %s, 右键: %s" % [
			area_drag_start, 
			area_drag_end,
			is_left_dragging,
			is_right_dragging
		])

func handle_editor_mouse(event: InputEventMouseButton):
	"""处理编辑器模式下的鼠标事件"""
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	
	print("鼠标事件: 按钮=%d, 按下=%s" % [event.button_index, event.pressed])
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 左键按下
			print("左键按下 (位置: %s)" % grid_pos)
			
			# 先检查是否是元素拖拽
			if is_valid_grid_position(grid_pos) and grid[grid_pos.x][grid_pos.y] != null:
				# 开始拖拽现有元素
				current_dragging_element = grid[grid_pos.x][grid_pos.y]
				drag_offset = mouse_pos - current_dragging_element.position
				is_dragging = true
				print("开始拖拽元素: %s" % current_dragging_element.name)
			else:
				# 否则开始区域拖拽
				is_left_dragging = true
				is_area_dragging = true
				area_drag_start = grid_pos
				area_drag_end = grid_pos
				print("开始左键区域放置拖拽，起始点: %s" % area_drag_start)
		else:
			# 左键释放
			print("左键释放 (位置: %s)" % grid_pos)
			
			# 如果是元素拖拽，结束拖拽
			if is_dragging and current_dragging_element:
				end_drag()
				is_dragging = false
				current_dragging_element = null
				print("结束元素拖拽")
			
			# 左键释放：结束区域放置
			elif is_left_dragging and is_area_dragging:
				print("结束左键区域放置，从 %s 到 %s" % [area_drag_start, area_drag_end])
				# 如果区域大小为1x1，则放置单个元素
				if area_drag_start == area_drag_end:
					place_element_at(area_drag_start)
				else:
					fill_area(area_drag_start, area_drag_end)
				
				is_left_dragging = false
				is_area_dragging = false
				area_rect = Rect2()
				queue_redraw()
				print("区域拖拽结束")
	
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# 右键按下
			print("右键按下 (位置: %s)" % grid_pos)
			# 右键按下：开始区域删除
			is_right_dragging = true
			is_area_dragging = true
			area_drag_start = grid_pos
			area_drag_end = grid_pos
			print("开始右键区域删除拖拽，起始点: %s" % area_drag_start)
		else:
			# 右键释放
			print("右键释放 (位置: %s)" % grid_pos)
			# 右键释放：结束区域删除
			if is_right_dragging and is_area_dragging:
				print("结束右键区域删除，从 %s 到 %s" % [area_drag_start, area_drag_end])
				# 如果区域大小为1x1，则删除单个元素
				if area_drag_start == area_drag_end:
					delete_element_at(area_drag_start)
				else:
					clear_area(area_drag_start, area_drag_end)
				
				is_right_dragging = false
				is_area_dragging = false
				area_rect = Rect2()
				queue_redraw()
				print("区域删除结束")

	
func handle_mouse_motion():
	"""处理鼠标移动"""
	# 如果是区域拖拽（左键或右键），更新区域
	if is_area_dragging and (is_left_dragging or is_right_dragging):
		var mouse_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		
		if is_valid_grid_position(grid_pos):
			area_drag_end = grid_pos
			
			# 计算区域矩形
			var start_x = min(area_drag_start.x, area_drag_end.x)
			var end_x = max(area_drag_start.x, area_drag_end.x)
			var start_y = min(area_drag_start.y, area_drag_end.y)
			var end_y = max(area_drag_start.y, area_drag_end.y)
			
			# 创建区域矩形
			area_rect = Rect2(
				start_x * grid_size,
				start_y * grid_size,
				(end_x - start_x + 1) * grid_size,
				(end_y - start_y + 1) * grid_size
			)
			
			# 强制重绘
			queue_redraw()
			
			# 调试信息
			if Time.get_ticks_msec() % 100 == 0:  # 每100毫秒打印一次，避免太频繁
				print("区域拖拽更新: 从%s到%s, 大小: %dx%d" % [
					area_drag_start, 
					area_drag_end,
					(end_x - start_x + 1),
					(end_y - start_y + 1)
				])
	
	# 如果是元素拖拽
	elif current_dragging_element:
		var mouse_pos = get_global_mouse_position()
		
		if Input.is_key_pressed(KEY_CTRL):
			# Ctrl键：自由移动
			current_dragging_element.position = mouse_pos - drag_offset
		else:
			# 默认：对齐到网格
			var grid_pos = world_to_grid(mouse_pos - drag_offset)
			if is_valid_grid_position(grid_pos):
				current_dragging_element.position = grid_to_world(grid_pos)
				
				
var debug_last_print_time = 0	
func handle_debug_info():
	"""处理调试信息"""
	var current_time = Time.get_ticks_msec()
	
	# 每秒打印一次调试信息
	if current_time - debug_last_print_time > 1000:
		if is_area_dragging:
			print("调试: 持续区域拖拽中, 从 %s 到 %s, 模式=%s" % [
				area_drag_start, 
				area_drag_end
			])
		debug_last_print_time = current_time
func setup_input_map():
	"""设置输入映射"""
	# 清除现有输入映射
	InputMap.action_erase_events("test_move_left")
	InputMap.action_erase_events("test_move_right")
	InputMap.action_erase_events("test_jump")
	InputMap.action_erase_events("test_attack")
	InputMap.action_erase_events("test_exit")
	
	# 移除模式切换的按键映射
	# InputMap.add_action("editor_select_mode")
	# InputMap.add_action("editor_place_mode")
	# InputMap.add_action("editor_delete_mode")
	# InputMap.add_action("editor_toggle_area_mode")
	
	# 保留测试模式切换
	InputMap.add_action("editor_toggle_test")
	var event = InputEventKey.new()
	event.keycode = KEY_TAB
	InputMap.action_add_event("editor_toggle_test", event)
	
	# 元素选择
	InputMap.add_action("element_wall")
	event = InputEventKey.new()
	event.keycode = KEY_1
	InputMap.action_add_event("element_wall", event)
	
	InputMap.add_action("element_ground")
	event = InputEventKey.new()
	event.keycode = KEY_2
	InputMap.action_add_event("element_ground", event)
	
	# ... 其他元素按键映射保持不变
	
	# 颜色选择
	InputMap.add_action("color_0")
	event = InputEventKey.new()
	event.keycode = KEY_0
	event.alt_pressed = true
	InputMap.action_add_event("color_0", event)
	
	# ... 其他颜色按键映射保持不变
	
	# 文件操作
	InputMap.add_action("editor_save")
	event = InputEventKey.new()
	event.keycode = KEY_S
	event.ctrl_pressed = true
	InputMap.action_add_event("editor_save", event)
	
	InputMap.add_action("editor_load")
	event = InputEventKey.new()
	event.keycode = KEY_L
	event.ctrl_pressed = true
	InputMap.action_add_event("editor_load", event)
	
	InputMap.add_action("editor_clear")
	event = InputEventKey.new()
	event.keycode = KEY_C
	event.ctrl_pressed = true
	InputMap.action_add_event("editor_clear", event)
func _notification(what):
	"""处理节点通知"""
	if what == NOTIFICATION_ENTER_TREE:
		setup_input_map()
