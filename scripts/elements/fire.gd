extends Mechanism
class_name FireTrap

@export var damage: int = 1
@export var damage_interval: float = 0.5
@export var is_permanent: bool = true

var players_in_trap: Array = []
var damage_timers: Dictionary = {}  # 玩家ID -> 计时器

func _ready():
	mechanism_type = "fire"
	text = "火"
	text_color = Color(1.0, 0.5, 0.0)  # 橙色
	can_be_triggered = false  # 火不能被触发，只能触发别人
	
	super._ready()
	
	# 开始闪烁动画
	start_flicker_animation()

func _process(delta):
	"""处理伤害"""
	for player in players_in_trap:
		if player and player.is_inside_tree():
			deal_damage_to_player(player)

func on_player_entered(player: Node2D):
	"""玩家进入火中"""
	if player not in players_in_trap:
		print("玩家进入火陷阱")
		players_in_trap.append(player)
		
		# 立即造成一次伤害
		deal_damage_to_player(player)
		
		# 开始持续伤害计时器
		start_damage_timer(player)

func on_player_exited(player: Node2D):
	"""玩家离开火"""
	if player in players_in_trap:
		print("玩家离开火陷阱")
		players_in_trap.erase(player)
		
		# 停止伤害计时器
		stop_damage_timer(player)

func deal_damage_to_player(player: Node2D):
	"""对玩家造成伤害"""
	if player and player.has_method("take_damage"):
		print("火陷阱造成 %d 点伤害" % damage)
		player.take_damage(damage, "fire")
		
		# 播放伤害效果
		play_damage_effect()

func play_damage_effect():
	"""播放伤害效果"""
	if anim_player and anim_player.has_animation("damage"):
		anim_player.play("damage")
	else:
		# 简单的闪烁
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate", Color.RED, 0.1)
		tween.tween_property(label, "modulate", text_color, 0.1)

func start_damage_timer(player: Node2D):
	"""开始持续伤害计时器"""
	var timer = get_tree().create_timer(damage_interval)
	timer.timeout.connect(_on_damage_timer_timeout.bind(player))
	
	if not player in damage_timers:
		damage_timers[player] = []
	damage_timers[player].append(timer)

func stop_damage_timer(player: Node2D):
	"""停止伤害计时器"""
	if player in damage_timers:
		for timer in damage_timers[player]:
			if timer and not timer.is_stopped():
				timer.stop()
		damage_timers.erase(player)

func _on_damage_timer_timeout(player: Node2D):
	"""伤害计时器超时"""
	if player in players_in_trap:
		deal_damage_to_player(player)
		# 重新开始计时器
		start_damage_timer(player)

func start_flicker_animation():
	"""开始火焰闪烁动画"""
	if anim_player and anim_player.has_animation("flicker"):
		anim_player.play("flicker")
	else:
		# 程序化闪烁
		var tween = get_tree().create_tween().set_loops()
		tween.tween_property(label, "modulate", Color(1.0, 0.8, 0.0, 0.8), 0.3)
		tween.tween_property(label, "modulate", text_color, 0.3)

func _exit_tree():
	"""清理"""
	for player in players_in_trap:
		stop_damage_timer(player)
	players_in_trap.clear()
