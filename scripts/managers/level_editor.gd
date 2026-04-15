extends Node2D
class_name LevelEditor

# 导出变量
@export var level_width: int = 20
@export var level_height: int = 15
@export var grid_size: int = 32
@export var char_size: int = 24

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

# 编辑模式
enum EditMode {
	SELECT,
	PLACE,
	DELETE
}

@export var current_edit_mode: EditMode = EditMode.PLACE
@export var current_element_type: String = "wall"
@export var current_element_name: String = "brick"

# 关卡数据
var level_data: Dictionary = {}
var elements: Array = []
var grid: Array = []
var player_start_position: Vector2 = Vector2(64, 384)  # 默认位置
var current_dragging_element: Node2D = null
var drag_start_pos: Vector2
var drag_offset: Vector2
var is_dragging: bool = false
var selected_element: Node2D = null
var drag_start_grid_pos: Vector2  # 添加这个变量

# 颜色定义
var colors: Array = ["红", "绿", "蓝", "黄", "紫", "青"]
var current_color: String = "红"

func _ready():
	"""初始化编辑器"""
	print("地图编辑器初始化")
	load_scenes()
	init_grid()
	
	# 连接输入信号
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	
	print("地图编辑器准备就绪")
	print("快捷键: W-放置模式, Q-选择模式, E-删除模式")
	print("数字键1-7选择元素类型, R/G/B选择颜色")
	print("Ctrl+S保存, Ctrl+L加载, Ctrl+C清空")

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
		teleporter_in_scene = load("res://scenes/elements/teleporter/teleporter_in.tscn")
	if not teleporter_out_scene:
		teleporter_out_scene = load("res://scenes/elements/teleporter/teleporter_out.tscn")
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

func _input(event):
	"""处理输入"""
	# 切换编辑模式
	if event.is_action_pressed("editor_select_mode"):
		current_edit_mode = EditMode.SELECT
		print("切换到选择模式")
	
	elif event.is_action_pressed("editor_place_mode"):
		current_edit_mode = EditMode.PLACE
		print("切换到放置模式")
	
	elif event.is_action_pressed("editor_delete_mode"):
		current_edit_mode = EditMode.DELETE
		print("切换到删除模式")
	
	# 切换元素类型
	elif event.is_action_pressed("element_wall"):
		current_element_type = "wall"
		current_element_name = "brick"
		print("选择元素: 墙")
	
	elif event.is_action_pressed("element_ground"):
		current_element_type = "ground"
		current_element_name = ""
		print("选择元素: 地面")
	
	elif event.is_action_pressed("element_switch"):
		current_element_type = "switch"
		current_element_name = ""
		print("选择元素: 开关")
	
	elif event.is_action_pressed("element_door"):
		current_element_type = "door"
		current_element_name = ""
		print("选择元素: 门")
	
	elif event.is_action_pressed("element_fire"):
		current_element_type = "fire"
		current_element_name = ""
		print("选择元素: 火焰陷阱")
	
	elif event.is_action_pressed("element_player"):
		current_element_type = "player"
		current_element_name = ""
		print("选择元素: 玩家")
	
	elif event.is_action_pressed("element_goal"):
		current_element_type = "goal"
		current_element_name = ""
		print("选择元素: 终点")
	
	# 切换颜色
	elif event.is_action_pressed("color_red"):
		current_color = "红"
		print("选择颜色: 红")
	
	elif event.is_action_pressed("color_green"):
		current_color = "绿"
		print("选择颜色: 绿")
	
	elif event.is_action_pressed("color_blue"):
		current_color = "蓝"
		print("选择颜色: 蓝")
	
	# 保存/加载
	elif event.is_action_pressed("editor_save"):
		save_level("user://custom_level.json")
	
	elif event.is_action_pressed("editor_load"):
		load_level("user://custom_level.json")
	
	elif event.is_action_pressed("editor_clear"):
		clear_level()
	
	# 鼠标输入
	elif event is InputEventMouseButton:
		handle_mouse_input(event)
	
	# 鼠标移动
	elif event is InputEventMouseMotion and is_dragging:
		handle_mouse_drag(event)

func handle_mouse_input(event: InputEventMouseButton):
	"""处理鼠标输入"""
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 左键按下
		if current_edit_mode == EditMode.PLACE:
			# 放置模式
			place_element_at(grid_pos)
		
		elif current_edit_mode == EditMode.SELECT:
			# 选择模式
			select_element_at(grid_pos)
		
		elif current_edit_mode == EditMode.DELETE:
			# 删除模式
			delete_element_at(grid_pos)
	
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# 左键释放
		if is_dragging and current_dragging_element:
			end_drag()
			is_dragging = false
			current_dragging_element = null
	
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# 右键点击
		if current_edit_mode == EditMode.DELETE:
			delete_element_at(grid_pos)

