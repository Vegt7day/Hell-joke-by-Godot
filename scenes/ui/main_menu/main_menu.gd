extends Control
class_name MainMenu

# 节点引用
@onready var title_label: Label = $MenuContainer/TitleLabel
@onready var new_game_button: Button = $MenuContainer/NewGameButton
@onready var continue_button: Button = $MenuContainer/ContinueButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var quit_button: Button = $MenuContainer/QuitButton
@onready var version_label: Label = $MenuContainer/VersionLabel

func _ready():
	print("主菜单已加载")
	
	# 设置版本号
	version_label.text = "文字地狱大战 v1.0.0 Alpha"
	
	# 连接按钮信号
	connect_button_signals()
	
	# 检查存档
	check_save_data()
	
	# 设置焦点
	new_game_button.grab_focus()

func connect_button_signals():
	print("连接按钮信号...")
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	print("所有按钮信号已连接")

func check_save_data():
	print("检查存档数据...")
	
	# 这里可以检查是否有存档
	# 暂时设置继续按钮可用
	continue_button.disabled = false
	
	# 如果有存档，显示最后游戏时间
	var has_save = false  # 这里应检查实际存档
	if has_save:
		continue_button.text = "继续游戏 (有存档)"
	else:
		continue_button.text = "继续游戏 (无存档)"
		continue_button.disabled = true

func _on_new_game_pressed():
	print("新游戏按钮被点击")
	
	# 播放点击音效
	play_button_sound()
	
	# 通知GameManager开始新游戏
	if GameManager.instance:
		GameManager.instance.start_new_game()
	else:
		print("错误：GameManager未找到")
		# 备用方案
		start_game_fallback()

func _on_continue_pressed():
	print("继续游戏按钮被点击")
	
	# 播放点击音效
	play_button_sound()
	
	# 这里应该加载存档
	print("加载存档功能待实现")
	
	# 暂时也调用开始游戏
	if GameManager.instance:
		GameManager.instance.start_new_game()

func _on_settings_pressed():
	print("设置按钮被点击")
	
	# 播放点击音效
	play_button_sound()
	
	# 打开设置菜单
	open_settings_menu()

func _on_quit_pressed():
	print("退出游戏按钮被点击")
	
	# 播放点击音效
	play_button_sound()
	
	# 退出游戏
	get_tree().quit()

func play_button_sound():
	print("播放按钮音效")
	# 这里可以播放UI音效
	# AudioManager.instance.play_ui_sound("button_click")

func start_game_fallback():
	print("使用备用方案开始游戏")
	
	# 隐藏主菜单
	hide()
	
	# 创建简单的游戏世界
	var parent = get_parent()
	if parent:
		# 清空父节点的其他子节点
		for child in parent.get_children():
			if child != self:
				child.queue_free()
		
		# 创建测试关卡
		var test_level = Node2D.new()
		test_level.name = "TestLevel"
		
		# 添加玩家
		var player = CharacterBody2D.new()
		player.name = "Player"
		player.position = Vector2(100, 100)
		test_level.add_child(player)
		
		parent.add_child(test_level)
	
	queue_free()

func open_settings_menu():
	print("打开设置菜单")
	
	# 这里应该打开设置界面
	# 暂时显示消息
	var message = Label.new()
	message.text = "设置菜单\n(功能开发中)"
	message.position = Vector2(300, 300)
	message.add_theme_font_size_override("font_size", 32)
	add_child(message)
	
	# 3秒后移除
	await get_tree().create_timer(3.0).timeout
	message.queue_free()
