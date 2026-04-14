# 位置: projectiles/ink_projectile.gd
extends Area2D
class_name InkProjectile

var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var lifetime: float = 3.0
var is_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	set_active(false)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# 设置定时器自动销毁
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_end)
	
	print("墨弹初始化完成")

func setup_ink(start_position: Vector2, move_direction: Vector2, owner: Node, params: Dictionary = {}):
	"""设置墨弹"""
	print("设置墨弹")
	
	position = start_position
	direction = move_direction.normalized()
	
	# 应用参数
	if "speed" in params:
		speed = params.speed
	if "damage" in params:
		damage = params.damage
	if "lifetime" in params:
		lifetime = params.lifetime
		# 重新设置定时器
		var timer = get_tree().create_timer(lifetime)
		timer.timeout.connect(_on_lifetime_end)
	
	# 设置颜色
	if "ink_color" in params and sprite:
		sprite.modulate = params.ink_color
	
	set_active(true)
	print("墨弹设置完成: 位置=%s, 方向=%s" % [position, direction])
	return self

func _physics_process(delta: float):
	if not is_active:
		return
	
	# 移动
	position += direction * speed * delta

func _on_area_entered(area: Area2D):
	"""与区域碰撞"""
	if not is_active:
		return
	
	print("墨弹击中区域")
	destroy()

func _on_body_entered(body: PhysicsBody2D):
	"""与物理体碰撞"""
	if not is_active:
		return
	
	print("墨弹击中物体")
	
	# 造成伤害
	if body.has_method("take_damage"):
		body.take_damage(damage, "ink")
	
	destroy()

func _on_lifetime_end():
	"""生命周期结束"""
	if is_active:
		destroy()

func destroy():
	"""销毁墨弹"""
	print("销毁墨弹")
	is_active = false
	
	# 播放销毁动画
	if animation_player and animation_player.has_animation("destroy"):
		animation_player.play("destroy")
		await animation_player.animation_finished
	else:
		# 简单的淡出效果
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		await tween.finished
	
	queue_free()

func set_active(active: bool):
	"""设置活动状态"""
	is_active = active
	if collision_shape:
		collision_shape.disabled = not active
	visible = active
	set_physics_process(active)
