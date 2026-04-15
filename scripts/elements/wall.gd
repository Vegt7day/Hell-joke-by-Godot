extends Mechanism
class_name Wall

# 导出变量
@export var is_destructible: bool = false
@export var health: int = 3
@export var grid_size: int = 32
@export var color: Color = Color.RED

func _ready():
	"""初始化墙"""
	print("墙初始化: %s" % name)
	
	# 设置碰撞层
	set_collision_layer_value(4, true)  # 第3层：墙壁
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
	
	print("墙初始化完成: %s, 碰撞层: %d, 碰撞掩码: %d" % [name, collision_layer, collision_mask])

func take_damage(damage: int, attacker: Node2D = null):
	"""墙受到伤害"""
	if is_destructible:
		health -= damage
		print("墙受到伤害: %d, 剩余生命: %d" % [damage, health])
		
		if health <= 0:
			destroy(attacker)

func destroy(attacker: Node2D = null):
	"""销毁墙"""
	print("墙被摧毁: %s" % name)
	
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
