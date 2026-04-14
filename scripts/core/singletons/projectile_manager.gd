# 位置: scripts/core/singletons/projectile_manager.gd
extends Node
# 注意：不定义 class_name，让AutoLoad处理

# 预制体引用
var projectile_prefabs: Dictionary = {
	"shoe": "res://scripts/core/projectiles/shoe_projectile.tscn",
	"ink": "res://scripts/core/projectiles/ink_projectile.tscn"
}

func _ready():
	print("抛射体管理器初始化完成")

func spawn_projectile(projectile_type: String, position: Vector2, direction: Vector2, owner: Node, params: Dictionary = {}):
	"""生成抛射体"""
	print("生成抛射体: 类型=%s, 位置=%s" % [projectile_type, position])
	
	# 检查预制体是否存在
	if projectile_type not in projectile_prefabs:
		print("错误: 未知的抛射体类型: %s" % projectile_type)
		return null
	
	var prefab_path = projectile_prefabs[projectile_type]
	if not ResourceLoader.exists(prefab_path):
		print("错误: 预制体不存在: %s" % prefab_path)
		return null
	
	# 加载预制体
	var prefab = load(prefab_path)
	if not prefab:
		print("错误: 无法加载预制体: %s" % prefab_path)
		return null
	
	# 实例化
	var projectile = prefab.instantiate()
	if not projectile:
		print("错误: 无法实例化抛射体")
		return null
	
	# 添加到场景
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(projectile)
	else:
		print("错误: 没有当前场景")
		return null
	
	# 设置位置
	projectile.global_position = position
	
	# 根据类型调用设置方法
	if projectile_type == "ink" and projectile.has_method("setup_ink"):
		projectile.setup_ink(position, direction, owner, params)
	elif projectile_type == "shoe" and projectile.has_method("setup_shoe"):
		var shoe_name = params.get("shoe_name", "shoe")
		projectile.setup_shoe(position, direction, owner, shoe_name, params)
	elif projectile.has_method("setup"):
		projectile.setup(position, direction, owner, params)
	
	print("✓ 抛射体生成成功: %s" % projectile_type)
	return projectile
