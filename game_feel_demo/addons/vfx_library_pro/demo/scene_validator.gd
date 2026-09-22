extends Node
## 商业版特效场景验证脚本
## 用于检查所有.tscn文件是否可以正常加载

func _ready() -> void:
    print("=== VFX Library Pro - 场景验证 ===")
    
    var scenes_to_test = [
        "res://addons/vfx_library_pro/effects_pro/button_ripple.tscn",
        "res://addons/vfx_library_pro/effects_pro/page_transition.tscn",
        "res://addons/vfx_library_pro/effects_pro/sword_slash.tscn",
        "res://addons/vfx_library_pro/effects_pro/explosion_wave.tscn",
        "res://addons/vfx_library_pro/effects_pro/energy_shield.tscn",
        "res://addons/vfx_library_pro/effects_pro/charging_effect.tscn",
        "res://addons/vfx_library_pro/effects_pro/critical_hit.tscn",
		"res://addons/vfx_library_pro/demo/demo_pro.tscn"
    ]
    
    var success_count = 0
    var fail_count = 0
    
    for scene_path in scenes_to_test:
        var result = _test_scene(scene_path)
        if result:
            success_count += 1
        else:
            fail_count += 1
    
    print("\n=== 验证结果 ===")
    print("✅ 成功: %d" % success_count)
    print("❌ 失败: %d" % fail_count)
    print("总计: %d" % scenes_to_test.size())
    
    if fail_count == 0:
        print("\n🎉 所有场景验证通过!")
    else:
        print("\n⚠️ 有场景加载失败，请检查错误信息")


func _test_scene(scene_path: String) -> bool:
    print("\n测试: %s" % scene_path)
    
    if not FileAccess.file_exists(scene_path):
        print("  ❌ 文件不存在")
        return false
    
    var scene = load(scene_path)
    if scene == null:
        print("  ❌ 加载失败")
        return false
    
    var instance = scene.instantiate()
    if instance == null:
        print("  ❌ 实例化失败")
        return false
    
    print("  ✅ 加载成功")
    instance.queue_free()
    return true
