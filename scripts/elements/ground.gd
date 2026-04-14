extends RectElement
class_name GroundElement

func _ready():
	element_type = "ground"
	text = "地"
	text_color = Color(0.6, 0.4, 0.2)  # 棕色
	
	# 地面的配置
	has_collision = true
	is_destructible = false
	
	# 设置碰撞层
	collision_layer = 1 << 1  # 第2层：地面
	collision_mask = 1 << 0  # 第1层：玩家
	
	super._ready()
