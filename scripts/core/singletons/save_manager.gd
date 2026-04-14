extends Node
# 存档管理器

signal game_saved(slot: int, success: bool)
signal game_loaded(slot: int, success: bool)
signal save_deleted(slot: int)

const SAVE_DIR = "user://saves/"
const MAX_SAVE_SLOTS = 10

var current_save_data: Dictionary = {}
var save_slots: Array[Dictionary] = []

static var instance: Node

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("SaveManager 已加载")
	
	# 确保存档目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)
	
	# 加载存档列表
	_load_save_list()
	
	print("存档系统初始化完成，找到 %d 个存档" % save_slots.size())

func save_game(slot: int, data: Dictionary) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		print("错误：存档槽位 %d 无效" % slot)
		return false
	
	var save_path = SAVE_DIR + "save_%d.sav" % slot
	var save_data = {
		"slot": slot,
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": data.get("play_time", 0.0),
		"level": data.get("current_level", 1),
		"player_data": data
	}
	
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "thw_2024")
	if file:
		file.store_var(save_data)
		file.close()
		
		# 更新存档列表
		_update_save_list(slot, save_data)
		
		print("游戏已保存到槽位 %d" % slot)
		emit_signal("game_saved", slot, true)
		
		if EventBus.instance:
			EventBus.instance.game_saved.emit(slot)
		
		return true
	else:
		print("错误：无法保存游戏到槽位 %d" % slot)
		emit_signal("game_saved", slot, false)
		return false

func load_game(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		print("错误：存档槽位 %d 无效" % slot)
		return {}
	
	var save_path = SAVE_DIR + "save_%d.sav" % slot
	if not FileAccess.file_exists(save_path):
		print("错误：存档文件不存在: %s" % save_path)
		emit_signal("game_loaded", slot, false)
		return {}
	
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "thw_2024")
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data and "player_data" in save_data:
			print("游戏已从槽位 %d 加载" % slot)
			current_save_data = save_data["player_data"]
			
			emit_signal("game_loaded", slot, true)
			
			if EventBus.instance:
				EventBus.instance.game_loaded.emit(slot)
			
			return current_save_data
		else:
			print("错误：存档数据损坏")
	
	print("错误：无法加载游戏从槽位 %d" % slot)
	emit_signal("game_loaded", slot, false)
	return {}

func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	
	var save_path = SAVE_DIR + "save_%d.sav" % slot
	if FileAccess.file_exists(save_path):
		var error = DirAccess.remove_absolute(save_path)
		if error == OK:
			# 从存档列表中移除
			for i in range(save_slots.size()):
				if save_slots[i]["slot"] == slot:
					save_slots.remove_at(i)
					break
			
			print("存档槽位 %d 已删除" % slot)
			emit_signal("save_deleted", slot)
			return true
	
	return false

func get_save_info(slot: int) -> Dictionary:
	for save_info in save_slots:
		if save_info["slot"] == slot:
			return save_info
	return {}

func get_all_saves() -> Array[Dictionary]:
	return save_slots.duplicate()

func _load_save_list():
	save_slots.clear()
	
	for slot in range(MAX_SAVE_SLOTS):
		var save_path = SAVE_DIR + "save_%d.sav" % slot
		if FileAccess.file_exists(save_path):
			var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "thw_2024")
			if file:
				var save_data = file.get_var()
				file.close()
				
				if save_data and "timestamp" in save_data:
					var save_info = {
						"slot": slot,
						"timestamp": save_data["timestamp"],
						"play_time": save_data.get("play_time", 0.0),
						"level": save_data.get("level", 1),
						"exists": true
					}
					save_slots.append(save_info)

func _update_save_list(slot: int, save_data: Dictionary):
	# 移除旧的存档信息
	for i in range(save_slots.size()):
		if save_slots[i]["slot"] == slot:
			save_slots.remove_at(i)
			break
	
	# 添加新的存档信息
	var save_info = {
		"slot": slot,
		"timestamp": save_data["timestamp"],
		"play_time": save_data.get("play_time", 0.0),
		"level": save_data.get("level", 1),
		"exists": true
	}
	save_slots.append(save_info)
	
	# 按时间排序
	save_slots.sort_custom(func(a, b): return a["timestamp"] > b["timestamp"])

func quick_save() -> bool:
	if GameManager.instance:
		var data = GameManager.instance.player_data.duplicate()
		data["timestamp"] = Time.get_datetime_string_from_system()
		return save_game(0, data)
	return false

func quick_load() -> Dictionary:
	return load_game(0)
