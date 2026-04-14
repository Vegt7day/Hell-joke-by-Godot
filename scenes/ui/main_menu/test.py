import os
import xml.etree.ElementTree as ET

def check_scene_structure():
    scene_path = "main_menu.tscn"
    
    if not os.path.exists(scene_path):
        print(f"场景文件不存在: {scene_path}")
        return
    
    with open(scene_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f"场景文件大小: {len(content)} 字节")
    print(f"前100个字符: {content[:100]}")
    
    # 检查是否包含关键节点
    if "MenuContainer" in content:
        print("✓ 场景包含 MenuContainer")
    else:
        print("✗ 场景不包含 MenuContainer")
    
    if "NewGameButton" in content:
        print("✓ 场景包含 NewGameButton")
    else:
        print("✗ 场景不包含 NewGameButton")
    
    # 尝试解析XML
    try:
        if content.strip().startswith("<?xml"):
            root = ET.fromstring(content)
            print("✓ 场景是有效的XML格式")
        elif content.strip().startswith("[gd_scene"):
            print("✓ 场景是文本格式")
        else:
            print("✗ 未知场景格式")
    except Exception as e:
        print(f"✗ 解析场景时出错: {e}")

if __name__ == "__main__":
    check_scene_structure()