extends Node2D
class_name LevelEditor

# 导出变量
@export var level_width: int = 20
@export var level_height: int = 15
@export var grid_size: int = 32
var ui_node: Node = null
# 在类变量定义部分添加摄像机控制变量
var camera: Camera2D
var is_camera_dragging: bool = false
var camera_drag_start: Vector2
var camera_original_position: Vector2
var camera_zoom: float = 1.0
var test_switch_door_connections = {}  # 测试模式下的开关-门连接
var test_teleporter_connections = {}  # 测试模式下的传送门连接
var mouse_over_ui: bool = false

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
# 在场景引用部分添加
@export var student_scene: PackedScene



var is_left_dragging: bool = false
var is_right_dragging: bool = false
# 在类变量定义部分添加
var drag_original_grid_pos: Vector2
# 在类变量定义部分添加UI引用
var ui_scene: PackedScene = preload("res://scripts/managers/level_editor_ui.tscn")
var ui_instance: CanvasLayer = null


# 颜色定义
var color_names: Array = ["红", "橙", "黄", "绿", "青", "蓝", "紫", "白", "灰", "黑"]
var color_values: Array = [
	Color(1, 0, 0),       # 红
	Color(1, 0.5, 0),     # 橙
	Color(1, 1, 0),       # 黄
	Color(0, 1, 0),       # 绿
	Color(0, 1, 1),       # 青
	Color(0, 0, 1),       # 蓝
	Color(0.5, 0, 1),     # 紫
	Color(1, 1, 1),       # 白
	Color(0.5, 0.5, 0.5), # 灰
	Color(0, 0, 0)        # 黑
]
var current_color: String = "红"
var current_color_index: int = 0
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
# 元素类型列表 - 添加student
var element_types: Array = ["wall", "ground", "switch", "door", "fire", "player", "goal", "teleporter_in", "teleporter_out", "bow", "dirt", "student"]
var current_element_index: int = 0

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
	create_editor_ui() 
	# 设置输入映射
	setup_input_map()
	setup_camera()
	# 确保能接收输入
	set_process_input(true)
	set_process(true)
	
	# 创建默认的空白地图
	create_default_map()




func setup_camera():
	"""设置摄像机"""
	# 尝试获取场景中的摄像机
	camera = get_viewport().get_camera_2d()
	
	if camera:
		print("使用场景中的摄像机: ", camera.name)
	else:
		# 如果场景中没有摄像机，创建一个
		print("未找到场景摄像机，创建编辑器摄像机")
		create_editor_camera()
	
	# 设置摄像机初始位置
	if camera:
		# 将摄像机移动到地图中心
		camera.position = Vector2(
			(level_width * grid_size) / 2,
			(level_height * grid_size) / 2
		)
		camera.zoom = Vector2(camera_zoom, camera_zoom)
		print("摄像机位置: %s, 缩放: %s" % [camera.position, camera.zoom])

func create_editor_camera():
	"""创建编辑器摄像机"""
	camera = Camera2D.new()
	camera.name = "EditorCamera"
	camera.make_current()
	add_child(camera)
	print("创建了编辑器摄像机")

func create_default_map():
	"""创建默认的空白地图"""
	print("创建默认空白地图...")
	
	# 创建地图边界
	#create_map_bounds()
	
	# 在中心创建玩家起始点
	var center_x = int(level_width / 2)
	var center_y = int(level_height / 2)
	
	# 确保玩家起始位置有效
	if is_valid_grid_position(Vector2(center_x, center_y)):
		player_start_position = grid_to_world(Vector2(center_x, center_y))
		print("玩家起始位置设置到: %s" % player_start_position)
	
	# 更新显示
	queue_redraw()

func validate_level_size(rows: int, cols: int) -> bool:
	"""验证地图大小是否有效"""
	if rows <= 0 or cols <= 0:
		print("错误: 行数和列数必须大于0")
		return false
	
	if rows > 200 or cols > 200:
		print("警告: 地图大小过大，可能会影响性能")
		print("建议: 行数和列数不要超过200")
	
	return true

func create_editor_ui():
	"""创建编辑器UI"""
	if ui_scene:
		ui_instance = ui_scene.instantiate() as CanvasLayer
		if ui_instance:
			add_child(ui_instance)
			connect_ui_signals()
func connect_ui_signals():
	"""连接UI信号"""
	if not ui_instance:
		return
	ui_instance.save_pressed.connect(_on_ui_save_pressed)
	ui_instance.load_pressed.connect(_on_ui_load_pressed)
	ui_instance.clear_pressed.connect(_on_ui_clear_pressed)
	ui_instance.test_mode_toggled.connect(_on_ui_test_mode_toggled)
	ui_instance.zoom_in_pressed.connect(_on_ui_zoom_in_pressed)
	ui_instance.zoom_out_pressed.connect(_on_ui_zoom_out_pressed)
	ui_instance.element_selected.connect(_on_ui_element_selected)
	ui_instance.color_selected.connect(_on_ui_color_selected)
	if ui_instance.has_signal("level_size_changed"):
		ui_instance.level_size_changed.connect(_on_ui_level_size_changed)
	if ui_instance.has_signal("reload_map_size_pressed"):
		ui_instance.reload_map_size_pressed.connect(_on_ui_reload_map_size_pressed)
		# 添加学生场景
	if not student_scene:
		student_scene = load("res://scenes/elements/student.tscn")
	# 使用ui_instance进行初始同步
	if ui_instance:
		print("UI实例已创建")
		
		# 初始同步
		ui_instance.set_current_element(current_element_type)
		ui_instance.set_current_color(current_color_index)
	else:
		print("警告: UI实例未创建")

func get_student_elements_in_level():
	"""获取关卡中的所有学生元素"""
	var students = []
	for element in elements:
		if element and element.name.begins_with("Student_"):
			students.append(element)
	return students

func get_player_elements_in_level():
	"""获取关卡中的所有玩家元素"""
	var players = []
	for element in elements:
		if element and (element.name == "Player" or element.name.begins_with("Player_")):
			players.append(element)
	return players

func create_test_student():
	"""创建测试学生角色"""
	if student_scene:
		var student = student_scene.instantiate() as CharacterBody2D
		if student:
			# 创建测试相机
			test_camera = Camera2D.new()
			test_camera.name = "TestCamera"
			test_camera.make_current()
			student.add_child(test_camera)
			return student
	return null

# 新的UI信号处理函数
func _on_ui_level_size_changed(rows: int, cols: int):
	"""地图大小变化处理"""
	# 更新当前地图尺寸
	update_level_size(rows, cols)

func _on_ui_reload_map_size_pressed():
	"""重载地图大小按钮按下处理"""
	# 重新加载地图大小
	reload_level_size()
