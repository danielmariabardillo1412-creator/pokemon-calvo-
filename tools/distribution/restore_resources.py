"""Restore the pinned development resources attached to the V27 GitHub release."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import json
import shutil
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'ci/resources_v27.json'


def digest(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def target_for(root, name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
        raise ValueError('Invalid resource path: ' + name)
    allowed = ('assets/local_battle_catalog/', 'assets/local_battle_variants/', '.godot/')
    if not name.startswith(allowed):
        raise ValueError('Resource outside declared roots: ' + name)
    target = root.joinpath(*path.parts)
    if not target.resolve().is_relative_to(root.resolve()):
        raise ValueError('Resource link leaves project: ' + name)
    return target


def check_files(root, files):
    missing = []
    for row in files:
        target = target_for(root, row['path'])
        if not target.is_file():
            missing.append(row['path'])
        elif target.stat().st_size != row['bytes'] or digest(target) != row['sha256']:
            raise ValueError('Existing resource differs; refusing overwrite: ' + row['path'])
    return missing


def restore_archive(root, archive, package):
    if digest(archive) != package['sha256']:
        raise ValueError('Archive checksum mismatch: ' + package['name'])
    expected = {row['path']: row for row in package['files']}
    if len(expected) != len(package['files']):
        raise ValueError('Duplicate manifest path')
    check_files(root, package['files'])
    with zipfile.ZipFile(archive) as source:
        names = source.namelist()
        if len(names) != len(set(names)) or set(names) != set(expected):
            raise ValueError('Archive inventory differs from pinned manifest')
        # Verify every byte before publishing any file to the project.
        for info in source.infolist():
            row = expected[info.filename]
            target_for(root, info.filename)
            if info.file_size != row['bytes'] or (info.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError('Invalid resource entry: ' + info.filename)
            with source.open(info) as stream:
                if hashlib.file_digest(stream, 'sha256').hexdigest() != row['sha256']:
                    raise ValueError('Resource checksum mismatch: ' + info.filename)
        for name, row in expected.items():
            target = target_for(root, name)
            if target.exists():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as staged:
                temporary = Path(staged.name)
                with source.open(name) as stream:
                    shutil.copyfileobj(stream, staged)
            try:
                # Exclusive creation never replaces an existing local resource.
                with temporary.open('rb') as stream, target.open('xb') as output:
                    shutil.copyfileobj(stream, output)
            finally:
                temporary.unlink(missing_ok=True)
    if check_files(root, package['files']):
        raise ValueError('Incomplete restoration')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify without downloading or writing')
    parser.add_argument('--archive-dir', type=Path, help='Use already downloaded ZIP files')
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    files = [row for package in manifest['packages'] for row in package['files']]
    missing = check_files(ROOT, files)
    if args.check:
        print(json.dumps({'status': 'FAIL' if missing else 'PASS', 'files': len(files),
                          'missing': len(missing), 'first_missing': missing[:5]}))
        return 1 if missing else 0
    cache = ROOT / '.godot/distribution_downloads'
    cache.mkdir(parents=True, exist_ok=True)
    for package in manifest['packages']:
        if not check_files(ROOT, package['files']):
            print(package['name'], 'already verified', flush=True)
            continue
        archive = (args.archive_dir or cache) / package['name']
        if not archive.exists() and args.archive_dir is None:
            temporary = archive.with_suffix('.download')
            try:
                with urllib.request.urlopen(package['url'], timeout=120) as response, temporary.open('wb') as output:
                    shutil.copyfileobj(response, output)
                if digest(temporary) != package['sha256']:
                    raise ValueError('Downloaded checksum mismatch')
                temporary.replace(archive)
            finally:
                temporary.unlink(missing_ok=True)
        restore_archive(ROOT, archive, package)
        print(package['name'], 'restored and verified', flush=True)
    print('RESOURCES_V27 PASS files=' + str(len(files)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
