extends Node

## 全局事件总线，用于解耦游戏中的不同模块
## 使用方法：在任意位置通过 GlobalEvent.signal_name.connect(callable) 连接信号


# ===================== 游戏流程 =====================
@warning_ignore_start("unused_signal")
## 游戏开始信号
signal gameStarted

## 游戏暂停信号
## @param isPaused: 是否暂停
signal gamePaused(isPaused: bool)

## 游戏结束信号
## @param isWin: 是否获胜
signal gameEnded(isWin: bool)


# ===================== 玩家相关 =====================

## 玩家死亡信号
signal playerDied

## 玩家得分变化信号
## @param score: 当前得分
signal playerScoreChanged(score: int)

# ===================== 界面相关 =====================

## 界面显示信号
## @param uiName: 界面名称
signal uiShow(uiName: String)

## 界面隐藏信号
## @param uiName: 界面名称
signal uiHide(uiName: String)