func update_level_size(new_rows: int, new_cols: int):
	"""更新地图大小（不立即应用）"""
	# 验证输入
	if new_rows <= 0 or new_cols <= 0:
		print("错误: 行数和列数必须大于0")
		return
	
	# 存储新的尺寸
	level_height = new_rows
	level_width = new_cols
	
	# 立即重新初始化网格
	reinit_grid_for_new_size()
	
	print("地图大小已更新为: %d行 × %d列" % [level_height, level_width])
	
	# 更新UI信息
	update_ui_info()

func reinit_grid_for_new_size():
	"""重新初始化网格以适应新大小"""
	print("重新初始化网格为: %d×%d" % [level_width, level_height])
	
	# 创建新的网格数组
	var new_grid = []
	
	# 初始化每一行
	for x in range(level_width):
		var row = []
		for y in range(level_height):
			row.append(null)
		new_grid.append(row)
	
	# 检查是否有现有元素需要保留
	var elements_to_keep = []
	
	if elements.size() > 0:
		print("尝试保留现有元素...")
		
		for element in elements:
			if is_instance_valid(element):
				var element_pos = element.position
				var grid_pos = world_to_grid(element_pos)
				
				# 检查元素是否在新地图范围内
				var element_in_range = (
					grid_pos.x >= 0 and 
					grid_pos.x < level_width and 
					grid_pos.y >= 0 and 
					grid_pos.y < level_height
				)
				
				if element_in_range:
					# 将元素位置转换为整数
					var int_grid_x = int(grid_pos.x)
					var int_grid_y = int(grid_pos.y)
					
					# 检查目标位置是否为空
					if int_grid_x >= 0 and int_grid_x < new_grid.size():
						if int_grid_y >= 0 and int_grid_y < new_grid[int_grid_x].size():
							if new_grid[int_grid_x][int_grid_y] == null:
								# 保留元素
								new_grid[int_grid_x][int_grid_y] = element
								elements_to_keep.append(element)
								print("保留元素: %s 在位置: %s" % [element.name, grid_pos])
							else:
								# 目标位置已被占用，删除元素
								print("目标位置已被占用，删除元素: %s" % element.name)
								element.queue_free()
						else:
							# 超出范围
							print("元素超出范围，删除: %s" % element.name)
							element.queue_free()
					else:
						# 超出范围
						print("元素超出范围，删除: %s" % element.name)
						element.queue_free()
				else:
					# 元素在新地图范围外，删除
					print("元素超出新地图范围，删除: %s" % element.name)
					element.queue_free()
			else:
				# 元素无效
				print("发现无效元素，跳过")
	
	# 更新元素列表
	elements = elements_to_keep
	
	# 更新网格引用
	grid = new_grid
	
	print("网格重新初始化完成，保留 %d 个元素" % elements.size())
	print("新网格大小: %d×%d" % [grid.size(), grid[0].size() if grid.size() > 0 else 0])
	
	
func reload_level_size():
	"""重新加载地图大小，清空现有地图并创建新的空白地图"""
	if level_height <= 0 or level_width <= 0:
		print("错误: 无效的地图尺寸: %d×%d" % [level_width, level_height])
		return
	var old_element_count = elements.size()
	var backup_player_start = player_start_position
	var player_grid_pos = world_to_grid(backup_player_start)
	var player_start_in_range = (
		player_grid_pos.x >= 0 and 
		player_grid_pos.x < level_width and 
		player_grid_pos.y >= 0 and 
		player_grid_pos.y < level_height
	)
	
	if not player_start_in_range:
		# 重置到新地图中心
		player_start_position = Vector2(
			(level_width * grid_size) / 2,
			(level_height * grid_size) / 2
		)
		print("玩家起始位置超出新地图范围，已重置到中心: %s" % player_start_position)
	clear_existing_elements()
	init_grid()
	#create_map_bounds()
	
	# 更新状态显示
	update_ui_info()
	
	# 重绘界面
	queue_redraw()
	
	print("地图重载完成，新尺寸: %d×%d" % [level_width, level_height])
	print("创建了新的空白地图")
func clear_existing_elements():
	"""清除所有现有元素"""
	print("开始清除现有元素...")
	
	# 统计清除的元素数量
	var cleared_count = 0
	
	# 首先，保存当前的网格大小
	var current_grid_width = grid.size() if grid else 0
	var current_grid_height = 0
	if current_grid_width > 0 and grid[0]:
		current_grid_height = grid[0].size()
	
	print("当前网格尺寸: %d×%d" % [current_grid_width, current_grid_height])
	
	# 删除所有元素
	for element in elements:
		if is_instance_valid(element):
			element.queue_free()
			cleared_count += 1
	
	# 清空元素列表
	elements.clear()
	
	# 清空网格（如果网格存在）
	if current_grid_width > 0 and current_grid_height > 0:
		for x in range(current_grid_width):
			# 确保行数组存在
			if x < grid.size() and grid[x] and grid[x].size() >= current_grid_height:
				for y in range(current_grid_height):
					grid[x][y] = null
		print("网格已清空")
	else:
		print("警告: 网格未初始化或尺寸为0")
	
	# 清空选择
	selected_element = null
	current_dragging_element = null
	is_dragging = false
	
	print("已清除 %d 个元素" % cleared_count)


func create_element_at_position(element_type: String, grid_pos: Vector2) -> bool:
	"""在指定位置创建元素（不检查是否被占用）"""
	if not is_valid_grid_position(grid_pos):
		print("错误: 无效的网格位置: %s" % grid_pos)
		return false
	
	var element = create_element(element_type, grid_pos)
	if element:
		# 添加到网格
		grid[grid_pos.x][grid_pos.y] = element
		return true
	
	return false
	
	
# UI信号处理函数
func _on_ui_save_pressed():
	save_level("user://custom_level.json")

func _on_ui_load_pressed():
	load_level("user://custom_level.json")

func _on_ui_clear_pressed():
	clear_level()

func _on_ui_test_mode_toggled(pressed: bool):
	if pressed != test_mode_active:
		toggle_test_mode()

func _on_ui_zoom_in_pressed():
	# TODO: 实现放大功能
	print("放大视图 (功能待实现)")

func _on_ui_zoom_out_pressed():
	# TODO: 实现缩小功能
	print("缩小视图 (功能待实现)")

func _on_ui_element_selected(element_type: String):
	select_element_type(element_type)
	# 更新UI状态
	if ui_instance:
		ui_instance.set_current_element(element_type)

func _on_ui_color_selected(color_index: int):
	set_color(color_index)
	# 更新UI状态
	if ui_instance:
		ui_instance.set_current_color(color_index)
		
	
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
	if not student_scene:
		student_scene = load("res://scenes/actors/player/student/student.tscn")


