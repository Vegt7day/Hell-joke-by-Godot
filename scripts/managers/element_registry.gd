extends Node
class_name ElementRegistry

# 单例实例
static var instance: ElementRegistry

# 元素场景映射
var element_scenes: Dictionary = {}
var mechanism_scenes: Dictionary = {}

# 颜色映射
var color_mapping: Dictionary = {
	"red": Color.RED,
	"green": Color.GREEN,
	"blue": Color.BLUE,
	"yellow": Color.YELLOW,
	"purple": Color.PURPLE,
	"cyan": Color.CYAN,
	"white": Color.WHITE,
	"black": Color.BLACK
}

# 中文颜色映射
var chinese_color_mapping: Dictionary = {
	"红": "red",
	"绿": "green", 
	"蓝": "blue",
	"黄": "yellow",
	"紫": "purple",
	"青": "cyan",
	"白": "white",
	"黑": "black"
}

func _ready():
	"""初始化注册表"""
	if not instance:
		instance = self
		print("元素注册表初始化")
		load_all_elements()
	else:
		queue_free()

func load_all_elements():
	"""加载所有元素"""
	print("加载元素场景...")
	
	# 加载墙/地元素
	load_elements_from_directory("res://scenes/elements/walls/", "wall")
	load_elements_from_directory("res://scenes/elements/platforms/", "platform")
	
	# 加载陷阱
	load_elements_from_directory("res://scenes/elements/traps/", "trap")
	
	# 加载目标
	load_elements_from_directory("res://scenes/elements/goals/", "goal")
	
	# 加载机关
	load_mechanisms_from_directory("res://scenes/elements/mechanisms/door/", "door")
	load_mechanisms_from_directory("res://scenes/elements/mechanisms/switch/", "switch")
	load_mechanisms_from_directory("res://scenes/elements/mechanisms/teleporter/", "teleporter")
	load_mechanisms_from_directory("res://scenes/elements/mechanisms/bow/", "bow")
	load_mechanisms_from_directory("res://scenes/elements/mechanisms/dirt/", "dirt")
	
	print("已加载元素:")
	print("  - 基础元素: %d 个" % element_scenes.size())
	print("  - 机关: %d 个" % mechanism_scenes.size())

func load_elements_from_directory(path: String, category: String):
	"""从目录加载元素场景"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var element_name = file_name.replace(".tscn", "")
				var scene_path = path + file_name
				var scene = load(scene_path)
				
				if scene:
					var key = "%s/%s" % [category, element_name]
					element_scenes[key] = scene
					print("    加载: %s -> %s" % [key, scene_path])
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("无法访问目录: %s" % path)

func load_mechanisms_from_directory(path: String, category: String):
	"""从目录加载机关场景"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var mechanism_name = file_name.replace(".tscn", "")
				var scene_path = path + file_name
				var scene = load(scene_path)
				
				if scene:
					var key = "%s/%s" % [category, mechanism_name]
					mechanism_scenes[key] = scene
					print("    加载: %s -> %s" % [key, scene_path])
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("无法访问目录: %s" % path)

func get_element_scene(element_type: String, element_name: String = "") -> PackedScene:
	"""获取元素场景"""
	var key = element_name != "" ? "%s/%s" % [element_type, element_name] : element_type
	
	if element_scenes.has(key):
		return element_scenes[key]
	elif mechanism_scenes.has(key):
		return mechanism_scenes[key]
	else:
		print("警告: 未找到元素场景: %s" % key)
		return null

func get_all_element_types() -> Array:
	"""获取所有元素类型"""
	var types = []
	
	for key in element_scenes.keys():
		var parts = key.split("/")
		if parts.size() >= 2 and not types.has(parts[0]):
			types.append(parts[0])
	
	for key in mechanism_scenes.keys():
		var parts = key.split("/")
		if parts.size() >= 2 and not types.has(parts[0]):
			types.append(parts[0])
	
	return types

