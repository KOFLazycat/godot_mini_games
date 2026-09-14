#!/bin/bash

WORKSPACE=..
LUBAN_DLL=$WORKSPACE/Tools/Luban/Luban.dll
CONF_ROOT=Configs

dotnet $LUBAN_DLL \
    -t all \
    -c gdscript-json \
    -d json \
    --conf $CONF_ROOT/luban.conf \
    -x compact=1 \
    -x outputCodeDir=..\..\GodotLubanProject\Src\DataTables ^
    -x outputDataDir=..\..\GodotLubanProject\Assets\DataTables