func handle_mouse_drag(event: InputEventMouseMotion):
	"""处理鼠标拖拽"""
	if current_dragging_element:
		var mouse_pos = get_global_mouse_position()
		
		if Input.is_key_pressed(KEY_SHIFT):
			# Shift键：对齐到网格
			var grid_pos = world_to_grid(mouse_pos - drag_offset)
			if is_valid_grid_position(grid_pos):
				current_dragging_element.position = grid_pos * grid_size
		elif Input.is_key_pressed(KEY_CTRL):
			# Ctrl键：自由移动
			current_dragging_element.position = mouse_pos - drag_offset
		else:
			# 默认：自由移动
			current_dragging_element.position = mouse_pos - drag_offset

func place_element_at(grid_pos: Vector2):
	"""在网格位置放置元素"""
	if not is_valid_grid_position(grid_pos):
		return
	
	# 检查位置是否已被占用
	if grid[grid_pos.x][grid_pos.y] != null:
		print("位置已被占用")
		return
	
	# 创建元素
	var element = create_element(current_element_type, current_element_name, grid_pos)
	if element:
		# 添加到网格
		grid[grid_pos.x][grid_pos.y] = element
		
		print("在 %s 放置 %s" % [grid_pos, current_element_type])

func create_element(element_type: String, element_name: String, grid_pos: Vector2) -> Node2D:
	"""创建元素实例"""
	var position = grid_pos * grid_size
	var element: Node2D = null
	
	match element_type:
		"wall":
			element = wall_scene.instantiate() as RectElement
			if element:
				element.grid_width = 1
				element.grid_height = 1
		
		"ground":
			element = ground_scene.instantiate() as RectElement
			if element:
				element.grid_width = 1
				element.grid_height = 1
		
		"fire":
			element = fire_scene.instantiate()
		
		"switch":
			element = switch_scene.instantiate() as Switch
			if element:
				element.door_color = current_color
		
		"door":
			element = door_scene.instantiate() as Door
			if element:
				element.door_color = current_color
		
		"teleporter_in":
			element = teleporter_in_scene.instantiate()
		
		"teleporter_out":
			element = teleporter_out_scene.instantiate()
		
		"bow":
			element = bow_scene.instantiate()
		
		"dirt":
			element = dirt_scene.instantiate()
		
		"player":
			element = player_scene.instantiate()
			player_start_position = position
			print("设置玩家起始位置: %s" % position)
		
		"goal":
			element = goal_scene.instantiate()
		
		_:
			print("未知元素类型: %s" % element_type)
			return null
	
	if element:
		element.position = position
		add_child(element)
		elements.append(element)
		
		# 记录到关卡数据
		var key = "%d,%d" % [grid_pos.x, grid_pos.y]
		level_data[key] = {
			"type": element_type,
			"name": element_name,
			"position": {"x": position.x, "y": position.y},
			"properties": {"color": current_color}
		}
		
		# 如果是玩家，保存起始位置
		if element_type == "player":
			level_data["player_start"] = {"x": position.x, "y": position.y}
		
		return element
	
	return null

func select_element_at(grid_pos: Vector2):
	"""选择网格位置的元素"""
	if not is_valid_grid_position(grid_pos):
		return
	
	var element = grid[grid_pos.x][grid_pos.y]
	if element:
		selected_element = element
		print("选中元素: %s 在 %s" % [element.name, grid_pos])
		
		# 如果是可拖拽的，开始拖拽
		if element_has_drag_property(element):
			current_dragging_element = element
			drag_start_grid_pos = grid_pos
			drag_offset = mouse_offset_from_center(element)
			is_dragging = true
			print("开始拖拽元素")
		
		# 显示元素属性
		show_element_properties(element)
	else:
		selected_element = null
		print("没有选中元素")

