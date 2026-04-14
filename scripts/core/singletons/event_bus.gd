extends Node
# 事件总线 - 用于组件间通信

# 自动加载单例
static var instance: EventBus

# === 玩家事件 ===
signal player_spawned(player_node)
signal player_died(cause: String)
signal player_hurt(damage: int, current_health: int)
signal player_healed(amount: int, current_health: int)
signal player_form_changed(old_form: String, new_form: String)
signal player_level_changed(level: int)
signal player_checkpoint_reached(checkpoint_id: String)

# === 物品事件 ===
# +++ 新增的鞋相关信号 +++
signal shoe_thrown(shoe_name: String, position: Vector2, owner_node: Node)
signal shoe_picked_up(shoe_name: String, position: Vector2, owner_node: Node)
signal shoe_landed(shoe_name: String, position: Vector2)
signal shoe_recovered(shoe_name: String, position: Vector2)
signal shoe_hit(shoe_name: String, position: Vector2, target_node: Node)
# +++ 新增的笔相关信号 +++
signal ink_shot(ink_amount: float, position: Vector2, direction: Vector2, owner_node: Node)
signal ink_hit(position: Vector2, target_node: Node)
# +++ 新增的物品通用信号 +++
signal item_picked_up(item_type: String, position: Vector2, player_node: Node)
signal item_used(item_type: String, position: Vector2, player_node: Node)

# === 游戏事件 ===
signal game_state_changed(old_state, new_state)
signal level_started(level_id: String)
signal level_completed(level_id: String)
signal level_failed(level_id: String, reason: String)
signal game_paused
signal game_resumed
signal game_saved(slot: int)
signal game_loaded(slot: int)

# === UI事件 ===
signal ui_menu_opened(menu_name: String)
signal ui_menu_closed(menu_name: String)
signal ui_dialogue_started(speaker: String, text: String)
signal ui_dialogue_ended(speaker: String)
signal ui_choice_made(choice_id: String, choice_index: int)

# === 机关事件 ===
signal door_opened(door_id: String)
signal door_closed(door_id: String)
signal switch_activated(switch_id: String)
signal portal_used(portal_id: String, destination: Vector2)
signal pressure_plate_activated(plate_id: String)
signal pressure_plate_deactivated(plate_id: String)

# === 敌人事件 ===
signal enemy_spawned(enemy_type: String, position: Vector2)
signal enemy_died(enemy_type: String, position: Vector2)
signal enemy_hurt(enemy_type: String, damage: int)
signal boss_phase_changed(boss_id: String, phase: int)

# === 投射体事件 ===
signal projectile_spawned(projectile_type: String, position: Vector2, direction: Vector2, owner_node: Node)
signal projectile_hit(projectile_type: String, position: Vector2, target_node: Node)
signal projectile_landed(projectile_type: String, position: Vector2)
signal projectile_destroyed(projectile_type: String, position: Vector2, reason: String)

# === 调试事件 ===
signal debug_message(message: String, level: int)
signal debug_warning(message: String)
signal debug_error(message: String)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
	
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	print("EventBus 已加载")
