## 坐标系统工具类
## 定义游戏中常用的方向向量常量，用于简化移动逻辑
class_name Coordinates
extends RefCounted

## 向左移动向量 (x=-1, y=0)
const LEFT = Vector2i(-1, 0)
## 向右移动向量 (x=1, y=0)
const RIGHT = Vector2i(1, 0)
## 向上移动向量 (x=0, y=1) - 在俄罗斯方块中通常向上是y增加
const UP = Vector2i(0, 1)
## 向下移动向量 (x=0, y=-1) - 在俄罗斯方块中通常向下是y减少
const DOWN = Vector2i(0, -1)