func end_drag():
	"""结束拖拽"""
	if not current_dragging_element or not is_dragging:
		return
	
	# 获取新的网格位置
	var new_grid_pos = world_to_grid(current_dragging_element.position)
	
	if is_valid_grid_position(new_grid_pos):
		# 检查新位置是否为空
		if grid[new_grid_pos.x][new_grid_pos.y] == null or grid[new_grid_pos.x][new_grid_pos.y] == current_dragging_element:
			# 从旧位置移除
			if is_valid_grid_position(drag_start_grid_pos) and grid[drag_start_grid_pos.x][drag_start_grid_pos.y] == current_dragging_element:
				grid[drag_start_grid_pos.x][drag_start_grid_pos.y] = null
			
			# 添加到新位置
			grid[new_grid_pos.x][new_grid_pos.y] = current_dragging_element
			
			# 对齐到网格
			if Input.is_key_pressed(KEY_SHIFT):
				snap_to_grid(current_dragging_element)
			
			# 更新关卡数据
			var old_key = "%d,%d" % [drag_start_grid_pos.x, drag_start_grid_pos.y]
			var new_key = "%d,%d" % [new_grid_pos.x, new_grid_pos.y]
			
			if level_data.has(old_key):
				var data = level_data[old_key]
				level_data.erase(old_key)
				data.position = {"x": current_dragging_element.position.x, "y": current_dragging_element.position.y}
				level_data[new_key] = data
			
			print("元素移动到 %s" % new_grid_pos)
		else:
			# 新位置被占用，返回原位置
			current_dragging_element.position = drag_start_grid_pos * grid_size
			print("新位置已被占用，返回原位置")
	else:
		# 位置无效，返回原位置
		current_dragging_element.position = drag_start_grid_pos * grid_size
		print("位置无效，返回原位置")

func delete_element_at(grid_pos: Vector2):
	"""删除网格位置的元素"""
	if not is_valid_grid_position(grid_pos):
		return
	
	var element = grid[grid_pos.x][grid_pos.y]
	if element:
		# 从场景中移除
		if is_instance_valid(element):
			element.queue_free()
		
		# 从数组中移除
		var index = elements.find(element)
		if index != -1:
			elements.remove_at(index)
		
		# 从网格中移除
		grid[grid_pos.x][grid_pos.y] = null
		
		# 从关卡数据中移除
		var key = "%d,%d" % [grid_pos.x, grid_pos.y]
		if level_data.has(key):
			level_data.erase(key)
		
		# 如果删除的是玩家起始位置
		if element.name.contains("Player") or element is CharacterBody2D:
			player_start_position = Vector2(64, 384)
			if level_data.has("player_start"):
				level_data.erase("player_start")
		
		print("删除元素在 %s" % grid_pos)
		
		# 如果删除的是选中的元素，清空选择
		if selected_element == element:
			selected_element = null

func clear_level():
	"""清空关卡"""
	print("清空关卡...")
	
	# 删除所有元素
	for element in elements:
		if is_instance_valid(element):
			element.queue_free()
	
	elements.clear()
	level_data.clear()
	
	# 清空网格
	init_grid()
	
	# 重置玩家位置
	player_start_position = Vector2(64, 384)
	
	print("关卡已清空")

func world_to_grid(world_pos: Vector2) -> Vector2:
	"""世界坐标转网格坐标"""
	return Vector2(
		floor(world_pos.x / grid_size),
		floor(world_pos.y / grid_size)
	)

func grid_to_world(grid_pos: Vector2) -> Vector2:
	"""网格坐标转世界坐标"""
	return Vector2(
		grid_pos.x * grid_size + grid_size / 2,
		grid_pos.y * grid_size + grid_size / 2
	)

func is_valid_grid_position(grid_pos: Vector2) -> bool:
	"""检查网格位置是否有效"""
	return (
		grid_pos.x >= 0 and 
		grid_pos.x < level_width and 
		grid_pos.y >= 0 and 
		grid_pos.y < level_height
	)

func element_has_drag_property(element: Node2D) -> bool:
	"""检查元素是否可拖拽"""
	# 大部分元素都可拖拽
	return true

func mouse_offset_from_center(element: Node2D) -> Vector2:
	"""计算鼠标位置相对于元素中心的偏移"""
	var mouse_pos = get_global_mouse_position()
	return mouse_pos - element.position

func snap_to_grid(element: Node2D):
	"""对齐到网格"""
	var grid_pos = world_to_grid(element.position)
	element.position = grid_pos * grid_size

