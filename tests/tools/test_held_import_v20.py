import sys,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools/item_import'))
import import_held_v20 as compiler

class HeldImportTests(unittest.TestCase):
    def test_full_pinned_batch(self):
        value=compiler.build()
        self.assertEqual(len(value['items']),12)
        self.assertEqual(compiler.encode(value),compiler.OUTPUT.read_text(encoding='utf-8'))
        self.assertEqual(sum(row['fling']['basePower']==10 for row in value['items'].values()),5)
        self.assertEqual(value['items']['pokedoll']['gen'],1)
        self.assertTrue(all(not row['held_passive_effect'] and not row['special_use_certified_by_this_import'] for row in value['separate_contexts'].values()))
        for id in ['amuletcoin','cleansetag','expshare','linkingcord','luckincense','pureincense','smokeball']:
            self.assertNotIn(id,value['items'])

    def test_no_unknown_passive_or_conditional_effect(self):
        base='.name=ITEM_NAME("Test"),\n.flingPower=30,'
        self.assertEqual(compiler.metadata('test',base,3)['fling']['basePower'],30)
        self.assertEqual(compiler.metadata('poke_doll',base.replace('Test','Poké Doll'),1)['name'],'Poke Doll')
        with self.assertRaises(ValueError):compiler.metadata('wrong_id',base,3)
        self.assertEqual(compiler.metadata('test','#if PRICE\n.price=1,\n#endif\n'+base,3)['gen'],3)
        for extra in ['\n.holdEffect=HOLD_EFFECT_REPEL,','\n.flingPower=10,',
            '\n#if UNKNOWN\n.name=ITEM_NAME("Changed"),\n#endif', '\n#if UNKNOWN']:
            with self.subTest(extra=extra),self.assertRaises(ValueError):compiler.metadata('test',base+extra,3)
        with self.assertRaises(ValueError):compiler.metadata('test',base.replace('30','UNKNOWN'),3)

    def test_policy_cannot_be_bypassed(self):
        original=compiler.load
        def load(path):
            value=original(path)
            if path.name=='item_selection_v1.json':value['excluded_ids']['blue_flute']='test ban'
            return value
        with patch.object(compiler,'load',load),self.assertRaisesRegex(ValueError,'blue_flute'):compiler.build()

    def test_changed_source_fails_before_generation(self):
        with patch.dict(compiler.HASHES,{'items.h':'0'*64}),self.assertRaisesRegex(ValueError,'hash mismatch'):compiler.build()

if __name__=='__main__':unittest.main(verbosity=2)
