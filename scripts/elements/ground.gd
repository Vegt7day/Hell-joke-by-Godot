extends Mechanism
class_name Ground

# 导出变量
@export var grid_size: int = 32
@export var color: Color = Color(0.8, 0.6, 0.4)  # 大地色
@export var is_slippery: bool = false  # 地面是否滑
@export var friction: float = 1.0  # 摩擦力系数
@export var bounce_factor: float = 0.0  # 弹跳系数

func _ready():
	"""初始化地面"""
	print("地面初始化: %s" % name)
	
	# 设置碰撞层
	set_collision_layer_value(2, true)  # 第2层：地面
	set_collision_mask_value(1, true)   # 与玩家（第1层）碰撞
	
	# 设置碰撞形状大小
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(grid_size, grid_size)
	
	# 设置Sprite
	var sprite = $Sprite2D
	if sprite:
		sprite.scale = Vector2(grid_size / 28.0, grid_size / 28.0)  # 调整缩放
		sprite.modulate = color
	
	print("地面初始化完成: %s, 碰撞层: %d, 碰撞掩码: %d" % [name, collision_layer, collision_mask])
	
	# 设置物理属性
	setup_physics_properties()

func setup_physics_properties():
	"""设置地面的物理属性"""
	# 如果是滑的地面，设置较低的摩擦
	if is_slippery:
		# 在Godot 4中，可以通过PhysicsMaterial设置
		if has_node("CollisionShape2D"):
			var collision = $CollisionShape2D
			# 创建物理材质
			var material = PhysicsMaterial.new()
			material.friction = 0.3
			material.bounce = bounce_factor
			collision.physics_material_override = material
			print("设置地面为滑面，摩擦系数: 0.3")

func on_player_entered(player: Node2D):
	"""玩家进入地面"""
	print("玩家进入地面: %s" % name)
	
	# 如果是滑的地面，通知玩家
	if is_slippery and player is CharacterBody2D:
		print("警告: 玩家进入滑面")

func on_player_exited(player: Node2D):
	"""玩家离开地面"""
	print("玩家离开地面: %s" % name)
	
	# 离开滑面
	if is_slippery and player is CharacterBody2D:
		print("玩家离开滑面")

# 地面可以接收子弹击中，但默认不处理
func take_damage(damage: int, attacker: Variant = null):
	"""地面受到伤害（可选，地面通常不可破坏）"""
	print("地面被攻击: %s, 伤害: %d, 攻击者: %s" % [name, damage, attacker])
	
	# 地面可以被设置为可破坏，但默认不破坏
	# 如果需要可破坏地面，可以添加相关逻辑
	# 例如：播放地面受击效果
	play_hit_effect()
func play_hit_effect():
	"""播放受击效果"""
	var sprite = $Sprite2D
	if sprite:
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite, "modulate", color, 0.2)
		print("地面受击效果播放")

func destroy(attacker: Node2D = null):
	"""销毁地面（可选，地面通常不可销毁）"""
	print("地面被销毁: %s" % name)
	
	# 只有当地面可被破坏时才执行销毁
	# 播放销毁动画
	if has_node("AnimationPlayer"):
		var anim_player = $AnimationPlayer
		anim_player.play("destroy")
		await anim_player.animation_finished
	else:
		# 简单的淡出效果
		var sprite = $Sprite2D
		if sprite:
			var tween = get_tree().create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
			await tween.finished
	
	queue_free()

# 保存数据
func get_element_data() -> Dictionary:
	"""获取地面数据（用于保存）"""
	var data = {
		"type": "ground",
		"position": {"x": position.x, "y": position.y},
		"name": name,
		"grid_size": grid_size,
		"color": {
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a
		},
		"is_slippery": is_slippery,
		"friction": friction,
		"bounce_factor": bounce_factor
	}
	return data