func show_element_properties(element: Node2D):
	"""显示元素属性"""
	if not element:
		return
	
	var properties = {}
	
	if element is RectElement:
		properties["width"] = element.grid_width
		properties["height"] = element.grid_height
		if element.has_property("text"):
			properties["text"] = element.text
		if element.has_property("has_collision"):
			properties["has_collision"] = element.has_collision
	
	elif element is Mechanism:
		if element.has_property("mechanism_type"):
			properties["type"] = element.mechanism_type
		if element.has_property("mechanism_color"):
			properties["color"] = element.mechanism_color
		if element.has_property("text"):
			properties["text"] = element.text
		if element.has_property("is_active"):
			properties["is_active"] = element.is_active
	
	elif element is Switch:
		if element.has_property("door_color"):
			properties["door_color"] = element.door_color
	
	elif element is Door:
		if element.has_property("door_color"):
			properties["door_color"] = element.door_color
		if element.has_property("current_state"):
			properties["state"] = element.current_state
	
	elif element is FireTrap:
		if element.has_property("damage"):
			properties["damage"] = element.damage
	
	elif element is Goal:
		if element.has_property("level_to_load"):
			properties["level_to_load"] = element.level_to_load
	
	print("元素属性: ", properties)

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

func load_level(path: String):
	"""加载关卡"""
	print("加载关卡: %s" % path)
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_data = JSON.parse_string(json_text)
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
			for element_data in json_data.get("elements", []):
				create_element_from_data(element_data)
			
			print("关卡加载完成，共 %d 个元素" % elements.size())
			return true
	
	print("加载关卡失败")
	return false

func get_element_data(element: Node2D) -> Dictionary:
	"""获取元素数据"""
	var data = {
		"type": "unknown",
		"position": {"x": element.position.x, "y": element.position.y}
	}
	
	if element is RectElement:
		data["type"] = "rect"
		if element.has_property("element_type"):
			data["element_type"] = element.element_type
		if element.has_property("grid_width"):
			data["width"] = element.grid_width
		if element.has_property("grid_height"):
			data["height"] = element.grid_height
		if element.has_property("text"):
			data["text"] = element.text
	
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
	
	elif element is Node2D and "Teleporter" in element.name:
		if "In" in element.name:
			data["type"] = "teleporter_in"
		else:
			data["type"] = "teleporter_out"
	
	elif element is Node2D and "Player" in element.name:
		data["type"] = "player"
	
	else:
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
	
	return data

func create_element_from_data(data: Dictionary):
	"""从数据创建元素"""
	var position = Vector2(data["position"]["x"], data["position"]["y"])
	var element = null
	var element_type = data.get("type", "unknown")
	
	match element_type:
		"wall", "rect":
			element = wall_scene.instantiate() as RectElement
			if element:
				element.grid_width = data.get("width", 1)
				element.grid_height = data.get("height", 1)
				element.position = position
				if "element_type" in data:
					element.element_type = data["element_type"]
		
		"ground":
			element = ground_scene.instantiate() as RectElement
			if element:
				element.grid_width = data.get("width", 1)
				element.grid_height = data.get("height", 1)
				element.position = position
		
		"fire":
			element = fire_scene.instantiate() as FireTrap
			if element and "damage" in data:
				element.damage = data["damage"]
		
		"goal":
			element = goal_scene.instantiate() as Goal
			if element and "level_to_load" in data:
				element.level_to_load = data["level_to_load"]
		
		"switch":
			element = switch_scene.instantiate() as Switch
			if element and "door_color" in data:
				element.door_color = data["door_color"]
		
		"door":
			element = door_scene.instantiate() as Door
			if element and "door_color" in data:
				element.door_color = data["door_color"]
				if "state" in data:
					element.current_state = data["state"]
		
		"teleporter_in":
			element = teleporter_in_scene.instantiate()
			if element and element.has_method("set_color") and "color" in data:
				element.set_color(data["color"])
		
		"teleporter_out":
			element = teleporter_out_scene.instantiate()
			if element and element.has_method("set_color") and "color" in data:
				element.set_color(data["color"])
		
		"player":
			element = player_scene.instantiate()
			player_start_position = position
		
		_:
			print("未知元素类型: %s" % element_type)
	
	if element:
		# 添加到场景
		add_child(element)
		elements.append(element)
		
		# 添加到网格
		var grid_pos = world_to_grid(position)
		if is_valid_grid_position(grid_pos):
			grid[grid_pos.x][grid_pos.y] = element
		
		# 设置属性
		if "color" in data and element.has_method("set_color"):
			element.call("set_color", data["color"])
		elif "color" in data and element.has_property("mechanism_color"):
			element.mechanism_color = data["color"]
		
		if "text" in data and element.has_property("text"):
			element.text = data["text"]
		
		return element
	
	return null

