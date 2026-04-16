# LevelEditorUI.gd
extends CanvasLayer

# 信号定义
signal save_pressed
signal load_pressed
signal clear_pressed
signal test_mode_toggled(pressed: bool)
signal zoom_in_pressed
signal zoom_out_pressed
signal element_selected(element_type: String)
signal color_selected(color_index: int)
# 新增地图大小相关信号
signal level_size_changed(rows: int, cols: int)
signal reload_map_size_pressed
var mouse_over_ui: bool = false
# UI引用 - 更新为中文节点名称
@onready var save_button: Button = $Control/PanelContainer/VBoxContainer/文件操作/保存
@onready var load_button: Button = $Control/PanelContainer/VBoxContainer/文件操作/加载
@onready var clear_button: Button = $Control/PanelContainer/VBoxContainer/文件操作/清空
@onready var test_button: Button = $Control/PanelContainer/VBoxContainer/文件操作/测试模式
@onready var zoom_in_button: Button = $Control/PanelContainer/VBoxContainer/视图操作/放大
@onready var zoom_out_button: Button = $Control/PanelContainer/VBoxContainer/视图操作/缩小
@onready var zoom_label: Label = $Control/PanelContainer/VBoxContainer/视图操作/缩放显示
@onready var element_option: OptionButton = $Control/PanelContainer/VBoxContainer/元素选择/选择元素
@onready var element_label: Label = $Control/PanelContainer/VBoxContainer/元素选择/当前元素
@onready var color_preview: ColorRect = $Control/PanelContainer/VBoxContainer/颜色选择/颜色预览
@onready var color_option: OptionButton = $Control/PanelContainer/VBoxContainer/颜色选择/选择颜色
@onready var status_label: Label = $Control/PanelContainer/VBoxContainer/信息显示/状态信息
# 新增地图大小相关UI引用
@onready var rows_input: LineEdit = $Control/PanelContainer/VBoxContainer/地图大小设置/行数输入
@onready var cols_input: LineEdit = $Control/PanelContainer/VBoxContainer/地图大小设置/列数输入
@onready var reload_size_button: Button = $Control/PanelContainer/VBoxContainer/地图大小设置/重载地图大小

var current_zoom: float = 1.0
var is_test_mode: bool = false
var skip_element_signal: bool = false
var current_rows: int = 15
var current_cols: int = 20

func _ready():
	# 检查节点是否成功引用
	print("UI节点引用检查:")
	print("  save_button: ", "已找到" if save_button else "未找到")
	print("  load_button: ", "已找到" if load_button else "未找到")
	print("  clear_button: ", "已找到" if clear_button else "未找到")
	print("  test_button: ", "已找到" if test_button else "未找到")
	print("  element_option: ", "已找到" if element_option else "未找到")
	print("  color_option: ", "已找到" if color_option else "未找到")
	print("  status_label: ", "已找到" if status_label else "未找到")
	print("  rows_input: ", "已找到" if rows_input else "未找到")
	print("  cols_input: ", "已找到" if cols_input else "未找到")
	print("  reload_size_button: ", "已找到" if reload_size_button else "未找到")
	
	# 连接按钮信号
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	else:
		print("错误: save_button 未找到")
	
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	else:
		print("错误: load_button 未找到")
	
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)
	else:
		print("错误: clear_button 未找到")
	
	if test_button:
		test_button.toggled.connect(_on_test_button_toggled)
		test_button.toggle_mode = true
		test_button.button_pressed = false
	else:
		print("错误: test_button 未找到")
	
	if zoom_in_button:
		zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	else:
		print("错误: zoom_in_button 未找到")
	
	if zoom_out_button:
		zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	else:
		print("错误: zoom_out_button 未找到")
	
	# 连接新增地图大小按钮
	if reload_size_button:
		reload_size_button.pressed.connect(_on_reload_size_button_pressed)
	else:
		print("错误: reload_size_button 未找到")
	
	# 连接输入框信号
	if rows_input:
		rows_input.text_submitted.connect(_on_rows_input_submitted)
		rows_input.focus_exited.connect(_on_rows_input_focus_exited)
	else:
		print("错误: rows_input 未找到")
	
	if cols_input:
		cols_input.text_submitted.connect(_on_cols_input_submitted)
		cols_input.focus_exited.connect(_on_cols_input_focus_exited)
	else:
		print("错误: cols_input 未找到")
	
	# 初始化元素选项
	init_element_options()
	
	# 初始化颜色选项
	init_color_options()
	
	# 初始化地图大小输入框
	init_map_size_inputs()
	# 调试元素选项
	print("UI: element_option.item_count = ", element_option.item_count)
	print("UI: element_option.items = ", element_option.get_item_count())
	
	# 测试元数据
	for i in range(element_option.get_item_count()):
		var text = element_option.get_item_text(i)
		var metadata = element_option.get_item_metadata(i)
		print("UI: 选项[%d]: 文本='%s', 元数据='%s'" % [i, text, metadata])

	
	
	# 连接选项信号
	if element_option:
		element_option.item_selected.connect(_on_element_selected)
	else:
		print("错误: element_option 未找到")
	
	if color_option:
		color_option.item_selected.connect(_on_color_selected)
	else:
		print("错误: color_option 未找到")
	
	# 初始状态
	update_status("编辑器就绪")
	update_zoom_label()
	