func init_grid():
	"""初始化网格"""
	grid = []
	for x in range(level_width):
		grid.append([])
		for y in range(level_height):
			grid[x].append(null)
	print("网格初始化完成: %d×%d" % [level_width, level_height])
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
	
	var element_name = element_types[current_element_index] if current_element_index < element_types.size() else "未知"
	var color_name = color_names[current_color_index] if current_color_index < color_names.size() else "未知"
	
	info_label.text = "%s | 元素: %s | 颜色: %s | 地图: %d×%d" % [
		action_text, 
		element_name, 
		color_name,
		level_width,
		level_height
	]
	
	# 更新UI状态标签
	#if ui_instance:
		#ui_instance.update_status("地图大小: %d×%d" % [level_width, level_height])

func update_status(message: String):
	"""更新状态信息"""
	print("状态: " + message)
	
	# 如果UI节点存在，尝试调用它的update_status函数
	if ui_node and ui_node.has_method("update_status"):
		ui_node.call("update_status", message)

func handle_camera_input(event: InputEvent):
	"""处理摄像机输入"""
	if not camera:
		return
	
	# 鼠标中键拖拽
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				# 中键按下：开始摄像机拖拽
				is_camera_dragging = true
				camera_drag_start = get_viewport().get_mouse_position()
				camera_original_position = camera.position
				print("开始摄像机拖拽")
			else:
				# 中键释放：结束摄像机拖拽
				is_camera_dragging = false
				print("结束摄像机拖拽")
		
		# 鼠标滚轮缩放 - 只在按下Ctrl时生效
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# 检查是否按下Ctrl键
			if Input.is_key_pressed(KEY_CTRL):
				# Ctrl + 滚轮上滚：放大
				camera_zoom = clamp(camera_zoom + 0.1, 0.5, 3.0)
				camera.zoom = Vector2(camera_zoom, camera_zoom)
				print("摄像机放大: %.1f" % camera_zoom)
			else:
				# 不按Ctrl时，返回false让事件继续传递
				return
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# 检查是否按下Ctrl键
			if Input.is_key_pressed(KEY_CTRL):
				# Ctrl + 滚轮下滚：缩小
				camera_zoom = clamp(camera_zoom - 0.1, 0.5, 3.0)
				camera.zoom = Vector2(camera_zoom, camera_zoom)
				print("摄像机缩小: %.1f" % camera_zoom)
			else:
				# 不按Ctrl时，返回false让事件继续传递
				return
	
	# 鼠标移动摄像机
	elif event is InputEventMouseMotion and is_camera_dragging:
		handle_camera_drag(event)
func handle_camera_drag(event: InputEventMouseMotion):
	"""处理摄像机拖拽"""
	if not is_camera_dragging or not camera:
		return
	
	# 获取当前鼠标位置
	var current_mouse_pos = get_viewport().get_mouse_position()
	
	# 计算拖拽距离
	var drag_delta = current_mouse_pos - camera_drag_start
	
	# 应用拖拽到摄像机位置（移动方向与鼠标移动方向相反）
	camera.position = camera_original_position - drag_delta
	
	# 强制重绘，更新网格显示
	queue_redraw()

func _input(event):
	"""处理输入（只处理键盘）"""
	# 先处理摄像机输入
	if not test_mode_active:
		handle_camera_input(event)
	
	# 鼠标按钮事件
	if event is InputEventMouseButton:
		
		
		mouse_over_ui = is_mouse_over_ui()
		if mouse_over_ui:
			return
		if event is InputEventMouseButton and mouse_over_ui:
			return
		if test_mode_active:
			# 测试模式下的鼠标事件
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				handle_test_attack()
		else:
			# 编辑器模式下的鼠标事件
			handle_editor_mouse(event)
		
		# 鼠标滚轮切换元素类型（如果未用于摄像机缩放）
		if event is InputEventMouseButton and event.pressed:
			if not Input.is_key_pressed(KEY_CTRL):
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
	
	# 颜色切换
	elif event.is_action_pressed("color_0"):
		set_color(0)
	elif event.is_action_pressed("color_1"):
		set_color(1)
	elif event.is_action_pressed("color_2"):
		set_color(2)
	elif event.is_action_pressed("color_3"):
		set_color(3)
	elif event.is_action_pressed("color_4"):
		set_color(4)
	elif event.is_action_pressed("color_5"):
		set_color(5)
	elif event.is_action_pressed("color_6"):
		set_color(6)
	elif event.is_action_pressed("color_7"):
		set_color(7)
	elif event.is_action_pressed("color_8"):
		set_color(8)
	elif event.is_action_pressed("color_9"):
		set_color(9)
	
	# 保存/加载
	elif event.is_action_pressed("editor_save"):
		save_level("user://custom_level.json")
	elif event.is_action_pressed("editor_load"):
		load_level("user://custom_level.json")
	elif event.is_action_pressed("editor_clear"):
		clear_level()


func set_color(color_index: int):
	"""设置当前颜色"""
	if color_index >= 0 and color_index < color_names.size():
		current_color_index = color_index
		current_color = color_names[current_color_index]
		print("切换到颜色: %s (索引: %d)" % [current_color, current_color_index])
		update_ui_info()
		queue_redraw()
		
		# 更新已选中元素的颜色（如果有的话）
		if selected_element:
			apply_color_to_element(selected_element, "")
			print("更新选中元素的颜色")
		
		# 更新UI
		if ui_instance:
			ui_instance.set_current_color(color_index)
	else:
		print("错误: 颜色索引 %d 超出范围" % color_index)
# 修改现有的select_element_type函数
func select_element_type(type_name: String):
	"""选择元素类型"""
	current_element_index = element_types.find(type_name)
	if current_element_index != -1:
		current_element_type = element_types[current_element_index]
		update_ui_info()
		print("选择元素: %s" % current_element_type)
		queue_redraw()
		
		# 更新UI
		if ui_instance:
			ui_instance.set_current_element(type_name)
			
			
func handle_mouse_wheel_up(event: InputEventMouseButton):
	"""处理鼠标滚轮上滚（切换元素类型）"""
	# 如果正在拖拽摄像机，不处理元素切换
	if is_camera_dragging:
		return
	cycle_element_type(1)

func handle_mouse_wheel_down(event: InputEventMouseButton):
	"""处理鼠标滚轮下滚（切换元素类型）"""
	# 如果正在拖拽摄像机，不处理元素切换
	if is_camera_dragging:
		return
	cycle_element_type(-1)

	
