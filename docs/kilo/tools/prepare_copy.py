"""One-time copy of the current local tree, not an old remote revision."""
from pathlib import Path
import collections
import hashlib
import json
import os
import re
import shutil
import subprocess

SOURCE = Path('D:/Proyectos/Pokemon Calvo')
DEST = Path('D:/Proyectos/Pokemon Calvo - Arquitectura Kilo')
OUT = DEST / 'docs/kilo/baseline'


def sha(p):
    h = hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def git(*args):
    return subprocess.run(['git', '-c', 'core.safecrlf=false', *args], cwd=SOURCE,
                          capture_output=True, text=True, check=True).stdout


def main():
    assert SOURCE.resolve() != DEST.resolve() and DEST.parent.resolve() == SOURCE.parent.resolve()
    OUT.mkdir(parents=True, exist_ok=True)
    before = git('status', '--porcelain=v1', '-uall')
    (OUT / 'original_git_status.txt').write_text(before, encoding='utf-8')
    selected = {'imported', 'item_audit_v1', 'item_connections_v1', 'item_verification_v2',
                'item_verification_v3', 'item_field_v4', 'showdown_medicine_checks', 'field_native_checks'}
    for folder in ['modules', 'scenes', 'core']:
        for p in (SOURCE / folder).rglob('*'):
            if p.suffix in {'.gd', '.cjs'}:
                selected.update(re.findall(r'\.godot/([A-Za-z0-9_]+)/', p.read_text(encoding='utf-8-sig')))
    # Follow runtime manifest links to other .godot resource roots.
    scanned = set()
    while selected - scanned:
        name = sorted(selected - scanned)[0]; scanned.add(name)
        if name in {'battle_reference', 'imported'}:
            continue
        for p in (SOURCE / '.godot' / name).rglob('*.json'):
            selected.update(re.findall(r'\.godot/([A-Za-z0-9_]+)/', p.read_text(encoding='utf-8-sig')))
    files = []
    for root, dirs, names in os.walk(SOURCE, followlinks=False):
        base = Path(root)
        if base == SOURCE:
            dirs[:] = [d for d in dirs if d != '.godot']
        for d in dirs:
            p = base / d
            assert not p.is_symlink() and not p.is_junction(), f'Unexpected linked directory {p}'
        for name in names:
            files.append(base / name)
    for name in sorted(selected):
        root = SOURCE / '.godot' / name
        assert root.is_dir(), f'Missing runtime/test dependency {root}'
        files.extend(p for p in root.rglob('*') if p.is_file())
    records = []
    for index, p in enumerate(files):
        assert not p.is_symlink(), p
        rel = p.relative_to(SOURCE); target = DEST / rel
        assert not target.exists(), f'Refuse overwrite: {target}'
        target.parent.mkdir(parents=True, exist_ok=True)
        before_sha = sha(p)
        shutil.copy2(p, target)
        assert sha(target) == before_sha and sha(p) == before_sha, f'Changed during copy: {p}'
        records.append({'path': rel.as_posix(), 'bytes': p.stat().st_size, 'sha256': before_sha})
        if index % 2000 == 0:
            print('COPY_VERIFIED', index, '/', len(files), flush=True)
    omitted = []
    for p in (SOURCE / '.godot').iterdir():
        if p.name not in selected:
            omitted.append(p.relative_to(SOURCE).as_posix())
    assert before == git('status', '--porcelain=v1', '-uall'), 'Original working tree changed during copy'
    (OUT / 'copy_manifest.json').write_text(json.dumps({
        'source': str(SOURCE), 'destination': str(DEST), 'source_head': git('rev-parse', 'HEAD').strip(),
        'source_branch': git('branch', '--show-current').strip(), 'date': '2026-10-28',
        'copied_files': len(records), 'copied_bytes': sum(r['bytes'] for r in records),
        'godot_roots_included': sorted(selected), 'godot_cache_or_history_omitted': sorted(omitted),
        'source_untouched': True, 'copy_hash_verified_before_boot_isolation': True, 'files': records,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('COPY_COMPLETE', len(records), 'files', sum(r['bytes'] for r in records), 'bytes', flush=True)


if __name__ == '__main__':
    main()
