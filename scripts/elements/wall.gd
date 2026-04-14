extends RectElement
class_name WallElement

func _ready():
	element_type = "wall"
	text = "墙"
	text_color = Color(0.8, 0.8, 0.8)  # 灰色
	
	# 墙的配置
	has_collision = true
	is_destructible = false
	
	# 设置碰撞层
	collision_layer = 1 << 1  # 第2层：障碍
	collision_mask = (1 << 0) | (1 << 3)  # 第1层：玩家，第4层：子弹
	
	super._ready()

func on_bullet_hit(bullet: Node2D):
	"""墙被子弹击中"""
	print("墙被子弹击中")
	
	# 播放受击效果
	play_hit_effect()
	
	# 墙不可破坏，但可以播放效果
	if bullet and bullet.has_method("on_hit"):
		bullet.on_hit(self)