func cycle_element_type(direction: int):
	"""循环切换元素类型"""
	var element_types = [
		"wall", 
		"ground", 
		"switch", 
		"door", 
		"fire", 
		"player", 
		"student", 
		"goal", 
		"teleporter_in", 
		"teleporter_out", 
		"bow", 
		"dirt"
	]
	
	# 找到当前元素的索引
	var current_index = element_types.find(current_element_type)
	if current_index == -1:
		# 如果当前元素不在列表中，从第一个开始
		current_element_type = element_types[0]
		current_index = 0
	else:
		# 计算新的索引
		var new_index = current_index + direction
		
		# 循环处理
		if new_index < 0:
			new_index = element_types.size() - 1
		elif new_index >= element_types.size():
			new_index = 0
		
		current_element_type = element_types[new_index]
	
	print("切换到元素: %s" % current_element_type)
	
	# 更新 UI - 取消注释并确保调用
	if ui_instance:
		ui_instance.set_current_element(current_element_type)
	update_ui_info()
	queue_redraw()
	
	# 更新状态
	update_status("当前元素: %s" % current_element_type)

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

func create_element_from_data(data: Dictionary) -> Node2D:
	"""从数据创建元素"""
	var position = Vector2(data["position"]["x"], data["position"]["y"])
	var element = null
	var element_type = data.get("type", "unknown")
	
	match element_type:
		"fire":
			if fire_scene:
				element = fire_scene.instantiate() as Node2D
				if element and "damage" in element and "damage" in data:
					element.damage = data["damage"]
		
		"goal":
			if goal_scene:
				element = goal_scene.instantiate() as Node2D
				if element and "level_to_load" in element and "level_to_load" in data:
					element.level_to_load = data["level_to_load"]
		
		"student":
			if student_scene:
				element = student_scene.instantiate() as Node2D
		
		"switch":
			if switch_scene:
				element = switch_scene.instantiate() as Node2D
				if element:
					# 设置颜色
					if "color" in data and "color" in element:
						element.color = data["color"]
						print("  从数据设置开关的颜色: %s" % data["color"])
					
					# 应用颜色方案
					if element.has_method("apply_color_scheme") and "color" in element:
						element.apply_color_scheme(element.color)
						print("  调用apply_color_scheme: %s" % element.color)
					
					if "current_state" in element and "state" in data:
						element.current_state = data["state"]
		"door":
			if door_scene:
				element = door_scene.instantiate() as Node2D
				if element and "color" in element and "color" in data:
					element.color = data["color"]
					if "current_state" in element and "state" in data:
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
		
		"wall":
			if wall_scene:
				element = wall_scene.instantiate() as Node2D
		
		"ground":
			if ground_scene:
				element = ground_scene.instantiate() as Node2D
		
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
			# 传递颜色索引
			element.call("set_color", data["color"])
		elif "color" in data and "color" in element:
			# 设置Color值
			if data["color"] is int and data["color"] < color_values.size():
				element.color = color_values[data["color"]]
		elif "color" in data and "color" in element:
			# 设置door_color为颜色索引
			element.color = data["color"]
		elif "color" in data and "mechanism_color" in element:
			# 设置mechanism_color为颜色索引
			element.mechanism_color = data["color"]
		
		if "text" in data and "text" in element:
			element.text = data["text"]
		
		return element
	
	return null

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
	player_start_position = Vector2(
		(level_width * grid_size) / 2,
		(level_height * grid_size) / 2
	)
	
	# 清空level_data字典
	level_data.clear()
	
	# 清空选择
	selected_element = null
	current_dragging_element = null
	is_dragging = false
	
	# 刷新显示
	queue_redraw()
	
	print("关卡已清空，地图尺寸: %d×%d" % [level_width, level_height])
func fill_area(start: Vector2, end: Vector2):
	"""填充区域，如果位置有东西则替换"""
	print("开始填充区域: 从 %s 到 %s" % [start, end])
	
	# 计算区域边界
	var start_x = int(min(start.x, end.x))
	var end_x = int(max(start.x, end.x))
	var start_y = int(min(start.y, end.y))
	var end_y = int(max(start.y, end.y))
	
	print("区域范围: x[%d-%d], y[%d-%d]" % [start_x, end_x, start_y, end_y])
	
	var replaced_count = 0
	var created_count = 0
	
	# 遍历区域内的所有网格
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var grid_pos = Vector2(x, y)
			
			# 检查位置是否有效
			if is_valid_grid_position(grid_pos):
				# 检查位置是否已被占用
				if grid[x][y] != null:
					# 如果位置有元素，先删除它
					if delete_element_at(grid_pos):
						print("✓ 删除了位置 %s 的原有元素" % grid_pos)
						replaced_count += 1
				
				# 创建新元素
				var element = create_element(current_element_type, grid_pos)
				if element:
					# 添加到网格
					grid[x][y] = element
					created_count += 1
					print("✓ 在 %s 放置了 %s" % [grid_pos, current_element_type])
				else:
					print("✗ 在 %s 创建元素失败" % grid_pos)
			else:
				print("✗ 无效的网格位置: %s" % grid_pos)
	
	print("区域填充完成，共替换 %d 个元素，新增 %d 个元素" % [replaced_count, created_count])
	
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


func setup_switch_door_connections():
	"""在测试模式下自动连接同颜色的开关和门"""
	test_switch_door_connections.clear()
	
	# 收集所有开关和门
	var switches = []
	var doors = []
	
	for element in elements:
		if is_instance_valid(element):
			if element is Switch:
				switches.append(element)
			elif element is Door:
				doors.append(element)
	
	print("找到 %d 个开关和 %d 个门" % [switches.size(), doors.size()])
	
	# 按颜色分组
	var color_groups = {}
	
	for switch in switches:
		var switch_color = get_element_color(switch)
		if not switch_color in color_groups:
			color_groups[switch_color] = {"switches": [], "doors": []}
		color_groups[switch_color].switches.append(switch)
	
	for door in doors:
		var door_color = get_element_color(door)
		if not door_color in color_groups:
			color_groups[door_color] = {"switches": [], "doors": []}
		color_groups[door_color].doors.append(door)
	
	# 为每个颜色组的开关和门创建连接
	for color_name in color_groups.keys():
		var group = color_groups[color_name]
		if group.switches.size() > 0 and group.doors.size() > 0:
			print("颜色组 %s: %d 个开关 -> %d 个门" % [color_name, group.switches.size(), group.doors.size()])
			
			for switch in group.switches:
				for door in group.doors:
					# 建立双向连接
					if is_instance_valid(switch) and is_instance_valid(door):
						if switch.has_method("link_door"):
							switch.link_door(door)
						
						if door.has_method("link_switch"):
							door.link_switch(switch)
						
						# 记录连接
						if not test_switch_door_connections.has(switch):
							test_switch_door_connections[switch] = []
						test_switch_door_connections[switch].append(door)
						
						print("连接: %s[%s] -> %s[%s]" % [switch.name, get_element_color(switch), door.name, get_element_color(door)])

