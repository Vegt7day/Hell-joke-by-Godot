
extends Mechanism
class_name Switch

@export var door_color: String = ""  # 控制门的颜色
@export var is_toggle: bool = true  # 是否切换
@export var is_pressure_plate: bool = false  # 是否是压力板
@export var require_stay: bool = false  # 是否需要持续压住

var is_pressed: bool = false
var linked_doors: Array = []
var pressure_objects: Array = []  # 压在压力板上的物体

func _ready():
	mechanism_type = "switch"
	text = "开"
	apply_color_scheme(door_color)
	
	super._ready()
	
	# 如果是压力板，设置不同
	if is_pressure_plate:
		setup_pressure_plate()

func setup_pressure_plate():
	"""设置为压力板"""
	# 压力板需要持续检测
	set_monitoring(true)
	set_monitorable(true)
	
	# 改变文字
	text = "压"
	
	print("设置压力板: %s" % door_color)

func on_bullet_hit(bullet: Node2D):
	"""被子弹击中"""
	if not is_pressure_plate:
		super.on_bullet_hit(bullet)
		# 切换状态
		if is_toggle:
			toggle_doors()

func on_dust_hit(dust: Node2D):
	"""被灰尘击中"""
	if not is_pressure_plate:
		super.on_dust_hit(dust)
		# 切换状态
		if is_toggle:
			toggle_doors()

func on_body_entered(body: Node2D):
	"""物体进入（用于压力板）"""
	if is_pressure_plate and (body.is_in_group("player") or body.is_in_group("enemy")):
		if body not in pressure_objects:
			pressure_objects.append(body)
			update_pressure_state()

func on_body_exited(body: Node2D):
	"""物体离开（用于压力板）"""
	if is_pressure_plate and body in pressure_objects:
		pressure_objects.erase(body)
		update_pressure_state()

func update_pressure_state():
	"""更新压力板状态"""
	var was_pressed = is_pressed
	is_pressed = pressure_objects.size() > 0
	
	if is_pressed != was_pressed:
		if is_pressed:
			press_switch()
		else:
			release_switch()

func press_switch():
	"""按下开关"""
	print("压力板被按下")
	is_triggered = true
	play_press_effect()
	
	# 触发门
	if not require_stay:
		toggle_doors()
	else:
		# 需要持续压住
		for door in linked_doors:
			if door and door.has_method("open"):
				door.open(self)

func release_switch():
	"""释放开关"""
	print("压力板被释放")
	is_triggered = false
	play_release_effect()
	
	if require_stay:
		# 如果要求持续压住，释放时关门
		for door in linked_doors:
			if door and door.has_method("close"):
				door.close(self)

func play_press_effect():
	"""播放按下效果"""
	if anim_player and anim_player.has_animation("press"):
		anim_player.play("press")
	else:
		# 下沉效果
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position:y", position.y + 2, 0.1)
		label.modulate = Color(0.5, 0.5, 0.5)

func play_release_effect():
	"""播放释放效果"""
	if anim_player and anim_player.has_animation("release"):
		anim_player.play("release")
	else:
		# 恢复效果
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position:y", position.y - 2, 0.1)
		label.modulate = text_color

func toggle_doors():
	"""切换门的状态"""
	print("切换门状态: %s" % door_color)
	
	for door in linked_doors:
		if door and door.has_method("toggle"):
			door.toggle(self)
	
	mechanism_triggered.emit(self, null)

func link_door(door: Node2D):
	"""连接门"""
	if door and door not in linked_doors:
		linked_doors.append(door)
		print("开关连接到门: %s" % door.name)

func unlink_door(door: Node2D):
	"""断开门连接"""
	if door in linked_doors:
		linked_doors.erase(door)
		print("开关断开连接: %s" % door.name)

func get_switch_data() -> Dictionary:
	"""获取开关数据"""
	var data = get_mechanism_data()
	data["door_color"] = door_color
	data["is_pressed"] = is_pressed
	data["linked_doors_count"] = linked_doors.size()
	return data