func init_map_size_inputs():
	"""初始化地图大小输入框"""
	if rows_input:
		rows_input.text = str(current_rows)
		rows_input.placeholder_text = "行数"
	
	if cols_input:
		cols_input.text = str(current_cols)
		cols_input.placeholder_text = "列数"

# 添加新的信号处理函数
func _on_reload_size_button_pressed():
	"""重载地图大小按钮按下"""
	print("重载地图大小按钮按下")
	
	# 获取输入框的值
	var new_rows = get_rows_input()
	var new_cols = get_cols_input()
	
	# 验证输入是否有效
	if new_rows > 0 and new_cols > 0:
		# 更新当前值
		current_rows = new_rows
		current_cols = new_cols
		
		# 发送重载信号
		reload_map_size_pressed.emit()
		
		# 发送地图大小变化信号
		level_size_changed.emit(new_rows, new_cols)
		
		update_status("地图大小已更新: %d行 × %d列" % [new_rows, new_cols])
	else:
		update_status("错误: 行数和列数必须大于0")

func _on_rows_input_submitted(new_text: String):
	"""行数输入框提交"""
	var rows = new_text.to_int()
	if rows > 0:
		current_rows = rows
		level_size_changed.emit(rows, current_cols)
		update_status("行数更新为: %d" % rows)
	else:
		rows_input.text = str(current_rows)
		update_status("错误: 行数必须大于0")

func _on_rows_input_focus_exited():
	"""行数输入框失去焦点"""
	if rows_input:
		var rows = rows_input.text.to_int()
		if rows > 0:
			current_rows = rows
			level_size_changed.emit(rows, current_cols)
		else:
			rows_input.text = str(current_rows)

func _on_cols_input_submitted(new_text: String):
	"""列数输入框提交"""
	var cols = new_text.to_int()
	if cols > 0:
		current_cols = cols
		level_size_changed.emit(current_rows, cols)
		update_status("列数更新为: %d" % cols)
	else:
		cols_input.text = str(current_cols)
		update_status("错误: 列数必须大于0")

func _on_cols_input_focus_exited():
	"""列数输入框失去焦点"""
	if cols_input:
		var cols = cols_input.text.to_int()
		if cols > 0:
			current_cols = cols
			level_size_changed.emit(current_rows, cols)
		else:
			cols_input.text = str(current_cols)

# 辅助函数
func get_rows_input() -> int:
	"""获取行数输入值"""
	if rows_input:
		return rows_input.text.to_int()
	return current_rows

func get_cols_input() -> int:
	"""获取列数输入值"""
	if cols_input:
		return cols_input.text.to_int()
	return current_cols

func set_map_size(rows: int, cols: int):
	"""设置地图大小"""
	if rows <= 0 or cols <= 0:
		print("错误: 行数和列数必须大于0")
		return
	
	current_rows = rows
	current_cols = cols
	
	if rows_input:
		rows_input.text = str(rows)
	
	if cols_input:
		cols_input.text = str(cols)
	
	update_status("地图大小: %d行 × %d列" % [rows, cols])



func init_element_options():
	"""初始化元素选项"""
	element_option.clear()
	
	# 定义元素类型和对应的显示文本
	var elements = [
		{"id": "wall", "text": "墙壁"},
		{"id": "ground", "text": "地面"},
		{"id": "switch", "text": "开关"},
		{"id": "door", "text": "门"},
		{"id": "fire", "text": "火焰陷阱"},
		{"id": "player", "text": "玩家"},
		{"id": "student", "text": "学生"},
		{"id": "goal", "text": "终点"},
		{"id": "teleporter_in", "text": "传送门入口"},
		{"id": "teleporter_out", "text": "传送门出口"},
		{"id": "bow", "text": "弓箭"},
		{"id": "dirt", "text": "泥土"}
	]
	
	for element in elements:
		element_option.add_item(element["text"])
		element_option.set_item_metadata(element_option.item_count - 1, element["id"])
	
	# 默认选择第一个
	element_option.select(0)

