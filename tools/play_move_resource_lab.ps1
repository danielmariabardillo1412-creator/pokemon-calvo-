$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -eq $command) { throw 'Godot 4.7 no está disponible.' }
    $godot = $command.Source
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot\move_resource_pilot\manifest.json'))) {
    throw 'Falta el pack de investigación local; consulta VISUAL_CATALOG.md.'
}
& $godot --path $projectRoot --resolution 960x680 res://scenes/visual/move_resource_lab.tscn -- --batch --game-pool
if ($LASTEXITCODE -ne 0) { throw 'La prueba visual terminó con un error.' }