func get_element_color(element: Node2D) -> String:
	"""获取元素的颜色"""
	# 优先尝试 color 属性
	if "color" in element and element.color != "":
		return element.color
	
	# 尝试 mechanism_color
	if "mechanism_color" in element and element.mechanism_color != "":
		return element.mechanism_color
	
	# 默认返回空字符串
	return ""
	
func setup_teleporter_connections():
	"""建立传送门连接（输入到输出，同颜色）"""
	test_teleporter_connections.clear()
	
	# 收集所有传送门
	var teleporters_in = []
	var teleporters_out = []
	
	for element in elements:
		if is_instance_valid(element):
			var element_name = element.name.to_lower()
			
			# 检查是否是传送门输入
			if "teleporter" in element_name and "in" in element_name:
				teleporters_in.append(element)
				print("找到传送门输入: %s" % element.name)
			
			# 检查是否是传送门输出
			elif "teleporter" in element_name and "out" in element_name:
				teleporters_out.append(element)
				print("找到传送门输出: %s" % element.name)
	
	# 按颜色分组
	var teleporters_in_by_color = {}
	var teleporters_out_by_color = {}
	
	for tele_in in teleporters_in:
		var color = 0
		if tele_in.has_method("get_color"):
			color = tele_in.get_color()
		teleporters_in_by_color[color] = tele_in
		print("传送门输入 %s 颜色: %d" % [tele_in.name, color])
	
	for tele_out in teleporters_out:
		var color = 0
		if tele_out.has_method("get_color"):
			color = tele_out.get_color()
		teleporters_out_by_color[color] = tele_out
		print("传送门输出 %s 颜色: %d" % [tele_out.name, color])
	
	# 建立连接
	for color in teleporters_in_by_color:
		if teleporters_out_by_color.has(color):
			var tele_in = teleporters_in_by_color[color]
			var tele_out = teleporters_out_by_color[color]
			
			# 建立连接
			connect_teleporters(tele_in, tele_out)
			print("✓ 连接传送门: %s -> %s (颜色: %d)" % [tele_in.name, tele_out.name, color])
			
			# 记录连接
			test_teleporter_connections[tele_in] = tele_out
		else:
			print("⚠ 警告: 颜色 %d 有输入传送门但无对应的输出" % color)
	
	print("传送门连接完成: %d 对传送门已连接" % test_teleporter_connections.size())

func connect_switch_to_door(switch: Node2D, door: Node2D):
	"""连接开关到门"""
	# 清除开关之前的连接
	if switch.is_connected("activated", Callable(door, "open")):
		switch.disconnect("activated", Callable(door, "open"))
	if switch.is_connected("deactivated", Callable(door, "close")):
		switch.disconnect("deactivated", Callable(door, "close"))
	
	# 建立新连接
	if door.has_method("open") and door.has_method("close"):
		if switch.has_signal("activated"):
			switch.connect("activated", Callable(door, "open"))
		if switch.has_signal("deactivated"):
			switch.connect("deactivated", Callable(door, "close"))
		print("连接建立: %s -> %s" % [switch.name, door.name])
	else:
		print("警告: 门 %s 没有 open/close 方法" % door.name)

func connect_teleporters(tele_in: Node2D, tele_out: Node2D):
	"""连接传送门"""
	if tele_in.has_method("set_target") and tele_out.has_method("get_position"):
		tele_in.set_target(tele_out.get_position())
		print("传送门连接: %s 目标设置为 %s" % [tele_in.name, str(tele_out.get_position())])
	else:
		print("警告: 传送门没有相应的方法")



func cleanup_switch_door_connections():
	"""清理开关-门连接"""
	for switch in test_switch_door_connections:
		if is_instance_valid(switch):
			for door in test_switch_door_connections[switch]:
				if is_instance_valid(door):
					# 断开连接
					if switch.is_connected("activated", Callable(door, "open")):
						switch.disconnect("activated", Callable(door, "open"))
					if switch.is_connected("deactivated", Callable(door, "close")):
						switch.disconnect("deactivated", Callable(door, "close"))
	
	test_switch_door_connections.clear()
	print("开关-门连接已清理")

func cleanup_teleporter_connections():
	"""清理传送门连接"""
	for tele_in in test_teleporter_connections:
		if is_instance_valid(tele_in) and tele_in.has_method("clear_target"):
			tele_in.clear_target()
	
	test_teleporter_connections.clear()
	print("传送门连接已清理")

# 在测试模式下处理机关触发
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


func enter_test_mode():
	"""进入测试模式"""
	# 创建测试玩家
	#create_test_player()
	# 设置测试控制
	setup_test_controls_for_current_character()
	
		# 自动连接同颜色的开关和门
	setup_switch_door_connections()
	
	# 自动连接同颜色的传送门
	setup_teleporter_connections()
	
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
		# 断开所有连接
	cleanup_switch_door_connections()
	cleanup_teleporter_connections()
	# 恢复编辑器输入映射
	setup_input_map()
	
	print("退出测试模式")
	
	



	
func setup_test_controls_for_current_character():
	"""为当前角色设置测试控制"""
	if not test_player:
		return
	
	# 先清除所有测试控制
	InputMap.action_erase_events("test_move_left")
	InputMap.action_erase_events("test_move_right")
	InputMap.action_erase_events("test_jump")
	InputMap.action_erase_events("test_attack")
	
	# 基本移动控制（所有角色通用）
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
	
	# 如果是学生角色，添加学生特有的控制
	if test_player is Student:
		setup_student_specific_controls()

func setup_student_specific_controls():
	"""设置学生特有的控制"""
	print("设置学生特有控制")
	
	# 使用笔
	InputMap.add_action("student_use_pen")
	var event = InputEventKey.new()
	event.keycode = KEY_E
	InputMap.action_add_event("student_use_pen", event)
	
	# 扔鞋
	InputMap.add_action("student_throw_shoe")
	event = InputEventKey.new()
	event.keycode = KEY_Q
	InputMap.action_add_event("student_throw_shoe", event)
	
	# 切换肢体
	InputMap.add_action("student_switch_limb")
	event = InputEventKey.new()
	event.keycode = KEY_TAB
	event.shift_pressed = true
	InputMap.action_add_event("student_switch_limb", event)
	
	# 回收
	InputMap.add_action("student_recover")
	event = InputEventKey.new()
	event.keycode = KEY_R
	InputMap.action_add_event("student_recover", event)
	
	
