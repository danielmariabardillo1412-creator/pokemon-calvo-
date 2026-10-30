import json,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools/verification'))
from opencode_items_v2_guard import ROOT,CONTRACT,mask_source,digest

class GuardTests(unittest.TestCase):
    def test_contract_paths_and_boundaries(self):
        c=json.loads(CONTRACT.read_text(encoding='utf-8'))
        self.assertEqual(c['authorized_tasks'],['O100','O110','O120','O190'])
        self.assertEqual(len(c['allowed_files']),len(set(c['allowed_files'])))
        for p in c['allowed_files']:
            self.assertFalse(Path(p).is_absolute());self.assertNotIn('..',Path(p).parts)
            self.assertFalse(p.startswith(('data/','config/','assets/','tools/architecture_handoff/')))
        self.assertNotIn('AGENTS.md',c['allowed_files'])
        self.assertNotIn('tools/verification/local_phase.py',c['allowed_files'])
        self.assertNotIn(CONTRACT.relative_to(ROOT).as_posix(),c['allowed_files'])

    def test_only_named_native_functions_are_mutable(self):
        c=json.loads(CONTRACT.read_text(encoding='utf-8'))
        rel='modules/battle/backends/showdown/native_engine.cjs';windows=c['code_windows'][rel]
        source=(ROOT/rel).read_text(encoding='utf-8');baseline=digest(mask_source(source,windows))
        for window in windows:
            changed=source.replace(window['end'],'\n/* new reviewed hook */'+window['end'],1)
            self.assertEqual(digest(mask_source(changed,windows)),baseline)
        self.assertNotEqual(digest(mask_source(source.replace('class NativeEngine {','class NativeEngine {\n// forbidden dispatch change'),windows)),baseline)
        with self.assertRaises(ValueError):mask_source(source.replace('function checkpoint(','function anotherCheckpoint('),windows)
        with self.assertRaises(ValueError):mask_source(source.replace('\nfunction lookup(','\nfunction injectedHelper(){}\nfunction lookup('),windows)

    def test_map_owner_other_functions_are_frozen(self):
        c=json.loads(CONTRACT.read_text(encoding='utf-8'));rel='scenes/visual/field_demo.gd';windows=c['code_windows'][rel]
        source=(ROOT/rel).read_text(encoding='utf-8');baseline=digest(mask_source(source,windows))
        changed=source.replace('\nfunc field_native_seed(','\n# forbidden unrelated change\nfunc field_native_seed(')
        self.assertEqual(digest(mask_source(changed,windows)),baseline) # inserted comment still inside the previous allowed window
        changed=source.replace('return _director._next_battle_seed if _director != null else -1','return 999')
        self.assertNotEqual(digest(mask_source(changed,windows)),baseline)

    def test_git_and_windows_line_endings_compare_consistently(self):
        c=json.loads(CONTRACT.read_text(encoding='utf-8'))
        for rel,windows in c['code_windows'].items():
            source=(ROOT/rel).read_text(encoding='utf-8')
            self.assertEqual(mask_source(source.replace('\n','\r\n'),windows),mask_source(source,windows))

if __name__=='__main__':unittest.main(verbosity=2)
