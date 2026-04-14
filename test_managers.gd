
@tool
extends Node


func _run():
	print("=== 管理器测试 ===")
	
	# 测试GameManager
	test_game_manager()
	
	# 测试InputManager
	test_input_manager()
	
	# 测试AudioManager
	test_audio_manager()
	
	# 测试SaveManager
	test_save_manager()
	
	# 测试EventBus
	test_event_bus()
	
	print("=== 所有测试完成 ===")

func test_game_manager():
	print("\n1. 测试GameManager...")
	
	if GameManager and GameManager.instance:
		print("  ✓ GameManager 实例存在")
		print("    当前状态: ", GameManager.instance.current_state)
		
		# 测试状态切换
		var old_state = GameManager.instance.current_state
		GameManager.instance.current_state = GameManager.GameState.PLAYING
		print("    状态已切换: %s -> %s" % [old_state, GameManager.instance.current_state])
	else:
		print("  ✗ GameManager 未找到")

func test_input_manager():
	print("\n2. 测试InputManager...")
	
	if InputManager and InputManager.instance:
		print("  ✓ InputManager 实例存在")
		
		# 测试输入动作
		var actions = ["move_left", "move_right", "jump", "attack_q"]
		for action in actions:
			if InputMap.has_action(action):
				print("    ✓ 输入动作存在: %s" % action)
			else:
				print("    ✗ 输入动作不存在: %s" % action)
	else:
		print("  ✗ InputManager 未找到")

func test_audio_manager():
	print("\n3. 测试AudioManager...")
	
	if AudioManager and AudioManager.instance:
		print("  ✓ AudioManager 实例存在")
		
		# 测试音频总线
		var buses = ["Master", "Music", "SFX", "Voice"]
		for bus in buses:
			if AudioServer.get_bus_index(bus) >= 0:
				print("    ✓ 音频总线存在: %s" % bus)
			else:
				print("    ✗ 音频总线不存在: %s" % bus)
	else:
		print("  ✗ AudioManager 未找到")

func test_save_manager():
	print("\n4. 测试SaveManager...")
	
	if SaveManager and SaveManager.instance:
		print("  ✓ SaveManager 实例存在")
		
		# 测试存档目录
		var dir = DirAccess.open("user://")
		if dir.dir_exists("saves/"):
			print("    ✓ 存档目录存在")
		else:
			print("    ✗ 存档目录不存在")
	else:
		print("  ✗ SaveManager 未找到")

func test_event_bus():
	print("\n5. 测试EventBus...")
	
	if EventBus and EventBus.instance:
		print("  ✓ EventBus 实例存在")
		
		# 测试信号连接
		var test_signal_received = false
		EventBus.instance.debug_message.connect(
			func(msg, level):
				test_signal_received = true
				print("    ✓ 收到调试消息: %s" % msg)
		)
		
		EventBus.instance.debug_message.emit("测试消息", 0)
		
		if test_signal_received:
			print("    ✓ 信号系统工作正常")
	else:
		print("  ✗ EventBus 未找到")
