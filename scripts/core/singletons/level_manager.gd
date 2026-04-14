extends Node
# 关卡管理器

signal level_loading_started(level_id: String)
signal level_loading_progress(progress: float)
signal level_loading_completed(level_id: String)
signal level_transition_started(from_level: String, to_level: String)
signal level_transition_completed(to_level: String)

var current_level: String = ""
var current_level_node: Node = null
var level_queue: Array[String] = []
var is_transitioning: bool = false

static var instance: Node

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("LevelManager 已加载")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	if EventBus.instance:
		EventBus.instance.game_state_changed.connect(_on_game_state_changed)

func load_level(level_id: String, transition_type: String = "fade") -> bool:
	if is_transitioning:
		print("警告：正在切换关卡，请等待")
		return false
	
	print("开始加载关卡: %s" % level_id)
	
	is_transitioning = true
	emit_signal("level_loading_started", level_id)
	emit_signal("level_transition_started", current_level, level_id)
	
	if EventBus.instance:
		EventBus.instance.level_started.emit(level_id)
	
	# 显示加载界面
	if UiManager.instance:
		UiManager.instance.show_loading_screen()
	
	# 卸载当前关卡
	if current_level_node and GameManager.instance and GameManager.instance.world_container:
		GameManager.instance.world_container.remove_child(current_level_node)
		current_level_node.queue_free()
		current_level_node = null
	
	# 加载新关卡
	var level_path = "res://scenes/levels/%s/%s.tscn" % [level_id, level_id]
	if not ResourceLoader.exists(level_path):
		print("错误：关卡文件不存在: %s" % level_path)
		level_path = "res://scenes/levels/test_rooms/%s.tscn" % level_id
		if not ResourceLoader.exists(level_path):
			print("错误：测试关卡文件也不存在")
			is_transitioning = false
			return false
	
	# 模拟加载进度
	for i in range(5):
		await get_tree().create_timer(0.1).timeout
		emit_signal("level_loading_progress", (i + 1) * 0.2)
	
	var level_scene = load(level_path)
	if not level_scene:
		print("错误：无法加载关卡场景")
		is_transitioning = false
		return false
	
	current_level_node = level_scene.instantiate()
	current_level = level_id
	
	# 添加到世界容器
	if GameManager.instance and GameManager.instance.world_container:
		GameManager.instance.world_container.add_child(current_level_node)
		
		# 查找玩家出生点
		var spawn_points = current_level_node.find_children("*", "Position2D")
		for spawn in spawn_points:
			if spawn.name == "PlayerSpawn":
				# 这里可以设置玩家位置
				pass
		
		# 更新GameManager
		if GameManager.instance:
			GameManager.instance.player_data["current_level"] = level_id
		
		# 隐藏加载界面
		if UiManager.instance:
			UiManager.instance.hide_loading_screen()
		
		emit_signal("level_loading_completed", level_id)
		emit_signal("level_transition_completed", level_id)
		
		print("关卡加载完成: %s" % level_id)
		
		# 播放进入关卡音效
		if AudioManager.instance:
			AudioManager.instance.play_sfx("res://assets/audio/sfx/ui/level_start.ogg")
		
		is_transitioning = false
		return true
	
	is_transitioning = false
	return false

func reload_current_level() -> bool:
	if current_level:
		return await load_level(current_level)
	return false

func queue_level(level_id: String):
	level_queue.append(level_id)
	print("关卡已加入队列: %s" % level_id)

func load_next_queued_level() -> bool:
	if level_queue.size() > 0:
		var next_level = level_queue.pop_front()
		return await load_level(next_level)
	return false

func get_current_level_info() -> Dictionary:
	if current_level_node and current_level_node.has_method("get_level_info"):
		return current_level_node.get_level_info()
	
	return {
		"id": current_level,
		"name": current_level,
		"difficulty": 1,
		"time_limit": 0,
		"checkpoints": 0
	}

func _on_game_state_changed(old_state, new_state):
	if new_state == "PLAYING" and not current_level:
		# 加载第一关
		load_level("intro")
