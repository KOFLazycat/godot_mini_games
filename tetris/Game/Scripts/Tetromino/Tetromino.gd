## 俄罗斯方块基类
## 定义所有方块共有的属性和方法
## 每个具体的方块类（I、J、L、O、S、T、Z）都继承自此类
class_name Tetromino
extends RefCounted

## 存储方块4个旋转状态的数组
## 每个状态是一个二维数组，1表示方块占据的位置，0表示空
var state_array: Array[Array] = []
## 当前旋转方向（0=0度, 1=90度, 2=180度, 3=270度）
var orientation: int = 0

## 获取当前旋转状态的方块形状
## @return 二维数组，表示方块在当前旋转状态下的形状
func get_blocks() -> Array:
	return state_array[orientation]

## 获取初始状态（0度）的方块形状
## @return 二维数组，表示方块在初始状态下的形状
func get_init_blocks() -> Array:
	return state_array[0]
