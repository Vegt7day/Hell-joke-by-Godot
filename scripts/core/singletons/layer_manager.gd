# layer_manager.gd
extends CanvasLayer
class_name LayerManager

enum LayerType {
	WORLD = 0,      # 游戏世界
	HUD = 1,        # 游戏内HUD
	MENU = 2,       # 菜单
	DIALOG = 3,     # 对话框
	LOADING = 4,    # 加载界面
	NOTIFICATION = 5 # 通知
}

static var instance: LayerManager

var current_scene: Node = null
var current_ui: Dictionary = {}

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	layer = 100
	print("LayerManager 已加载")

func switch_to_game():
	"""切换到游戏状态"""
	print("切换到游戏状态")
	
	# 隐藏所有菜单
	for ui_name in current_ui.keys():
		if ui_name in ["main_menu", "pause_menu", "settings"]:
			hide_ui(ui_name)
	
	# 显示游戏HUD
	show_ui("hud", LayerType.HUD)
	
	# 确保世界层在最下面
	if current_scene:
		current_scene.z_index = LayerType.WORLD

func switch_to_menu(menu_name: String = "main_menu"):
	"""切换到菜单状态"""
	print("切换到菜单状态: %s" % menu_name)
	
	# 隐藏游戏HUD
	hide_ui("hud")
	
	# 显示指定菜单
	show_ui(menu_name, LayerType.MENU)
	
	# 如果有游戏场景，暂停游戏
	if current_scene and current_scene.has_method("set_pause"):
		current_scene.set_pause(true)

func show_ui(ui_name: String, layer_type: LayerType) -> Node:
	"""显示UI"""
	# 先隐藏同一层级的其他UI
	for existing_ui in current_ui.keys():
		if existing_ui != ui_name:
			# 可以添加逻辑判断是否隐藏
			pass
	
	# 加载和显示UI
	# 这里可以调用UIManager
	if UIManager.instance:
		return UIManager.instance.show_ui(ui_name, UIManager.UILayer.MENU)
	
	return null

func hide_ui(ui_name: String):
	"""隐藏UI"""
	if UIManager.instance:
		UIManager.instance.hide_ui(ui_name)
	
	if ui_name in current_ui:
		current_ui.erase(ui_name)