func create_test_player():
	"""创建测试角色（支持玩家或学生）"""
	# 先检查是否有学生角色
	var student_elements = get_student_elements_in_level()
	if student_elements.size() > 0:
		# 使用第一个学生角色
		var student_element = student_elements[0]
		test_player = create_test_student()
		if test_player:
			test_player.position = student_element.position
			add_child(test_player)
			print("创建测试学生角色在位置: %s" % student_element.position)
			return
	
	# 如果没有学生，检查是否有玩家
	var player_elements = get_player_elements_in_level()
	if player_elements.size() > 0:
		# 使用第一个玩家角色
		var player_element = player_elements[0]
		if player_scene:
			test_player = player_scene.instantiate() as CharacterBody2D
			if test_player:
				test_player.position = player_element.position
				add_child(test_player)
				print("创建测试玩家在位置: %s" % player_element.position)
		return
	
	# 如果都没有，使用默认玩家起始位置
	if player_scene:
		test_player = player_scene.instantiate() as CharacterBody2D
		if test_player:
			test_player.position = player_start_position
			add_child(test_player)
			print("创建测试玩家在默认位置: %s" % player_start_position)
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
		if "color" in element:
			data["color"] = element.color
			print("  获取开关的color属性: %s" % element.color)
	elif element is Student:
		data["type"] = "student"
	elif element is Door:
		data["type"] = "door"
		if "color" in element:
			data["color"] = element.color
		if "current_state" in element:
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
	
func create_element(element_type: String, grid_pos: Vector2) -> Node2D:
	"""创建新元素"""
	var element = null
	# 确保位置是格子中心
	var world_pos = Vector2(
		grid_pos.x * grid_size + grid_size / 2,
		grid_pos.y * grid_size + grid_size / 2
	)
	
	print("创建元素: 类型=%s, 网格位置=%s, 世界位置=%s, 颜色=%s" % [element_type, grid_pos, world_pos, current_color])
	var color_name = color_names[current_color_index]
	match element_type:
		
		"student":
			if student_scene:
				element = student_scene.instantiate()
				if element:
					element.name = "Student_%d_%d" % [grid_pos.x, grid_pos.y]
			else:
				print("错误: 学生场景未加载")
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
		
		"teleporter_out":
			if teleporter_out_scene:
				element = teleporter_out_scene.instantiate()
				if element:
					element.name = "TeleporterOut_%d_%d" % [grid_pos.x, grid_pos.y]
		
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
		apply_color_to_element(element, element_type)
		apply_collision_to_element(element, element_type)
		print("元素创建成功: %s" % element.name)
		return element
	
	print("元素实例化失败")
	return null
func apply_color_to_element(element: Node2D, element_type: String):
	"""为元素应用颜色"""
	# 获取当前颜色
	var color_value = get_color_value(current_color_index)
	var color_name = color_names[current_color_index]  # 获取颜色名称
	
	print("为元素 %s 应用颜色: a%s (索引: %d)" % [element.name, current_color, current_color_index])
	
	# 根据不同元素类型和属性设置颜色
	if element_type == "door":
		# 先设置 color 属性
		if "color" in element:
			element.color = color_name
			print("  门: 设置color属性(字符串): %s" % color_name)
		
		# 然后设置 mechanism_color
		if "mechanism_color" in element:
			element.mechanism_color = color_name
			print("  门: 设置mechanism_color属性: %s" % color_name)
		
		# 调用 apply_color_scheme
		if element.has_method("apply_color_scheme"):
			element.apply_color_scheme(color_name)
			print("  门: 调用apply_color_scheme: %s" % color_name)
		
		# 更新门的颜色显示
		if element.has_method("update_door_color"):
			element.update_door_color()
			print("  门: 调用update_door_color")
	# 处理开关元素
	elif element_type == "switch":
		# 先设置 color 属性
		if "color" in element:
			element.color = color_name
			print("  开关: 设置color属性(字符串): %s" % color_name)
		
		# 然后设置 mechanism_color
		if "mechanism_color" in element:
			element.mechanism_color = color_name
			print("  开关: 设置mechanism_color属性: %s" % color_name)
		
		# 调用 apply_color_scheme
		if element.has_method("apply_color_scheme"):
			element.apply_color_scheme(color_name)
			print("  开关: 调用apply_color_scheme: %s" % color_name)
		
		# 更新开关的颜色显示
		if element.has_method("update_label_color"):
			element.update_label_color()
			print("  开关: 调用update_label_color")
			
			
	elif element.has_method("set_color"):
		# 如果元素有set_color方法，传递颜色索引
		element.set_color(current_color_index)
		print("  使用set_color方法设置颜色索引: %d" % current_color_index)
	
	elif "modulate" in element:
		# 如果元素有modulate属性，直接设置Color值
		element.modulate = color_value
		print("  设置modulate属性: %s" % str(color_value))
	

	elif "door_color" in element:
		# 如果元素有door_color属性，设置颜色索引
		element.door_color = current_color_index
		print("  设置door_color属性: %d" % current_color_index)
	
	elif "mechanism_color" in element:
		# 如果元素有mechanism_color属性，设置颜色索引
		element.mechanism_color = current_color_index
		print("  设置mechanism_color属性: %d" % current_color_index)
	
	else:
		# 尝试查找子节点中的Sprite2D
		var sprite = find_sprite_in_element(element)
		if sprite:
			sprite.modulate = color_value
			print("  为子Sprite设置modulate: %s" % str(color_value))
		else:
			print("  警告: 无法为元素设置颜色，无合适的颜色属性")
			
			
			
			
func get_color_value(color_index: int) -> Color:
	"""获取颜色索引对应的Color值"""
	if color_index >= 0 and color_index < color_values.size():
		return color_values[color_index]
	return Color.WHITE  # 默认白色

func find_sprite_in_element(element: Node2D) -> Node2D:
	"""在元素中查找Sprite2D节点"""
	# 检查常见名称
	var sprite_names = ["Sprite2D", "Sprite", "sprite"]
	for name in sprite_names:
		if element.has_node(name):
			return element.get_node(name)
	
	# 递归查找
	for child in element.get_children():
		if child is Sprite2D:
			return child
	
	return null
func world_to_grid(pos: Vector2) -> Vector2:
	"""将世界坐标转换为网格坐标"""
	# 注意：这里的世界坐标是相对于编辑器节点（LevelEditor）的
	# 计算相对于编辑器本地的坐标
	var local_pos = to_local(pos)
	
	# 计算网格坐标
	var grid_x = floor(local_pos.x / grid_size)
	var grid_y = floor(local_pos.y / grid_size)
	
	return Vector2(grid_x, grid_y)