func get_elements_by_type(element_type: String) -> Array:
	"""获取指定类型的元素"""
	var elements = []
	
	for key in element_scenes.keys():
		var parts = key.split("/")
		if parts.size() >= 2 and parts[0] == element_type:
			elements.append({
				"key": key,
				"name": parts[1],
				"scene": element_scenes[key]
			})
	
	for key in mechanism_scenes.keys():
		var parts = key.split("/")
		if parts.size() >= 2 and parts[0] == element_type:
			elements.append({
				"key": key,
				"name": parts[1],
				"scene": mechanism_scenes[key]
			})
	
	return elements

func get_color_from_name(color_name: String) -> Color:
	"""从名称获取颜色"""
	if chinese_color_mapping.has(color_name):
		var english_name = chinese_color_mapping[color_name]
		if color_mapping.has(english_name):
			return color_mapping[english_name]
	
	# 默认返回白色
	return Color.WHITE

func get_color_names() -> Array:
	"""获取所有颜色名称"""
	return chinese_color_mapping.keys()

func get_opposite_color(color_name: String) -> String:
	"""获取相反颜色（用于颜色配对）"""
	var opposite_map = {
		"红": "绿",
		"绿": "红",
		"蓝": "黄",
		"黄": "蓝",
		"紫": "青",
		"青": "紫"
	}
	
	return opposite_map.get(color_name, "白")

func get_random_color() -> String:
	"""获取随机颜色"""
	var keys = chinese_color_mapping.keys()
	return keys[randi() % keys.size()]

func get_complementary_colors(color_name: String) -> Array:
	"""获取互补颜色"""
	var complementary = {
		"红": ["绿", "蓝"],
		"绿": ["红", "紫"],
		"蓝": ["黄", "红"],
		"黄": ["蓝", "紫"],
		"紫": ["青", "绿"],
		"青": ["紫", "黄"]
	}
	
	return complementary.get(color_name, ["白", "黑"])

func create_element(element_type: String, element_name: String = "", 
				   position: Vector2 = Vector2.ZERO, 
				   properties: Dictionary = {}) -> Node2D:
	"""创建元素实例"""
	var scene = get_element_scene(element_type, element_name)
	
	if scene:
		var instance = scene.instantiate()
		
		# 设置位置
		instance.position = position
		
		# 设置属性
		apply_properties(instance, properties)
		
		return instance
	
	return null

func apply_properties(instance: Node2D, properties: Dictionary):
	"""应用属性到实例"""
	for key in properties.keys():
		if instance.has_method("set_" + key):
			instance.call("set_" + key, properties[key])
		elif instance.has_property(key):
			instance.set(key, properties[key])
		elif key == "text":
			if instance.has_property("text"):
				instance.set("text", properties[key])
		elif key == "color" or key == "mechanism_color":
			var color_name = properties[key]
			var color_value = get_color_from_name(color_name)
			
			if instance.has_method("set_color"):
				instance.call("set_color", color_value)
			elif instance.has_method("apply_color_scheme"):
				instance.call("apply_color_scheme", color_name)
			elif instance.has_property("modulate"):
				instance.set("modulate", color_value)
		elif key == "size":
			if instance is RectElement:
				var size = properties[key]
				if size is Vector2:
					instance.grid_width = int(size.x)
					instance.grid_height = int(size.y)
				elif size is Array and size.size() >= 2:
					instance.grid_width = int(size[0])
					instance.grid_height = int(size[1])

func get_element_info(element_type: String, element_name: String = "") -> Dictionary:
	"""获取元素信息"""
	var key = element_name != "" ? "%s/%s" % [element_type, element_name] : element_type
	var scene = get_element_scene(element_type, element_name)
	
	if not scene:
		return {}
	
	# 创建临时实例来获取信息
	var instance = scene.instantiate()
	var info = {
		"type": element_type,
		"name": element_name,
		"path": scene.resource_path
	}
	
	# 获取基础属性
	if instance.has_method("get_mechanism_data"):
		info["data"] = instance.call("get_mechanism_data")
	elif instance is RectElement:
		info["data"] = {
			"grid_width": instance.grid_width,
			"grid_height": instance.grid_height,
			"text": instance.text
		}
	
	instance.queue_free()
	return info

