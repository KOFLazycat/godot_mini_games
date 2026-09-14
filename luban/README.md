# godot-luban-example
Example of using Luban with Godot 4.x. 在Godot 4.x中使用Luban的简单示例.


```
.
|-- GodotLubanProject   Godot项目目录
|   |-- ...
`-- GodotLubanData 配置表目录
    |-- DataTables 示例配置表及导出脚本
    `-- Tools/Luban   工具

```

![](https://raw.githubusercontent.com/PamisuMyon/gh-assets/main/images/gle/1.png)

- `GodotLubanData/Tools/Luban` 可以使用最新版本的Luban：`https://github.com/focus-creative-games/luban/releases`
- `GodotLubanData/DataTables/_示例.xlsx` 用来配置数据
- `_gen.bat _gen.sh` 注意配置导出数据、代码目录
- `GodotLubanProject/Src/AutoLoad/LubanLoader.tscn` 和 `GodotLubanProject/Src/AutoLoad/LubanLoader.gd` 是用来加载Luban数据的全局单例，可以单独拷贝到项目中，但是要注意加到全局变量中才能使用。另外 `LubanLoader.configJsonPath` 注意要更新到`json`文件存放目录，以 `/` 结尾