func grid_to_world(pos: Vector2) -> Vector2:
	"""将网格坐标转换为世界坐标"""
	# 计算世界位置（相对于编辑器节点）
	var world_pos = Vector2(
		pos.x * grid_size + grid_size / 2,
		pos.y * grid_size + grid_size / 2
	)
	
	return world_pos
	
	
func is_valid_grid_position(pos: Vector2) -> bool:
	"""检查网格位置是否有效"""
	return pos.x >= 0 and pos.x < level_width and pos.y >= 0 and pos.y < level_height
func place_element_at(grid_pos: Vector2) -> void:
	"""在指定网格位置放置元素"""
	print("尝试在网格位置 %s 放置元素" % grid_pos)
	
	# 将浮点数坐标转换为整数
	var int_grid_x = int(grid_pos.x)
	var int_grid_y = int(grid_pos.y)
	var int_grid_pos = Vector2(int_grid_x, int_grid_y)
	
	if not is_valid_grid_position(int_grid_pos):
		print("错误: 无效的网格位置: ", int_grid_pos)
		return
	
	# 检查位置是否已被占用
	if grid[int_grid_x][int_grid_y] != null:
		var element = grid[int_grid_x][int_grid_y]
		print("位置已被占用，元素: %s" % element.name)
		return
	
	# 特殊处理：玩家和学生只能有一个
	if current_element_type == "player" or current_element_type == "student":
		# 删除现有的玩家或学生
		for element in elements:
			if element and (element.name == "Player" or element.name.begins_with("Student_")):
				element.queue_free()
				elements.erase(element)
				break
	
	# 创建元素
	var element = create_element(current_element_type, int_grid_pos)
	if element:
		# 添加到网格
		grid[int_grid_x][int_grid_y] = element
		print("在 %s 放置了 %s" % [int_grid_pos, current_element_type])
		
		# 更新显示
		queue_redraw()
	else:
		print("创建元素失败，类型: %s" % current_element_type)
	
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
			if grid[new_grid_pos.x][new_grid_pos.y] != null:
				# 目标位置已被占用，将元素放回原处
				print("目标位置已被占用，元素位置已恢复")
				# 恢复原来的位置
				current_dragging_element.position = grid_to_world(drag_original_grid_pos)
				# 恢复网格中的引用
				grid[drag_original_grid_pos.x][drag_original_grid_pos.y] = current_dragging_element
			else:
				# 更新网格 - 将元素放到新位置
				print("将元素从 %s 移动到 %s" % [drag_original_grid_pos, new_grid_pos])
				grid[new_grid_pos.x][new_grid_pos.y] = current_dragging_element
				
				# 对齐到网格中心
				current_dragging_element.position = grid_to_world(new_grid_pos)
		else:
			# 新位置无效，将元素放回原处
			print("新位置无效，元素位置已恢复")
			# 恢复原来的位置
			current_dragging_element.position = grid_to_world(drag_original_grid_pos)
			# 恢复网格中的引用
			grid[drag_original_grid_pos.x][drag_original_grid_pos.y] = current_dragging_element
		
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
		width = element.grid_width
		height = element.grid_height
		bounds.size = Vector2(width * grid_size, height * grid_size)
	
	# 如果元素是 Sprite2D，使用纹理大小
	elif element is Sprite2D and element.texture:
		bounds.size = element.texture.get_size() * element.scale
	
	return bounds
	# 计算攻击方向
	var attack_direction = (get_global_mouse_position() - test_player.position).normalized()
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
		if collider is Switch or (collider.has_method("is_switch") and collider.is_switch()):
			collider.interact()
			print("攻击触发了开关: %s" % collider.name)
			
			# 测试模式下，如果连接了门，门会自动响应
			if test_switch_door_connections.has(collider):
				var connected_doors = test_switch_door_connections[collider]
				for door in connected_doors:
					if is_instance_valid(door) and door.has_method("toggle"):
						door.toggle()
						print("→ 触发连接的门: %s" % door.name)
		
		elif collider is Door or (collider.has_method("is_door") and collider.is_door()):
			if collider.has_method("interact"):
				collider.interact()
				print("攻击触发了门: %s" % collider.name)
		
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
			var rect = Rect2(
				x * grid_size,
				y * grid_size,
				grid_size,
				grid_size
			)
			draw_rect(rect, grid_color, true)
			draw_rect(rect, Color(0.5, 0.5, 0.5, 0.2), false)
	
	# 绘制当前元素预览
	if not test_mode_active and not is_dragging and not is_camera_dragging:
		var mouse_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		
		if is_valid_grid_position(grid_pos):
			var preview_color = Color(0, 1, 0, 0.3)
			
			# 计算预览位置
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
		
		# 直接使用区域矩形
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
		# 将玩家起始位置转换为本地坐标
		var local_player_pos = to_local(player_start_position)
		draw_circle(local_player_pos, 8, Color(0, 1, 0, 0.5))
		draw_string(
			ThemeDB.fallback_font,
			local_player_pos + Vector2(-10, -20),
			"玩家",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12
		)
	
	# 绘制拖拽中的元素边框
	if current_dragging_element and not test_mode_active:
		var bounds = get_element_bounds(current_dragging_element)
		# 将元素位置转换为本地坐标
		bounds.position = to_local(current_dragging_element.position) - Vector2(grid_size / 2, grid_size / 2)
		draw_rect(bounds, Color(1, 0, 0, 0.5), false, 2.0)
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
		
func is_mouse_over_ui() -> bool:
	"""检查鼠标是否在UI区域内"""
	if not ui_instance:
		return false
	
	# 获取鼠标位置
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 检查UI实例是否可见
	if ui_instance.visible:
		# 获取UI的全局矩形
		var ui_rect = get_ui_global_rect()
		if ui_rect and ui_rect.has_point(mouse_pos):
			print("在ui区域")
			return true
	
	return false

func get_ui_global_rect() -> Rect2:
	"""获取UI的全局矩形区域"""
	if ui_instance and ui_instance is CanvasLayer:
		# 获取CanvasLayer下的Control节点
		var control = ui_instance.get_node("Control")
		if control and control is Control:
			# 获取控制节点的全局矩形
			var rect = control.get_global_rect()
			return rect
	
	return Rect2()


