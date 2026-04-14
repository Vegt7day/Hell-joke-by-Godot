# check_ui_layers.gd
extends Node

func _ready():
	print("=== UI层级检查 ===")
	
	# 等待UI加载
	await get_tree().process_frame
	
	# 检查所有CanvasLayer
	check_canvas_layers()
	
	# 检查Control节点的鼠标过滤
	check_controls_mouse_filter(get_tree().root)
	
	print("\n=== 检查完成 ===")

func check_canvas_layers():
	print("\n1. CanvasLayer检查:")
	
	var canvas_layers = []
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			canvas_layers.append(child)
	
	if canvas_layers.size() == 0:
		print("  没有找到CanvasLayer")
		return
	
	canvas_layers.sort_custom(func(a, b): return a.layer > b.layer)
	
	for cl in canvas_layers:
		print("  - %s: 层级=%d, 子节点数=%d" % [cl.name, cl.layer, cl.get_child_count()])
		
		# 检查子节点是否可能拦截鼠标
		check_control_tree(cl, "    ")

func check_control_tree(node: Node, indent: String = ""):
	for child in node.get_children():
		if child is Control:
			print("%s%s (%s): 鼠标过滤=%s" % [
				indent, 
				child.name, 
				child.get_class(),
				child.mouse_filter
			])
			
			# 如果鼠标过滤是IGNORE，可能有问题
			if child.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				print("%s  ⚠ 此节点会忽略鼠标事件，可能拦截点击" % indent)
		
		# 递归检查子节点
		check_control_tree(child, indent + "  ")

func check_controls_mouse_filter(node: Node):
	for child in node.get_children():
		if child is Control:
			var mf = child.mouse_filter
			if mf == Control.MOUSE_FILTER_IGNORE:
				print("  ⚠ %s 设置了鼠标过滤=IGNORE" % child.get_path())
		check_controls_mouse_filter(child)