func init_color_options():
	"""初始化颜色选项"""
	color_option.clear()
	
	# 颜色名称数组
	var colors = ["红", "橙", "黄", "绿", "青", "蓝", "紫", "白", "灰", "黑"]
	var color_values = [
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
	
	for i in range(colors.size()):
		color_option.add_item(colors[i])
		color_option.set_item_metadata(i, i)
		
		# 设置颜色预览
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.texture = create_color_texture(color_values[i])
		color_option.set_item_icon(i, icon.texture)
	
	# 默认选择第一个
	color_option.select(0)
	update_color_preview(color_values[0])

func create_color_texture(color: Color) -> Texture2D:
	"""创建颜色纹理"""
	var image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

# 按钮信号处理函数
func _on_save_button_pressed():
	save_pressed.emit()
	update_status("正在保存关卡...")

func _on_load_button_pressed():
	load_pressed.emit()
	update_status("正在加载关卡...")

func _on_clear_button_pressed():
	clear_pressed.emit()
	update_status("正在清空关卡...")

func _on_test_button_toggled(pressed: bool):
	is_test_mode = pressed
	test_mode_toggled.emit(pressed)
	test_button.text = "测试模式: " + ("开" if pressed else "关")
	update_status("测试模式: " + ("开启" if pressed else "关闭"))

func _on_zoom_in_pressed():
	current_zoom += 0.1
	if current_zoom > 2.0:
		current_zoom = 2.0
	zoom_in_pressed.emit()
	update_zoom_label()
	update_status("放大视图")

func _on_zoom_out_pressed():
	current_zoom -= 0.1
	if current_zoom < 0.5:
		current_zoom = 0.5
	zoom_out_pressed.emit()
	update_zoom_label()
	update_status("缩小视图")

# 修改 _on_element_selected
func _on_element_selected(index: int):
	if skip_element_signal:
		skip_element_signal = false
		return
	
	var element_type = element_option.get_item_metadata(index)
	element_selected.emit(element_type)
	element_label.text = "当前: " + element_option.get_item_text(index)
	update_status("选择元素: " + element_option.get_item_text(index))

func _on_color_selected(index: int):
	var color_index = color_option.get_item_metadata(index)
	color_selected.emit(color_index)
	
	# 更新颜色预览
	var colors = [
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
	
	if color_index < colors.size():
		update_color_preview(colors[color_index])
	
	update_status("选择颜色: " + color_option.get_item_text(index))

# UI更新函数
func update_status(message: String):
	"""更新状态信息"""
	status_label.text = message
	print("UI状态: " + message)

func update_zoom_label():
	"""更新缩放标签"""
	zoom_label.text = "缩放: " + str(round(current_zoom * 100)) + "%"

func update_color_preview(color: Color):
	"""更新颜色预览"""
	color_preview.color = color
# 修改 set_current_element
func set_current_element(element_type: String):
	"""设置当前选择的元素"""
	print("UI: 尝试设置当前元素类型: ", element_type)
	
	# 检查当前是否已经是这个元素
	var current_index = element_option.get_selected()
	if current_index >= 0:
		var current_id = element_option.get_item_metadata(current_index)
		if current_id == element_type:
			print("UI: 当前已经是这个元素，跳过更新")
			return
	
	# 先检查元素类型是否在UI的元素列表中
	var found = false
	for i in range(element_option.item_count):
		var item_id = element_option.get_item_metadata(i)
		if item_id == element_type:
			# 设置跳过信号标志，防止循环
			skip_element_signal = true
			element_option.select(i)
			element_label.text = "当前: " + element_option.get_item_text(i)
			print("UI: 成功设置元素为: ", element_option.get_item_text(i))
			found = true
			break
	
	# 如果没有找到，使用默认的第一个元素
	if not found and element_option.item_count > 0:
		print("UI: 警告: 元素类型'", element_type, "'不在UI元素列表中，使用默认元素")
		element_option.select(0)
		var default_id = element_option.get_item_metadata(0)
		element_label.text = "当前: " + element_option.get_item_text(0)
		print("UI: 使用默认元素: ", element_option.get_item_text(0))
		
		# 发送信号通知主编辑器切换到默认元素
		element_selected.emit(default_id)
	else:
		# 更新状态显示
		update_status("当前元素: " + element_type)
	
	# 刷新界面
	element_option.queue_redraw()
	
func set_current_color(color_index: int):
	"""设置当前选择的颜色"""
	if color_index < color_option.item_count:
		color_option.select(color_index)
		
		# 更新颜色预览
		var colors = [
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
		
		if color_index < colors.size():
			update_color_preview(colors[color_index])
		
		update_status("颜色: " + color_option.get_item_text(color_index))
