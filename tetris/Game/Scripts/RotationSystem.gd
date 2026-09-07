## 旋转系统 - SRS (Super Rotation System)
## 实现俄罗斯方块的墙踢（Wall Kick）功能
## 当旋转可能导致方块越界或重叠时，通过预定义的测试点尝试将方块推回合法位置
class_name RotationSystem
extends Object

# 普通方块（J、L、S、T、Z）的墙踢偏移表
# 格式：key表示旋转方向转换（如"0_to_R"表示从0度转到90度）
# value是5个测试点的数组，按顺序尝试，每个点都是一个Vector2i表示的偏移量
const tick_table_common: Dictionary = {
	&"0_to_R" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,2)],
	&"R_to_0" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)],
	&"R_to_2" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)],
	&"2_to_R" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,-2)],
	&"2_to_L" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)],
	&"L_to_2" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)],
	&"L_to_0" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)],
	&"0_to_L" : [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)]
}

# I型方块的墙踢偏移表
# I型方块由于形状特殊，有更大的偏移范围
const tick_table_i: Dictionary = {
	&"0_to_R" : [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)],
	&"R_to_0" : [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)],
	&"R_to_2" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)],
	&"2_to_R" : [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(1,-2),Vector2i(-2,1)],
	&"2_to_L" : [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)],
	&"L_to_2" : [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)],
	&"L_to_0" : [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(+1,-2),Vector2i(-2,1)],
	&"0_to_L" : [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)]
}

# 预定义的测试点数组 - 避免从 Dictionary 取值的类型问题
const _TICK_COMMON: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,-2), Vector2i(-1,2)
]

## 获取指定方块和旋转方向的墙踢测试点
## @param tetromino 俄罗斯方块对象
## @param key 旋转方向键（如"0_to_R"）
## @return 测试点数组
static func get_test_points(tetromino: Tetromino, key: String) -> Array[Vector2i]:
	# 直接根据 tetromino 类型返回对应数组，避免 Dictionary 取值的类型问题
	match typeof(tetromino):
		TYPE_OBJECT:
			# I型方块
			if tetromino is I:
				return _get_i_test_points(key)
			# O型方块
			elif tetromino is O:
				return [Vector2i.ZERO]
			# 其他方块（J、L、S、T、Z）
			else:
				return _get_common_test_points(key)
		_:
			return [Vector2i.ZERO]


static func _get_common_test_points(key: String) -> Array[Vector2i]:
	match key:
		&"0_to_R": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,2)]
		&"R_to_0": return [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)]
		&"R_to_2": return [Vector2i(0,0),Vector2i(1,0),Vector2i(1,-1),Vector2i(0,2),Vector2i(1,2)]
		&"2_to_R": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-2),Vector2i(-1,-2)]
		&"2_to_L": return [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)]
		&"L_to_2": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)]
		&"L_to_0": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,2),Vector2i(-1,2)]
		&"0_to_L": return [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,-2),Vector2i(1,-2)]
		_: return [Vector2i.ZERO]


static func _get_i_test_points(key: String) -> Array[Vector2i]:
	match key:
		&"0_to_R": return [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)]
		&"R_to_0": return [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)]
		&"R_to_2": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)]
		&"2_to_R": return [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(1,-2),Vector2i(-2,1)]
		&"2_to_L": return [Vector2i(0,0),Vector2i(2,0),Vector2i(-1,0),Vector2i(2,1),Vector2i(-1,-2)]
		&"L_to_2": return [Vector2i(0,0),Vector2i(-2,0),Vector2i(1,0),Vector2i(-2,-1),Vector2i(1,2)]
		&"L_to_0": return [Vector2i(0,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(+1,-2),Vector2i(-2,1)]
		&"0_to_L": return [Vector2i(0,0),Vector2i(-1,0),Vector2i(2,0),Vector2i(-1,2),Vector2i(2,-1)]
		_: return [Vector2i.ZERO]


## 获取旋转状态字符串表示
## @param orientation 旋转方向（0=0度, 1=90度/R, 2=180度/2, 3=270度/L）
## @return 字符串表示（"0", "R", "2", "L"）
static func get_state_string(orientation: int) -> String:
	match orientation:
		0:
			return '0'      # 0度（原始方向）
		1:
			return 'R'      # 90度顺时针
		2:
			return '2'      # 180度
		3:
			return 'L'      # 270度（顺时针）或90度逆时针
		_:
			return '0'
