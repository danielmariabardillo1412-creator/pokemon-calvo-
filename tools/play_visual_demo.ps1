$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -eq $command) { throw 'Instala Godot 4.7 o añade godot al PATH.' }
    $godot = $command.Source
}
Push-Location -LiteralPath $projectRoot
try {
    # A fresh checkout needs its script class cache before loading the inherited scene.
    & $godot --headless --path . --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot no ha podido importar el proyecto.' }
    & $godot --path . res://scenes/visual/field_demo.tscn
    if ($LASTEXITCODE -ne 0) { throw 'La demo terminó con un error; revisa la salida de Godot.' }
} finally {
    Pop-Location
}
