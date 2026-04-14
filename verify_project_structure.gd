extends Node

func _ready():
	print("=== 验证项目结构 ===")
	
	check_directories()
	check_required_files()
	check_autoload()
	check_main_scene()

func check_directories():
	print("\n检查目录结构:")
	
	var required_dirs = [
		"scripts/core/singletons",
		"scenes/system",
		"scenes/ui/main_menu",
		"scenes/actors/player/student",
		"scenes/ui/hud",
		"assets/audio/music",
		"assets/audio/sfx",
		"assets/graphics/characters",
		"data/levels",
		"data/dialogues"
	]
	
	for dir in required_dirs:
		if DirAccess.dir_exists_absolute("res://" + dir):
			print("✓ " + dir)
		else:
			print("✗ " + dir + " (不存在)")

func check_required_files():
	print("\n检查必需文件:")
	
	var required_files = [
		"scripts/core/singletons/game_manager.gd",
		"scenes/system/main.tscn",
		"scenes/system/main.gd",
		"scenes/ui/main_menu/main_menu.tscn",
		"scenes/ui/main_menu/main_menu.gd"
	]
	
	for file in required_files:
		if FileAccess.file_exists("res://" + file):
			print("✓ " + file)
		else:
			print("✗ " + file + " (不存在)")

func check_autoload():
	print("\n检查自动加载:")
	
	var autoloads = ProjectSettings.get_setting("autoload", {})
	if "GameManager" in autoloads:
		print("✓ GameManager 已设置为自动加载")
	else:
		print("✗ GameManager 未设置为自动加载")

func check_main_scene():
	print("\n检查主场景设置:")
	
	var main_scene = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene:
		print("主场景: " + main_scene)
		
		if FileAccess.file_exists(main_scene):
			print("✓ 主场景文件存在")
		else:
			print("✗ 主场景文件不存在")
	else:
		print("✗ 主场景未设置")
