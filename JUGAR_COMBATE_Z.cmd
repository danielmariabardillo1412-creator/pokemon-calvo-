@echo off
"C:\Godot\4.7\Godot_v4.7-stable_win64.exe" --path "%~dp0." res://scenes/visual/showdown_battle_lab.tscn -- --z-demo
if errorlevel 1 pause
