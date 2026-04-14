# ui_manager.gd
extends CanvasLayer
class_name UIManager

static var instance: UIManager

# 信号
signal ui_layer_added(layer_name: String)
signal ui_layer_removed(layer_name: String)
signal ui_focus_changed(old_focus: Control, new_focus: Control)
signal ui_transition_started(transition_type: String)
signal ui_transition_completed(transition_type: String)

# UI层级
enum UILayer {
	BACKGROUND = 0,
	GAME = 1,
	DIALOGUE = 2,
	MENU = 3,
	LOADING = 4,
	NOTIFICATION = 5,
	DEBUG = 6
}

# 当前打开的UI
var current_ui: Dictionary = {}
var ui_history: Array = []

# 预设场景
var ui_prefabs: Dictionary = {
	"main_menu": "res://scenes/ui/main_menu/main_menu.tscn",
	"pause_menu": "res://scenes/ui/pause_menu/pause_menu.tscn",
	"hud": "res://scenes/ui/hud/hud.tscn",
	"dialogue": "res://scenes/ui/dialogue/dialogue_box.tscn",
	"choice": "res://scenes/ui/choice_menu/choice_menu.tscn",
	"loading": "res://scenes/ui/loading_screen/loading_screen.tscn",
	"notification": "res://scenes/ui/notification/notification.tscn"
}

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# 设置层级
	layer = 100  # 高层级，确保在最上面
	
	print("UIManager 初始化完成")

func show_ui(ui_name: String, layer: UILayer = UILayer.MENU, data: Dictionary = {}) -> Node:
	# 如果已经显示，先隐藏
	if ui_name in current_ui:
		hide_ui(ui_name)
	
	# 加载UI场景
	var ui_path = ui_prefabs.get(ui_name, "")
	if ui_path.is_empty():
		print("UI预设不存在: %s" % ui_name)
		return null
	
	var ui_scene = load(ui_path)
	if not ui_scene:
		print("无法加载UI场景: %s" % ui_path)
		return null
	
	# 实例化UI
	var ui_instance = ui_scene.instantiate()
	ui_instance.name = ui_name
	
	# 设置层级
	ui_instance.z_index = layer
	
	# 传递数据
	if ui_instance.has_method("set_data"):
		ui_instance.set_data(data)
	
	# 添加到场景
	add_child(ui_instance)
	
	# 保存引用
	current_ui[ui_name] = ui_instance
	
	# 添加到历史记录
	ui_history.append(ui_name)
	
	emit_signal("ui_layer_added", ui_name)
	print("显示UI: %s (层级: %d)" % [ui_name, layer])
	
	return ui_instance

func hide_ui(ui_name: String) -> void:
	if ui_name in current_ui:
		var ui_instance = current_ui[ui_name]
		ui_instance.queue_free()
		current_ui.erase(ui_name)
		
		# 从历史记录中移除
		var index = ui_history.find(ui_name)
		if index != -1:
			ui_history.remove_at(index)
		
		emit_signal("ui_layer_removed", ui_name)
		print("隐藏UI: %s" % ui_name)

func hide_all_ui() -> void:
	for ui_name in current_ui.keys():
		hide_ui(ui_name)

func get_ui(ui_name: String) -> Node:
	return current_ui.get(ui_name)

func is_ui_visible(ui_name: String) -> bool:
	return ui_name in current_ui

func show_hud() -> void:
	show_ui("hud", UILayer.GAME)

func hide_hud() -> void:
	hide_ui("hud")

func show_dialogue(speaker: String, text: String) -> void:
	var data = {
		"speaker": speaker,
		"text": text
	}
	show_ui("dialogue", UILayer.DIALOGUE, data)

# 删除冲突的 show_menu 函数
# 使用 show_main_menu() 代替

func show_choice(question: String, choices: Array) -> void:
	var data = {
		"question": question,
		"choices": choices
	}
	show_ui("choice", UILayer.DIALOGUE, data)

func show_loading_screen() -> void:
	show_ui("loading", UILayer.LOADING)

func hide_loading_screen() -> void:
	hide_ui("loading")

func show_notification(message: String, duration: float = 3.0) -> void:
	var data = {
		"message": message,
		"duration": duration
	}
	
	var notification = show_ui("notification", UILayer.NOTIFICATION, data)
	if notification and notification.has_method("show"):
		notification.show()

func show_pause_menu() -> void:
	show_ui("pause_menu", UILayer.MENU)

func hide_pause_menu() -> void:
	hide_ui("pause_menu")

func show_main_menu() -> void:
	show_ui("main_menu", UILayer.MENU)

func hide_main_menu() -> void:
	hide_ui("main_menu")

func go_back() -> bool:
	if ui_history.size() <= 1:
		return false
	
	# 移除当前UI
	var current = ui_history.pop_back()
	hide_ui(current)
	
	# 显示上一个UI
	if ui_history.size() > 0:
		var previous = ui_history.back()
		# 这里可以重新显示上一个UI
		print("返回至: %s" % previous)
		return true
	
	return false

func set_focus(control: Control) -> void:
	if control:
		control.grab_focus()

func clear_focus() -> void:
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_release_focus()

func is_any_menu_open() -> bool:
	for ui_name in current_ui.keys():
		if ui_name in ["main_menu", "pause_menu", "settings"]:
			return true
	return false
