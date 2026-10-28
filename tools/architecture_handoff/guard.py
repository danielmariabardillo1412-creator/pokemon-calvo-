"""Read-only guard for the bounded HUD pilot. Never reads or writes the original."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = Path('D:/Proyectos/Pokemon Calvo - Arquitectura Kilo')
BASE = ROOT / 'docs/kilo/baseline'
MUTABLE = {'scenes/visual/field_demo.gd', 'scenes/visual/field_hud.gd',
           'scenes/visual/field_hud.gd.uid', 'tests/gameplay/field_hud_contract_test_runner.gd',
           'tests/gameplay/field_hud_contract_test_runner.gd.uid',
           'docs/kilo/PROGRESS.md', 'docs/kilo/TASKS.json'}


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def check_root():
    assert ROOT.resolve() == EXPECTED.resolve(), 'Wrong workspace: refusing to run'
    marker = json.loads((ROOT / '.kilo-handoff.json').read_text(encoding='utf-8'))
    assert Path(marker['copy_root']).resolve() == ROOT.resolve()
    assert marker['user_data_name'] == 'Pokemon Calvo - Arquitectura Kilo'
    assert 'config/name="Pokemon Calvo - Arquitectura Kilo"' in (ROOT / 'project.godot').read_text()


def allowed(path):
    return path in MUTABLE or path.startswith('docs/kilo/evidence/')


def verify(full=False):
    check_root()
    frozen = json.loads((BASE / 'protected_files.json').read_text(encoding='utf-8'))
    bad = []
    for row in frozen:
        p = ROOT / row['path']
        if not p.is_file() or p.is_symlink():
            bad.append(row['path'] + ': missing/linked'); continue
        stat = p.stat()
        if full or row['text'] or stat.st_size != row['bytes'] or stat.st_mtime_ns != row['mtime_ns']:
            if sha(p) != row['sha256']: bad.append(row['path'] + ': changed')
    commit_file = BASE / 'BASELINE_COMMIT.txt'
    if commit_file.exists():
        commit = commit_file.read_text().strip()
        changed = subprocess.run(['git', 'diff', '--name-only', commit], cwd=ROOT,
                                 capture_output=True, text=True, check=True).stdout.splitlines()
        new = subprocess.run(['git', 'ls-files', '--others', '--exclude-standard'], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout.splitlines()
        bad += [p + ': outside pilot scope' for p in changed + new if not allowed(p)]
        assert subprocess.run(['git', 'remote'], cwd=ROOT, capture_output=True,
                              text=True, check=True).stdout.strip() == '', 'Unexpected remote'
    assert not bad, '\n'.join(bad[:30])
    return {'status': 'PASS', 'protected_files': len(frozen),
            'mode': 'FULL_CONTENT_HASHES' if full else 'TEXT_HASHES_AND_RESOURCE_METADATA_WITH_HASH_ON_CHANGE'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--full', action='store_true')
    args = parser.parse_args(); print(json.dumps(verify(args.full)))
