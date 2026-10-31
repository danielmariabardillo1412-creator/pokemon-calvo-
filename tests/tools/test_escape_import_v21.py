import sys,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools/item_import'))
import import_escape_v21 as compiler

class EscapeImportTests(unittest.TestCase):
    def test_pinned_family(self):
        result=compiler.build()
        self.assertEqual(set(result['items']),{'poke_doll','fluffy_tail','poke_toy'})
        self.assertTrue(all(row=={'wild_only':True,'consume':1,'guaranteed':True,'rng_consumed':False} for row in result['items'].values()))
        self.assertEqual(compiler.encode(result),compiler.OUTPUT.read_text(encoding='utf-8'))

    def test_unsupported_semantics_rejected(self):
        base='.fieldUseFunc=ItemUseOutOfBattle_CannotUse,\n.battleUsage=EFFECT_ITEM_ESCAPE,'
        self.assertEqual(compiler.compile_row('test',base)['consume'],1)
        for extra in ['\n.notConsumed=TRUE,','\n.holdEffect=UNKNOWN,','\n.battleUsage=OTHER,']:
            with self.subTest(extra=extra),self.assertRaises(ValueError):compiler.compile_row('test',base+extra)
        with self.assertRaises(ValueError):compiler.compile_row('test',base.replace('ESCAPE','RESTORE_HP'))

    def test_ban_applies_before_generation(self):
        original=compiler.load
        def load(path):
            result=original(path)
            if path.name=='item_selection_v1.json':result['excluded_ids']['poke_doll']='test ban'
            return result
        with patch.object(compiler,'load',load),self.assertRaisesRegex(ValueError,'poke_doll'):compiler.build()

    def test_source_change_fails(self):
        with patch.dict(compiler.HASHES,{'items.h':'0'*64}),self.assertRaisesRegex(ValueError,'hash mismatch'):compiler.build()

if __name__=='__main__':unittest.main(verbosity=2)
