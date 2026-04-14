extends Node
# 事件总线 - 用于组件间通信

# 玩家事件
signal player_spawned(player_node)
signal player_died(cause: String)
signal player_hurt(damage: int, current_health: int)
signal player_healed(amount: int, current_health: int)
signal player_form_changed(old_form: String, new_form: String)
signal player_level_changed(level: int)
signal player_checkpoint_reached(checkpoint_id: String)

# 游戏事件
signal game_state_changed(old_state, new_state)
signal level_started(level_id: String)
signal level_completed(level_id: String)
signal level_failed(level_id: String, reason: String)
signal game_paused
signal game_resumed
signal game_saved(slot: int)
signal game_loaded(slot: int)

# UI事件
signal ui_menu_opened(menu_name: String)
signal ui_menu_closed(menu_name: String)
signal ui_dialogue_started(speaker: String, text: String)
signal ui_dialogue_ended(speaker: String)
signal ui_choice_made(choice_id: String, choice_index: int)

# 机关事件
signal door_opened(door_id: String)
signal door_closed(door_id: String)
signal switch_activated(switch_id: String)
signal portal_used(portal_id: String, destination: Vector2)
signal pressure_plate_activated(plate_id: String)
signal pressure_plate_deactivated(plate_id: String)

# 敌人事件
signal enemy_spawned(enemy_type: String, position: Vector2)
signal enemy_died(enemy_type: String, position: Vector2)
signal enemy_hurt(enemy_type: String, damage: int)
signal boss_phase_changed(boss_id: String, phase: int)

# 调试事件
signal debug_message(message: String, level: int)
signal debug_warning(message: String)
signal debug_error(message: String)

static var instance: Node

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	print("EventBus 已加载")
