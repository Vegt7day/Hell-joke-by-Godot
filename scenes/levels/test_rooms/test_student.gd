extends Node2D
# 学生形态测试关卡

func _ready():
	print("=== 学生形态测试关卡 ===")
	
	# 查找玩家
	var player = $Student
	if player:
		print("玩家已加载: %s" % player.name)
		
		# 连接玩家信号
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		player.player_respawned.connect(_on_player_respawned)
		
		# 打印初始状态
		print("玩家生命值: %f/%f" % [player.health, player.max_health])
		print("玩家墨水: %f/%f" % [player.ink, player.max_ink])
		print("活动肢体: %s" % player.active_limb)
	
	# 添加测试UI
	create_test_ui()

func _on_player_health_changed(old_health: float, new_health: float):
	print("玩家生命值变化: %f -> %f" % [old_health, new_health])

func _on_player_died(cause: String):
	print("玩家死亡，原因: %s" % cause)

func _on_player_respawned():
	print("玩家已重生")

func create_test_ui():
	"""创建测试UI"""
	print("创建测试UI")
	
	# 这里可以添加测试用的UI按钮
	# 例如：测试伤害、测试墨水消耗等
	
	var test_panel = Panel.new()
	test_panel.position = Vector2(20, 20)
	test_panel.size = Vector2(200, 150)
	add_child(test_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.size = Vector2(180, 130)
	test_panel.add_child(vbox)
	
	# 测试伤害按钮
	var damage_btn = Button.new()
	damage_btn.text = "测试伤害(10)"
	damage_btn.pressed.connect(
		func():
			var player = $Student
			if player:
				player.take_damage(10, "test")
	)
	vbox.add_child(damage_btn)
	
	# 测试治疗按钮
	var heal_btn = Button.new()
	heal_btn.text = "测试治疗(20)"
	heal_btn.pressed.connect(
		func():
			var player = $Student
			if player:
				player.health = min(player.max_health, player.health + 20)
				player.health_changed.emit(player.health - 20, player.health)
	)
	vbox.add_child(heal_btn)
	
	print("测试UI已创建")
