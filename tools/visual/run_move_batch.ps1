param(
    [string]$SourceRoot = 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1',
    [switch]$Capture,
    [switch]$OpenLab
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$godot = 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
$builder = Join-Path $PSScriptRoot 'build_move_batch.py'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Falta Godot 4.7 local.' }
& python $builder --source-root $SourceRoot
if ($LASTEXITCODE -ne 0) { throw 'Falló la conversión; no iniciar auditoría sobre un índice antiguo.' }
$auditArgs = @('--path', $projectRoot, '--script', 'tests/visual/move_batch_audit_runner.gd', '--log-file', '.godot/move_batch_checks/run.log')
if ($Capture) {
    & $godot @auditArgs --resolution 64x64 --disable-render-loop --disable-vsync --max-fps 0 -- --capture
} else {
    & $godot --headless @auditArgs
}
if ($LASTEXITCODE -ne 0) { throw 'Falló la auditoría. Consultar .godot/move_batch_checks/.' }
$auditName = if ($Capture) { 'gpu_result.json' } else { 'headless_result.json' }
& python (Join-Path $PSScriptRoot 'summarize_move_batch.py') --audit (Join-Path $projectRoot ".godot/move_batch_checks/$auditName")
if ($LASTEXITCODE -ne 0) { throw 'Informe no válido o pruebas obsoletas.' }
if ($OpenLab) { & $godot --path $projectRoot --resolution 960x680 res://scenes/visual/move_resource_lab.tscn -- --batch }
