@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\play_visual_demo.ps1"
if errorlevel 1 pause