func validate_element_placement(level_data: Dictionary, position: Vector2, 
							   width: int = 1, height: int = 1) -> bool:
	"""验证元素放置位置是否有效"""
	for x in range(width):
		for y in range(height):
			var key = "%d,%d" % [position.x + x, position.y + y]
			if level_data.has(key):
				return false
	return true

func get_element_at_position(level_data: Dictionary, position: Vector2) -> Dictionary:
	"""获取位置上的元素"""
	var key = "%d,%d" % [position.x, position.y]
	return level_data.get(key, {})

func remove_element_at_position(level_data: Dictionary, position: Vector2) -> bool:

	var key = "%d,%d" % [position.x, position.y]
	if level_data.has(key):
		level_data.erase(key)
		return true
	return false

func get_element_grid_size(element_type: String, element_name: String = "") -> Vector2:

	var info = get_element_info(element_type, element_name)
	if info.has("data"):
		var data = info["data"]
		if data.has("grid_width") and data.has("grid_height"):
			return Vector2(data["grid_width"], data["grid_height"])
	
	return Vector2.ONE

func get_compatible_elements(required_type: String) -> Array:

	var compatible = []
	
	match required_type:
		"switch":
			# 开关可以连接门
			compatible = get_elements_by_type("door")
		
		"door":
			# 门可以连接开关
			compatible = get_elements_by_type("switch")
		
		"teleporter_in":
			# 传送入口可以连接出口
			compatible = get_elements_by_type("teleporter_out")
		
		"teleporter_out":
			# 传送出口可以连接入口
			compatible = get_elements_by_type("teleporter_in")
		
		"bow":
			# 弓可以发射箭
			compatible = get_elements_by_type("arrow")
	
	return compatible

func is_mechanism(element_type: String) -> bool:
  
	var mechanism_types = ["switch", "door", "teleporter", "bow", "dirt", "fire", "goal"]
	return mechanism_types.has(element_type)

func is_blocking(element: Node2D) -> bool:

	if element is RectElement:
		return element.has_collision
	elif element is Mechanism:
		var mech_type = element.mechanism_type
		if mech_type == "door":
			return not element.is_active
		return false
	return false

func is_damaging(element: Node2D) -> bool:

	if element is Mechanism:
		var mech_type = element.mechanism_type
		return mech_type == "fire"
	return false

func is_interactive(element: Node2D) -> bool:

	if element is Mechanism:
		var mech_type = element.mechanism_type
		return mech_type in ["switch", "door", "bow", "dirt"]
	return false

func save_registry_data() -> Dictionary:

	var data = {
		"version": "1.0",
		"elements": {},
		"mechanisms": {}
	}
	
	for key in element_scenes:
		data["elements"][key] = element_scenes[key].resource_path
	
	for key in mechanism_scenes:
		data["mechanisms"][key] = mechanism_scenes[key].resource_path
	
	return data

func load_registry_data(data: Dictionary) -> bool:

	if not data.has("version") or data["version"] != "1.0":
		print("版本不匹配")
		return false
	
	# 清空当前注册表
	element_scenes.clear()
	mechanism_scenes.clear()
	
	# 加载元素
	for key in data.get("elements", {}):
		var path = data["elements"][key]
		var scene = load(path)
		if scene:
			element_scenes[key] = scene
	
	# 加载机关
	for key in data.get("mechanisms", {}):
		var path = data["mechanisms"][key]
		var scene = load(path)
		if scene:
			mechanism_scenes[key] = scene
	
	print("注册表数据加载完成")
	return true
