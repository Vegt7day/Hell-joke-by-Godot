extends Mechanism
class_name Ground

func _ready():
	"""初始化地面"""
	mechanism_type = "ground"
	text = "地"
	text_color = Color(0.8, 0.6, 0.4)  # 大地色
	
	# 地面可以被踩踏，但不能被触发
	can_be_triggered = false
	is_active = true
	
	# 调用父类初始化
	super._ready()

func setup_collision():
	"""设置地面的碰撞"""
	# 地面应该有碰撞，让玩家可以站在上面
	if collision_shape and collision_shape.shape is RectangleShape2D:
		# 计算矩形大小（基于格子数）
		var actual_size = Vector2(grid_width * element_size, grid_height * element_size)
		collision_shape.shape.size = actual_size
		
		# 地面在障碍层，但允许玩家穿过
		set_collision_layer_value(2, true)  # 障碍层
		set_collision_mask_value(1, true)   # 玩家层
		
		print("地面碰撞大小: %s" % actual_size)

func on_player_entered(player: Node2D):
	"""玩家进入地面"""
	print("玩家进入地面: %s" % text)
	# 地面不需要特殊处理，只是让玩家可以站立

func on_player_exited(player: Node2D):
	"""玩家离开地面"""
	print("玩家离开地面: %s" % text)
	# 地面不需要特殊处理

# 地面不能被触发，所以重写触发方法为空
func trigger(triggerer: Node2D = null):
	pass

func on_bullet_hit(bullet: Node2D):
	"""子弹击中地面"""
	# 地面通常不会被子弹破坏
	pass

func on_dust_hit(dust: Node2D):
	"""灰尘击中地面"""
	# 地面不会被灰尘影响
	pass

# 保存数据
func get_element_data() -> Dictionary:
	"""获取地面数据（用于保存）"""
	var data = super.get_mechanism_data()
	data["type"] = "ground"
	data["grid_width"] = grid_width
	data["grid_height"] = grid_height
	return data