func _on_gui_focus_changed(control: Control):
	"""GUI焦点变化时处理"""
	if control and control.get_parent() and control.get_parent().name == "PropertyPanel":
		# 如果焦点在属性面板，暂停拖拽
		is_dragging = false
		current_dragging_element = null

func _draw():
	"""绘制网格和当前元素预览"""
	# 绘制网格背景
	var grid_color = Color(0.2, 0.2, 0.2, 0.1)
	for x in range(level_width):
		for y in range(level_height):
			var rect = Rect2(x * grid_size, y * grid_size, grid_size, grid_size)
			draw_rect(rect, grid_color, true)
			draw_rect(rect, Color(0.5, 0.5, 0.5, 0.2), false)
	
	# 绘制当前元素预览
	if current_edit_mode == EditMode.PLACE and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		
		if is_valid_grid_position(grid_pos):
			var preview_color = Color(0, 1, 0, 0.3)
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
	
	# 绘制玩家起始位置
	if player_start_position:
		draw_circle(player_start_position, 8, Color(0, 1, 0, 0.5))
		draw_string(
			ThemeDB.fallback_font,
			player_start_position + Vector2(-10, -20),
			"玩家",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12
		)
	
	# 绘制已选中元素边框
	if selected_element and selected_element != current_dragging_element:
		var bounds = get_element_bounds(selected_element)
		draw_rect(bounds, Color(0, 1, 0, 0.5), false, 2.0)
	
	# 绘制拖拽中的元素边框
	if current_dragging_element:
		var bounds = get_element_bounds(current_dragging_element)
		draw_rect(bounds, Color(1, 0, 0, 0.5), false, 2.0)

func get_element_bounds(element: Node2D) -> Rect2:
	"""获取元素边界框"""
	if element is RectElement:
		return Rect2(
			element.position.x - (element.grid_width * grid_size) / 2,
			element.position.y - (element.grid_height * grid_size) / 2,
			element.grid_width * grid_size,
			element.grid_height * grid_size
		)
	else:
		# 默认大小
		return Rect2(
			element.position.x - grid_size / 2,
			element.position.y - grid_size / 2,
			grid_size,
			grid_size
		)

# 设置输入映射
func setup_input_map():
	"""设置输入映射"""
	# 编辑模式
	InputMap.add_action("editor_select_mode")
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	InputMap.action_add_event("editor_select_mode", event)
	
	InputMap.add_action("editor_place_mode")
	event = InputEventKey.new()
	event.keycode = KEY_W
	InputMap.action_add_event("editor_place_mode", event)
	
	InputMap.add_action("editor_delete_mode")
	event = InputEventKey.new()
	event.keycode = KEY_E
	InputMap.action_add_event("editor_delete_mode", event)
	
	# 元素选择
	InputMap.add_action("element_wall")
	event = InputEventKey.new()
	event.keycode = KEY_1
	InputMap.action_add_event("element_wall", event)
	
	InputMap.add_action("element_ground")
	event = InputEventKey.new()
	event.keycode = KEY_2
	InputMap.action_add_event("element_ground", event)
	
	InputMap.add_action("element_switch")
	event = InputEventKey.new()
	event.keycode = KEY_3
	InputMap.action_add_event("element_switch", event)
	
	InputMap.add_action("element_door")
	event = InputEventKey.new()
	event.keycode = KEY_4
	InputMap.action_add_event("element_door", event)
	
	InputMap.add_action("element_fire")
	event = InputEventKey.new()
	event.keycode = KEY_5
	InputMap.action_add_event("element_fire", event)
	
	InputMap.add_action("element_player")
	event = InputEventKey.new()
	event.keycode = KEY_6
	InputMap.action_add_event("element_player", event)
	
	InputMap.add_action("element_goal")
	event = InputEventKey.new()
	event.keycode = KEY_7
	InputMap.action_add_event("element_goal", event)
	
	# 颜色选择
	InputMap.add_action("color_red")
	event = InputEventKey.new()
	event.keycode = KEY_R
	InputMap.action_add_event("color_red", event)
	
	InputMap.add_action("color_green")
	event = InputEventKey.new()
	event.keycode = KEY_G
	InputMap.action_add_event("color_green", event)
	
	InputMap.add_action("color_blue")
	event = InputEventKey.new()
	event.keycode = KEY_B
	InputMap.action_add_event("color_blue", event)
	
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
		# 节点进入场景树时设置输入映射
		setup_input_map()
	elif what == NOTIFICATION_EXIT_TREE:
		# 节点离开场景树时清理
		pass
