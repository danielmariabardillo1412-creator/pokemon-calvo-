"""Exercise real ZIP restoration, conflicting files and invalid archives."""
from pathlib import Path
import importlib.util
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('resources', ROOT / 'tools/distribution/restore_resources.py')
resources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(resources)


class RestoreTests(unittest.TestCase):
    def fixture(self, folder, name='assets/local_battle_catalog/example.png', data=b'original'):
        archive = folder / 'resources.zip'
        with zipfile.ZipFile(archive, 'w') as output:
            output.writestr(name, data)
        import hashlib
        package = {'name': archive.name, 'sha256': resources.digest(archive),
                   'files': [{'path': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}]}
        return archive, package

    def test_roundtrip_and_idempotence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); archive, package = self.fixture(root)
            resources.restore_archive(root, archive, package)
            resources.restore_archive(root, archive, package)
            self.assertEqual(resources.check_files(root, package['files']), [])

    def test_checksum_rejected_before_write(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); archive, package = self.fixture(root)
            package['files'][0]['sha256'] = '0' * 64
            with self.assertRaises(ValueError): resources.restore_archive(root, archive, package)
            self.assertFalse((root / 'assets').exists())

    def test_existing_local_change_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); archive, package = self.fixture(root)
            target = root / package['files'][0]['path']; target.parent.mkdir(parents=True)
            target.write_bytes(b'local change')
            with self.assertRaises(ValueError): resources.restore_archive(root, archive, package)
            self.assertEqual(target.read_bytes(), b'local change')

    def test_extra_entry_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); archive, package = self.fixture(root)
            with zipfile.ZipFile(archive, 'a') as output: output.writestr('.godot/unexpected', b'x')
            package['sha256'] = resources.digest(archive)
            with self.assertRaises(ValueError): resources.restore_archive(root, archive, package)
            self.assertFalse((root / 'assets').exists())

    def test_paths_cannot_escape_or_replace_code(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ['../escape', '/absolute', '.godot/../../escape', 'C:/escape',
                         'modules/engine.gd', '.godot/..\\escape']:
                with self.subTest(name=name), self.assertRaises(ValueError):
                    resources.target_for(root, name)


if __name__ == '__main__': unittest.main()
