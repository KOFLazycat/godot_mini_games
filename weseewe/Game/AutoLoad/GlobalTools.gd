extends Node

@onready var splashAnimationPlayer: AnimationPlayer = $Splash/AnimationPlayer

var mainScene: String = "res://scenes/welcome.tscn"

#游戏状态
enum State {STATE_IDLE, STATE_START, STATE_OVER, STATE_HELP, STATE_NEWSCORE, STATE_PAUSE, STATE_RESUME, STATE_PASS, STATE_SCORE}
#方块状态
enum BlockState {FAST, SLOW, STOP, SLOWMOVE, SHAKE}
#玩家
enum PlayerState {IDLE, STAND, JUMP, DEAD}

var nextState: State = State.STATE_IDLE

@warning_ignore("unused_signal")
signal blockExit(pos: float)

var sound: bool = true	#声音开关

var blockColor: Array[String] = ['#a5aeb3', '#22bdd1', '#2a6aff', '#ffc827', '#00b264', '#5f6380', '#ff702a', '#fdfbc8', '#ff4352', '#ffa195']
var lineColor: Array[String] = ["#a5aeb3"]
var group: Dictionary[String, String] = {
	"colorDot" = "colorDot",
	"scoreDot" = "scoreDot"}
var words: Array[String] = ['hello world','debug!!!','say no']	
const FILE_NAME: String = "user://game-data.json"

#保存的数据
var data: Dictionary = {
	"best_round": 0,
	"last_round": 0,
	"rounds_played": 0,
	"avg_per_round":0,
	"colors_earned":0,
	"sound":true
}

	
func _ready() -> void:
	printFont()
	data = loadFile()


#更改场景
func changeScene(stagePath: String) -> void:
	splashAnimationPlayer.play("MoveIn")
	await splashAnimationPlayer.animation_finished
	set_process_input(false)
	get_tree().change_scene_to_file(stagePath)
	set_process_input(true)
	splashAnimationPlayer.play("MoveOut")


#保存数据
func save(_data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(FILE_NAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(_data))
	

#载入文件
func loadFile() -> Dictionary:
	var file: FileAccess = FileAccess.open(FILE_NAME, FileAccess.READ)
	if file != null:
		var content: String = file.get_as_text()
		return JSON.parse_string(content)
	else:
		save(data)  #保存数据
		return data


func addGamePlayNum() -> void:
	data['rounds_played']+=1
	save(data)


func recordGameData(colors_earned: int) -> void:
	data['rounds_played']+=1
	data['last_round']=colors_earned
	if data['best_round']<colors_earned:
		data['best_round']=colors_earned
	data['colors_earned']+=colors_earned
	var avg: float = float(data['colors_earned'])/data['rounds_played']
	data['avg_per_round']=avg
	save(data)

func printFont() -> void:
	print("""
 __    __    ___  _____   ___    ___ __    __    ___ 
|  |__|  |  /  _]/ ___/  /  _]  /  _]  |__|  |  /  _]
|  |  |  | /  [_(   \\_  /  [_  /  [_|  |  |  | /  [_ 
|  |  |  ||    _]\\__  ||    _]|    _]  |  |  ||    _]
|  `  '  ||   [_ /  \\ ||   [_ |   [_|  `  '  ||   [_ 
 \\      / |     |\\    ||     ||     |\\      / |     |
  \\_/\\_/  |_____| \\___||_____||_____| \\_/\\_/  |_____|
	""")
