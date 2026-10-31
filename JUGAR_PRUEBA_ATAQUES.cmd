@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\play_move_resource_lab.ps1"
if errorlevel 1 pause
