extends Node
class_name Main

@onready var world_container: Node2D = $World
@onready var ui_container: CanvasLayer = $UI
@onready var effects_container: Node2D = $Effects

func _ready():
	print("主场景加载完成")
	
	# 验证容器
	setup_containers()
	
	# 通知GameManager
	notify_game_manager()

func setup_containers():
	print("设置容器...")
	
	# 确保容器存在
	if not world_container:
		print("创建World容器")
		world_container = Node2D.new()
		world_container.name = "World"
		add_child(world_container)
		world_container.owner = self
	
	if not ui_container:
		print("创建UI容器")
		ui_container = CanvasLayer.new()
		ui_container.name = "UI"
		ui_container.layer = 10
		add_child(ui_container)
		ui_container.owner = self
	
	if not effects_container:
		print("创建Effects容器")
		effects_container = Node2D.new()
		effects_container.name = "Effects"
		add_child(effects_container)
		effects_container.owner = self
	
	print("容器设置完成")

func notify_game_manager():
	print("通知GameManager...")
	
	# 等待一帧确保GameManager已加载
	await get_tree().process_frame
	
	if GameManager.instance:
		print("找到GameManager实例，传递容器引用")
		GameManager.instance.setup_containers(world_container, ui_container, effects_container)
	else:
		print("错误：GameManager实例未找到！")
		
		# 备用方案：直接加载主菜单
		load_main_menu_directly()

func load_main_menu_directly():
	print("直接加载主菜单...")
	
	var main_menu_scene = load("res://scenes/ui/main_menu/main_menu.tscn")
	if main_menu_scene:
		var main_menu = main_menu_scene.instantiate()
		ui_container.add_child(main_menu)
		print("主菜单已直接加载")
	else:
		print("错误：无法加载主菜单场景")
