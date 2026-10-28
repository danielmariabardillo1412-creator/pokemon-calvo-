"""Launch only the authorized task in the existing installed Kilo CLI, hidden."""
from pathlib import Path
import json
import os
import subprocess
import sys
import guard

ROOT = guard.ROOT
KILO = Path('C:/Users/danie/.vscode/extensions/kilocode.kilo-code-7.8.18-win32-x64/bin/kilo.exe')


def main():
    guard.check_root(); guard.verify()
    ready = json.loads((ROOT / 'docs/kilo/baseline/BASELINE_STATUS.json').read_text(encoding='utf-8'))
    assert ready['status'] == 'PASS', 'Baseline not ready'
    out = ROOT / 'docs/kilo/evidence/session'; out.mkdir(parents=True, exist_ok=True)
    assert not (out / 'launch.json').exists(), 'A launch is already recorded; inspect before starting another'
    assert KILO.is_file(), 'Installed Kilo CLI missing; do not download or choose another model automatically'
    prompt = 'Lee el encargo adjunto. Ejecuta T001 y T002 en esta copia y detente en READY_FOR_REVIEW. Usa herramientas de lectura para inspeccionar archivos. Para probar usa los comandos exactos del runner; no encadenes comandos ni cambies de carpeta. Mantén el modelo y proveedor configurados.'
    args = [str(KILO), 'run', prompt, '--dir', str(ROOT), '--agent', 'code',
            '--format', 'json', '--title', 'Pokemon Calvo - Arquitectura HUD T001-T002',
            '--file', 'docs/kilo/KILO_PROMPT.txt']
    startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW; startup.wShowWindow = 0
    with (out / 'events.jsonl').open('wb') as stdout, (out / 'stderr.log').open('wb') as stderr:
        p = subprocess.Popen(args, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                             startupinfo=startup, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP)
    result = {'pid': p.pid, 'root': str(ROOT), 'command': args, 'status': 'LAUNCHED_NOT_YET_VERIFIED',
              'note': 'Uses existing configured provider/model. No --auto, no global permission changes.'}
    (out / 'launch.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))


if __name__ == '__main__':
    main()
