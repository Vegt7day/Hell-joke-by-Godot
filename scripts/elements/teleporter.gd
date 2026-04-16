extends Mechanism
class_name Teleporter

# 导出变量 - 在场景中设置
@export var is_entrance: bool = false  # true="传", false="送"
@export var color: String = ""  # 颜色名称，用于配对
@export var paired_teleporter_path: NodePath  # 配对的传送门路径

# 内部变量
var label_node: Label
var area_node: Area2D
var sprite_node: Sprite2D
var paired_target: Teleporter = null
var teleport_cooldown: float = 1.0
var last_teleport_time: float = 0.0

# 信号
signal teleporter_activated(teleporter: Teleporter)
signal teleporter_deactivated(teleporter: Teleporter)
signal teleporter_state_changed(is_entrance: bool)
signal entity_teleported(entity: Node2D, from: Teleporter, to: Teleporter)

func _ready():
    """初始化传送门"""
    # 调用基类初始化
    super._ready()
    
    # 设置机制类型
    mechanism_type = "teleporter"
    mechanism_color = color
    add_to_group("teleporters")
    # 获取节点引用
    initialize_nodes()
    
    # 设置初始文本	
    update_teleporter_label()
    
    # 应用颜色
    apply_color_to_label()
    
    # 连接信号	
    connect_area_signals()
    
    print("传送门初始化完成: %s, 颜色: %s, 状态: %s" % [
        name, color, ("传" if is_entrance else "送")
    ])

func initialize_nodes():
    """初始化所有需要的节点引用"""
    # 获取Label节点
    label_node = get_node("label") as Label
    if not label_node:
        print("警告: 无法找到label节点")
    
    # 获取Area2D节点（假设名为"Area2D"或自动查找）
    find_area_node()
    
    # 获取Sprite2D节点用于视觉效果
    find_sprite_node()

func find_area_node():
    """查找Area2D节点"""
    # 尝试常见名称
    var area_names = ["Area2D", "TeleportArea", "CollisionArea"]
    for area_name in area_names:
        if has_node(area_name):
            area_node = get_node(area_name) as Area2D
            if area_node:
                return
    
    # 如果没找到，创建并添加一个
    print("未找到Area2D节点，正在创建...")
    area_node = Area2D.new()
    area_node.name = "TeleportArea"
    
    # 添加碰撞形状
    var collision_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(32, 32)  # 默认大小
    collision_shape.shape = shape
    
    area_node.add_child(collision_shape)
    add_child(area_node)
    
    print("已创建Area2D节点")

func find_sprite_node():
    """查找Sprite2D节点"""
    # 尝试常见名称
    var sprite_names = ["Sprite2D", "sprite", "Sprite"]
    for sprite_name in sprite_names:
        if has_node(sprite_name):
            sprite_node = get_node(sprite_name) as Sprite2D
            if sprite_node:
                return
    
    # 如果没找到，查找任意Sprite2D子节点
    for child in get_children():
        if child is Sprite2D:
            sprite_node = child
            return
    
    print("未找到Sprite2D节点")

func connect_area_signals():
    """连接Area2D的信号"""
    if area_node:
        if not area_node.body_entered.is_connected(_on_body_entered):
            area_node.body_entered.connect(_on_body_entered)
        print("已连接Area2D信号")
    else:
        print("警告: Area2D节点未找到，无法连接信号")

func update_teleporter_label():
    """更新传送门标签文字"""
    if label_node:
        if is_entrance:
            label_node.text = "传"
        else:
            label_node.text = "送"
        print("传送门 %s 标签更新为: %s" % [name, label_node.text])

func apply_color_to_label():
    """根据颜色设置标签颜色"""
    if label_node and color:
        var color_map = {
            "红": Color.RED,
            "橙": Color(1, 0.5, 0),
            "黄": Color.YELLOW,
            "绿": Color.GREEN,
            "青": Color.CYAN,
            "蓝": Color.BLUE,
            "紫": Color.PURPLE,
            "白": Color.WHITE,
            "灰": Color(0.5, 0.5, 0.5),
            "黑": Color.BLACK
        }
        
        if color_map.has(color):
            label_node.modulate = color_map[color]
            print("传送门 %s 标签颜色设置为: %s" % [name, color])
        else:
            label_node.modulate = Color.WHITE
            print("传送门 %s 颜色未匹配，使用白色" % [name])

func set_teleporter_color(new_color: String):
    """设置传送门颜色"""
    color = new_color
    mechanism_color = new_color
    
    # 更新标签颜色
    apply_color_to_label()
    
    print("传送门 %s 颜色已设置为: %s" % [name, new_color])

func toggle_entrance_state():
    """切换传送门状态（传↔送）"""
    is_entrance = not is_entrance
    
    # 更新标签
    update_teleporter_label()
    
    # 播放切换动画
    play_state_change_animation()
    
    # 发射状态变化信号
    teleporter_state_changed.emit(is_entrance)
    
    print("传送门 %s 状态切换为: %s" % [name, ("传" if is_entrance else "送")])

func play_state_change_animation():
    """播放状态切换动画"""
    if label_node:
        var tween = create_tween()
        
        # 缩放效果
        tween.tween_property(label_node, "scale", Vector2(1.3, 1.3), 0.1)
        tween.tween_property(label_node, "scale", Vector2(1.0, 1.0), 0.1)
        
        # 旋转效果
        tween.parallel().tween_property(label_node, "rotation", PI * 2, 0.2)
        
        # 恢复旋转
        tween.tween_property(label_node, "rotation", 0, 0)
    
    if sprite_node:
        var tween = create_tween()
        tween.tween_property(sprite_node, "modulate", Color(1, 1, 0.5, 1), 0.1)
        tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)

