# test_mouse_click.gd
extends Control

func _ready():
	print("=== 鼠标点击调试 ===")
	print("点击屏幕上任何位置查看输出")
	
	# 设置全屏捕获鼠标
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1, 1, 1, 0.1)  # 半透明可见
	
	print("等待鼠标点击...")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var pos = event.position
		var button = event.button_index
		var pressed = event.pressed
		
		print("鼠标点击: 位置=%s, 按钮=%d, 按下=%s" % [pos, button, pressed])
		
		# 检查是否点击了按钮区域
		check_button_hit(pos)

func check_button_hit(position: Vector2):
	# 查找主菜单中的按钮
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		var new_game_btn = main_menu.get_node_or_null("NewGameButton")
		if new_game_btn:
			var btn_rect = new_game_btn.get_global_rect()
			if btn_rect.has_point(position):
				print("✓ 点击了'新游戏'按钮区域")
			else:
				print("✗ 未点击按钮区域，按钮位置: %s" % btn_rect)