func handle_editor_mouse(event: InputEventMouseButton):
	"""处理编辑器模式下的鼠标事件"""
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	
	print("鼠标事件: 按钮=%d, 按下=%s" % [event.button_index, event.pressed])
	
		# 检查鼠标是否在UI区域内
	if is_mouse_over_ui():
		print("鼠标在UI上，忽略编辑器操作")
		return
	
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 左键按下
			print("左键按下 (位置: %s, 网格: %s)" % [mouse_pos, grid_pos])
			
			# 先检查是否是元素拖拽
			if is_valid_grid_position(grid_pos) and grid[grid_pos.x][grid_pos.y] != null:
				# 开始拖拽现有元素
				current_dragging_element = grid[grid_pos.x][grid_pos.y]
				# 使用相对位置而不是绝对偏移
				drag_offset = mouse_pos - current_dragging_element.position
				is_dragging = true
				# 记录原始网格位置
				drag_original_grid_pos = grid_pos
				# 从网格中清除原始位置的引用
				grid[grid_pos.x][grid_pos.y] = null
				print("开始拖拽元素: %s (原始位置: %s)" % [current_dragging_element.name, grid_pos])
			else:
				# 否则开始区域拖拽
				is_left_dragging = true
				is_area_dragging = true
				area_drag_start = grid_pos
				area_drag_end = grid_pos
				print("开始左键区域放置拖拽，起始点: %s" % area_drag_start)
		else:
			# 左键释放
			print("左键释放 (位置: %s, 网格: %s)" % [mouse_pos, grid_pos])
			
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
			
			# 创建区域矩形（世界坐标）
			area_rect = Rect2(
				start_x * grid_size,
				start_y * grid_size,
				(end_x - start_x + 1) * grid_size,
				(end_y - start_y + 1) * grid_size
			)
			
			# 强制重绘
			queue_redraw()
	
	# 如果是元素拖拽
	elif current_dragging_element:
		var mouse_pos = get_global_mouse_position()
		
		if Input.is_key_pressed(KEY_CTRL):
			# Ctrl键：自由移动
			current_dragging_element.position = mouse_pos - drag_offset
		else:
			# 默认：对齐到网格
			var new_pos = mouse_pos - drag_offset
			var grid_pos = world_to_grid(new_pos)
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
	InputMap.action_erase_events("test_move_left")
	InputMap.action_erase_events("test_move_right")
	InputMap.action_erase_events("test_jump")
	InputMap.action_erase_events("test_attack")
	InputMap.action_erase_events("test_exit")
	# 保留测试模式切换
	InputMap.add_action("editor_toggle_test")
	var event = InputEventKey.new()
	event.keycode = KEY_TAB
	InputMap.action_add_event("editor_toggle_test", event)

	# 颜色选择 - 使用数字键0-9切换颜色
	InputMap.add_action("color_0")
	event = InputEventKey.new()
	event.keycode = KEY_0
	InputMap.action_add_event("color_0", event)
	
	InputMap.add_action("color_1")
	event = InputEventKey.new()
	event.keycode = KEY_1
	InputMap.action_add_event("color_1", event)
	
	InputMap.add_action("color_2")
	event = InputEventKey.new()
	event.keycode = KEY_2
	InputMap.action_add_event("color_2", event)
	
	InputMap.add_action("color_3")
	event = InputEventKey.new()
	event.keycode = KEY_3
	InputMap.action_add_event("color_3", event)
	
	InputMap.add_action("color_4")
	event = InputEventKey.new()
	event.keycode = KEY_4
	InputMap.action_add_event("color_4", event)
	
	InputMap.add_action("color_5")
	event = InputEventKey.new()
	event.keycode = KEY_5
	InputMap.action_add_event("color_5", event)
	
	InputMap.add_action("color_6")
	event = InputEventKey.new()
	event.keycode = KEY_6
	InputMap.action_add_event("color_6", event)
	
	InputMap.add_action("color_7")
	event = InputEventKey.new()
	event.keycode = KEY_7
	InputMap.action_add_event("color_7", event)
	
	InputMap.add_action("color_8")
	event = InputEventKey.new()
	event.keycode = KEY_8
	InputMap.action_add_event("color_8", event)
	
	InputMap.add_action("color_9")
	event = InputEventKey.new()
	event.keycode = KEY_9
	InputMap.action_add_event("color_9", event)
	if not test_mode_active:
		handle_camera_input(event)
	else:
		# 测试模式下的输入
		handle_test_mode_input(event)
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
func handle_test_mode_input(event):
	"""处理测试模式下的输入"""
	if not test_mode_active or not test_player:
		return
	
	# 测试模式退出
	if event.is_action_pressed("test_exit"):
		toggle_test_mode()
		return
	
	# 学生特有控制
	if test_player is Student:
		handle_student_test_input(event)

func handle_student_test_input(event):
	"""处理学生测试输入"""
	# 这些输入应该被传递给学生角色
	# 我们只需要确保InputMap中有相应的动作
	# 学生角色的_input函数会处理这些动作
	pass

# 在create_element函数中，添加碰撞设置
func apply_collision_to_element(element: Node2D, element_type: String):
	"""为元素应用碰撞设置"""
	match element_type:
		"ground":
			# 地面应该在第2层
			set_collision_layer_for_element(element, 4, true)
			print("为地面设置碰撞层2")
		"wall":
			# 墙壁应该在第3层
			set_collision_layer_for_element(element, 4, true)
			print("为墙壁设置碰撞层3")
		"dirt":
			# 泥土应该在第2层
			set_collision_layer_for_element(element, 2, true)
			print("为泥土设置碰撞层2")
		"door":
			# 门应该在第3层
			set_collision_layer_for_element(element, 3, true)
			print("为门设置碰撞层3")
		"fire":
			# 火焰陷阱应该在第5层
			set_collision_layer_for_element(element, 5, true)
			print("为火焰陷阱设置碰撞层5")
		"mechanism":
			# 机关应该在第4层
			set_collision_layer_for_element(element, 4, true)
			print("为机关设置碰撞层4")

func set_collision_layer_for_element(element: Node2D, layer: int, value: bool):
	"""为元素设置碰撞层"""
	# 尝试查找碰撞节点
	if element is StaticBody2D or element is Area2D or element is CharacterBody2D:
		element.set_collision_layer_value(layer, value)
		print("  ✓ 为元素根节点 %s 设置碰撞层 %d" % [element.get_class(), layer])
	
	# 查找子节点中的碰撞体
	for child in element.get_children():
		if child is StaticBody2D or child is Area2D or child is CharacterBody2D:
			child.set_collision_layer_value(layer, value)
			print("  ✓ 为子节点 %s 设置碰撞层 %d" % [child.get_class(), layer])
		
		# 递归查找更深层级的节点
		for grandchild in child.get_children():
			if grandchild is StaticBody2D or grandchild is Area2D or grandchild is CharacterBody2D:
				grandchild.set_collision_layer_value(layer, value)
				print("  ✓ 为孙节点 %s 设置碰撞层 %d" % [grandchild.get_class(), layer])