func set_paired_target(target_teleporter: Teleporter):
    """设置配对的传送门"""
    if target_teleporter == self:
        print("错误: 不能与自己配对")
        return
    
    paired_target = target_teleporter
    print("传送门 %s 已与 %s 配对" % [name, target_teleporter.name])

func clear_paired_target():
    """清除配对"""
    if paired_target:
        print("传送门 %s 与 %s 断开配对" % [name, paired_target.name])
        paired_target = null

func validate_pairing() -> bool:
    """验证配对是否有效"""
    if not paired_target:
        print("警告: 传送门 %s 没有配对目标" % name)
        return false
    
    if not is_instance_valid(paired_target):
        print("错误: 传送门 %s 的配对目标已失效" % name)
        clear_paired_target()
        return false
    
    if paired_target.color != color:
        print("警告: 传送门 %s 与 %s 颜色不匹配" % [name, paired_target.name])
        return false
    
    return true

func _on_body_entered(body: Node2D):
    """有实体进入传送门区域"""
    if not is_active:
        return
    
    if not is_entrance:
        # 只有"传"门能传送
        return
    
    if not validate_pairing():
        print("传送门 %s 配对无效，无法传送" % name)
        return
    
    # 冷却时间检查
    var current_time = Time.get_ticks_msec() / 1000.0
    if current_time - last_teleport_time < teleport_cooldown:
        return
    
    # 检查实体是否可以传送
    if can_teleport_entity(body):
        teleport_entity_to_target(body)
    else:
        print("实体 %s 无法被传送" % body.name)

func can_teleport_entity(entity: Node2D) -> bool:
    """检查实体是否可以被传送"""
    # 检查实体类型
    if entity is CharacterBody2D or entity is RigidBody2D or entity is Area2D:
        return true
    
    # 检查是否有"player"或"student"标签
    if "player" in entity.name.to_lower() or "student" in entity.name.to_lower():
        return true
    
    return false

func teleport_entity_to_target(entity: Node2D):
    """将实体传送到目标位置"""
    if not paired_target:
        print("错误: 没有配对目标")
        return
    
    # 记录传送时间
    last_teleport_time = Time.get_ticks_msec() / 1000.0
    
    # 播放传送开始特效
    play_teleport_start_effect()
    
    # 延迟传送，让特效有时间播放
    await get_tree().create_timer(0.1).timeout
    
    # 保存实体状态
    var original_position = entity.global_position
    var original_velocity = Vector2.ZERO
    if entity is CharacterBody2D:
        original_velocity = entity.velocity
    
    # 计算目标位置
    var target_position = paired_target.global_position
    
    # 传送实体
    entity.global_position = target_position
    
    # 播放传送结束特效
    paired_target.play_teleport_end_effect()
    
    # 发射信号
    entity_teleported.emit(entity, self, paired_target)
    
    print("传送完成: %s 从 %s 传送到 %s" % [
        entity.name, 
        original_position, 
        target_position
    ])

func play_teleport_start_effect():
    """播放传送开始特效"""
    if sprite_node:
        var tween = create_tween()
        tween.tween_property(sprite_node, "modulate:a", 0.3, 0.1)
    
    if label_node:
        var tween = create_tween()
        tween.tween_property(label_node, "modulate:a", 0.3, 0.1)
    
    # 可以添加粒子效果
    # spawn_particles_at_position(global_position, Color.CYAN)

func play_teleport_end_effect():
    """播放传送结束特效"""
    if sprite_node:
        var tween = create_tween()
        tween.tween_property(sprite_node, "modulate:a", 1.0, 0.2)
    
    if label_node:
        var tween = create_tween()
        tween.tween_property(label_node, "modulate:a", 1.0, 0.2)
    
    # 闪烁效果
    if label_node:
        var tween = create_tween()
        tween.tween_property(label_node, "scale", Vector2(1.2, 1.2), 0.1)
        tween.tween_property(label_node, "scale", Vector2(1.0, 1.0), 0.1)

func spawn_particles_at_position(position: Vector2, color: Color):
    """在指定位置生成粒子效果"""
    # 创建粒子节点
    var particles = GPUParticles2D.new()
    particles.process_material = ParticleProcessMaterial.new()
    particles.process_material.color = color
    particles.amount = 20
    particles.lifetime = 0.5
    particles.emitting = true
    
    particles.position = position
    get_parent().add_child(particles)
    
    # 自动清理
    particles.finished.connect(particles.queue_free)

func activate_teleporter():
    """激活传送门"""
    is_active = true
    teleporter_activated.emit(self)
    
    if label_node:
        label_node.modulate.a = 1.0
    
    print("传送门 %s 已激活" % name)

func deactivate_teleporter():
    """停用传送门"""
    is_active = false
    teleporter_deactivated.emit(self)
    
    if label_node:
        label_node.modulate.a = 0.5
    
    print("传送门 %s 已停用" % name)

func get_teleporter_save_data() -> Dictionary:
    """获取传送门保存数据"""
    var data = get_mechanism_data()
    
    data["is_entrance"] = is_entrance
    data["color"] = color
    data["is_active"] = is_active
    
    # 保存配对信息（如果存在）
    if paired_target and is_instance_valid(paired_target):
        data["paired_target_name"] = paired_target.name
    else:
        data["paired_target_name"] = ""
    
    return data

func load_teleporter_data(data: Dictionary):
    """加载传送门数据"""
    if "is_entrance" in data:
        is_entrance = data["is_entrance"]
    
    if "color" in data:
        color = data["color"]
    
    if "is_active" in data:
        is_active = data["is_active"]
    
    # 更新显示
    update_teleporter_label()
    apply_color_to_label()
    
    if is_active:
        activate_teleporter()
    else:
        deactivate_teleporter()
    
    print("传送门 %s 数据加载完成" % name)
