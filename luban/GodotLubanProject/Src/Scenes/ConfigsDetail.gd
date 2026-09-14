extends Control


@onready var labelInfo1: Label = $MarginContainer/HBoxContainer/LabelInfo1
@onready var labelInfo2: Label = $MarginContainer/HBoxContainer/LabelInfo2

func _ready() -> void:
	var text = "基础示例表中所有记录：\n"
	# 显示所有记录
	for i in LubanLoader.config.tbExampleBasic.get_data_list():
		text += "%d %s %d\n" % [i.id, i.name, i.type]
	
	# 显示单条记录
	text += "\n根据id获取基础示例表中单条记录：\n"
	var item = LubanLoader.config.tbExampleBasic.get_item(1001)
	text += "%d %s %d\n" % [item.id, item.name, item.type]
	
	labelInfo1.text = text
	labelInfo2.text = text
