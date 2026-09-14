extends Node

## json 数据文件存放目录，注意要以 / 结尾
@export var configJsonPath: StringName = &"res://Assets/DataTables/"

var config: Schema.CfgTables

func _ready():
	config = Schema.CfgTables.new(loadFile)


func loadFile(fileName: String):
	var jsonFile = FileAccess.open("%s%s.json" % [self.configJsonPath, fileName], FileAccess.READ)
	var jsonText = jsonFile.get_as_text()
	jsonFile.close()
	return JSON.parse_string(jsonText)
