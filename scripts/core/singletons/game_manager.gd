

extends Node

# 单例实例
static var instance: Node

# 游戏状态枚举
enum GameState { 
	MAIN_MENU,      # 主菜单
	PLAYING,        # 游戏中
	PAUSED,         # 暂停
	CUTSCENE,       # 过场动画
	GAME_OVER       # 游戏结束
}

# 当前状态
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

# 容器引用（将在运行时设置）
var world_container: Node2D
var ui_container: CanvasLayer
var effects_container: Node2D

# 游戏数据
var player_data: Dictionary = {
	"current_level": 1,
	"current_form": "student",
	"unlocked_forms": ["student"],
	"health": 100,
	"max_health": 100,
	"ink": 100,
	"max_ink": 100,
	"checkpoint": Vector2.ZERO,
	"play_time": 0.0
}

var game_settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": true,
	"vsync": true,
	"show_fps": false
}

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	print("GameManager 初始化完成")

func _ready():
	print("GameManager 就绪")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func setup_containers(world: Node2D, ui: CanvasLayer, effects: Node2D = null):
	world_container = world
	ui_container = ui
	if effects:
		effects_container = effects
	else:
		effects_container = Node2D.new()
		effects_container.name = "Effects"
		get_tree().root.add_child(effects_container)

	print("容器设置完成")
	show_main_menu()
# 在 game_manager.gd 中
func show_main_menu():
	print("显示主菜单...")
	current_state = GameState.MAIN_MENU
	
	# 清空UI容器
	clear_ui_container()
	
	# 切换到菜单状态
	if layer_manager:
		layer_manager.switch_to_menu("main_menu")
	elif UIManager.instance:
		UIManager.instance.show_main_menu()
	else:
		# 备用方案
		var main_menu_scene = load("res://scenes/ui/main_menu/main_menu.tscn")
		if main_menu_scene:
			var main_menu = main_menu_scene.instantiate()
			ui_container.add_child(main_menu)
			print("主菜单已直接加载")
			
			
func clear_ui_container():
	for child in ui_container.get_children():
		child.queue_free()

func create_fallback_menu():
	print("创建备用菜单...")

	var menu = Control.new()
	menu.name = "FallbackMenu"
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "文字地狱大战"
	title.position = Vector2(400, 200)
	title.add_theme_font_size_override("font_size", 48)
	menu.add_child(title)

	# 开始按钮
	var start_btn = Button.new()
	start_btn.text = "开始游戏"
	start_btn.position = Vector2(500, 300)
	start_btn.pressed.connect(start_new_game)
	menu.add_child(start_btn)

	# 退出按钮
	var quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.position = Vector2(500, 370)
	quit_btn.pressed.connect(get_tree().quit)
	menu.add_child(quit_btn)

	ui_container.add_child(menu)
	print("备用菜单已创建")
	
# 在顶部添加
@onready var layer_manager: Node = get_node("/root/LayerManager") if has_node("/root/LayerManager") else null
	
	
	
func start_new_game():
	print("开始新游戏")
	current_state = GameState.PLAYING
	
	# 清空所有容器
	clear_all_containers()
	
	# 重置玩家数据
	reset_player_data()
	
	# 切换到游戏状态
	if layer_manager:
		layer_manager.switch_to_game()
	else:
		# 备用方案
		hide_main_menu()
		show_hud()
		
	# 加载测试关卡
	create_test_level()
	
	print("新游戏开始完成")

func hide_main_menu():
	print("隐藏主菜单...")
	
	# 方法1：如果主菜单是通过UIManager显示的
	if UIManager.instance:
		UIManager.instance.hide_ui("main_menu")
		print("通过UIManager隐藏主菜单")
	
	# 方法2：如果主菜单是直接添加到ui_container的
	if ui_container:
		# 查找并移除主菜单节点
		var main_menu_nodes = ui_container.get_children()
		for child in main_menu_nodes:
			if "main_menu" in child.name.to_lower() or child.name == "MainMenu":
				print("找到并移除主菜单节点: %s" % child.name)
				child.queue_free()
func clear_all_containers():
	# 清空世界容器
	for child in world_container.get_children():
		child.queue_free()

	# 清空UI容器
	clear_ui_container()

	# 清空特效容器
	if effects_container:
		for child in effects_container.get_children():
			child.queue_free()

func reset_player_data():
	player_data = {
		"current_level": 1,
		"current_form": "student",
		"unlocked_forms": ["student"],
		"health": 100,
		"max_health": 100,
		"ink": 100,
		"max_ink": 100,
		"checkpoint": Vector2.ZERO,
		"play_time": 0.0
	}
	print("玩家数据已重置")

func load_level(level_number: int):
	print("加载关卡: ", level_number)

	# 这里会通过LevelManager加载关卡
	# 暂时创建测试关卡
	create_test_level()
func create_test_level():
	print("创建测试关卡...")
	
	# 清空世界容器
	for child in world_container.get_children():
		child.queue_free()
	
	# 加载学生测试关卡
	var test_level_scene = load("res://scenes/levels/test_rooms/test_student.tscn")
	if test_level_scene:
		var test_level = test_level_scene.instantiate()
		test_level.name = "StudentTestLevel"
		world_container.add_child(test_level)
		print("学生测试关卡已加载")
	else:
		print("错误：无法加载测试关卡，创建简单关卡")
		create_simple_test_level()
	
	print("测试关卡创建完成")

func create_simple_test_level():
	"""创建简单测试关卡"""
	print("创建简单测试关卡...")
	
	var test_level = Node2D.new()
	test_level.name = "SimpleTestLevel"
	
	# 添加玩家
	var player_scene = load("res://scenes/actors/player/student/student.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.position = Vector2(100, 100)
		test_level.add_child(player)
		print("玩家已添加到简单关卡")
	
	# 添加地面
	var ground = StaticBody2D.new()
	ground.position = Vector2(500, 500)
	
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(1000, 50)
	ground.add_child(collision)
	
	test_level.add_child(ground)
	
	# 添加到世界容器
	world_container.add_child(test_level)

func show_hud():
	print("显示HUD...")
	
	if layer_manager:
		layer_manager.show_ui("hud", layer_manager.LayerType.HUD)
	elif UIManager.instance:
		UIManager.instance.show_hud()
	else:
		print("错误：无法显示HUD，LayerManager和UIManager都不可用")

func create_simple_hud():
	var hud = Control.new()
	hud.name = "SimpleHUD"

	# 生命值显示
	var health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "生命: 100/100"
	health_label.position = Vector2(20, 20)
	hud.add_child(health_label)

	# 墨水显示
	var ink_label = Label.new()
	ink_label.name = "InkLabel"
	ink_label.text = "墨水: 100/100"
	ink_label.position = Vector2(20, 50)
	hud.add_child(ink_label)

	ui_container.add_child(hud)
