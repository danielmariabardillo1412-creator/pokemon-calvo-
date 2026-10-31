"""Compiler safety and real pinned-source regression, independent of Godot."""
import copy
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'tools/item_import'))
import import_recovery as compiler

class ImportTests(unittest.TestCase):
    def test_modern_amount_and_boundaries(self):
        for expr, expected in [('20', 20), ('ITEM6_HEAL_HP_FULL', 'full'),
             ('ITEM6_HEAL_HP_QUARTER', 'quarter'), ('I_HEALTH_RECOVERY >= GEN_7 ? 60 : 50', 60)]:
            with self.subTest(expr=expr):
                self.assertEqual(compiler.compile_effect('[4]=ITEM4_HEAL_HP,[6]='+expr+',', 7), {'heal': expected})
        for expr in ['0', '-1', '255', 'other()', '__import__("os")', 'I_HEALTH_RECOVERY >= GEN_6 ? 60 : 50']:
            with self.subTest(expr=expr), self.assertRaises(compiler.Unsupported):
                compiler.compile_effect('[4]=ITEM4_HEAL_HP,[6]='+expr+',', 7)

    def test_status_pp_and_friendship(self):
        for body, size, result in [('[3]=ITEM3_POISON,', 6, {'cure': ['psn', 'tox']}),
          ('[3]=ITEM3_STATUS_ALL,', 6, {'cure': 'all', 'confusion': True}),
          ('[4]=ITEM4_HEAL_PP_ONE|ITEM4_HEAL_PP,[6]=10,', 7, {'pp': 10, 'scope': 'one'}),
          ('[4]=ITEM4_HEAL_PP,[6]=ITEM6_HEAL_PP_FULL,', 7, {'pp': 'full', 'scope': 'all'}),
          ('[3]=ITEM3_STATUS_ALL,[5]=ITEM5_FRIENDSHIP_ALL,[6]=-5,[7]=-5,[8]=-10,', 9,
           {'cure': 'all', 'confusion': True, 'friendship_loss': [5, 5, 10]})]:
            with self.subTest(body=body): self.assertEqual(compiler.compile_effect(body, size), result)

    def test_never_drop_an_extra_capability(self):
        for body, size in [('[4]=ITEM4_REVIVE|ITEM4_HEAL_HP,[6]=ITEM6_HEAL_HP_FULL,', 7),
          ('[3]=ITEM3_LEVEL_UP,', 6), ('[0]=ITEM0_INFATUATION,', 6),
          ('[4]=ITEM4_HEAL_PP_ONE,[6]=10,', 7), ('[3]=ITEM3_SLEEP,[0]=UNKNOWN,', 6),
          ('[3]=ITEM3_SLEEP,[3]=ITEM3_SLEEP,', 6), ('[3]=ITEM3_SLEEP,[9]=10,', 6),
          ('[3]=ITEM3_SLEEP,MACRO(7),', 6), ('[3]=ITEM3_SLEEP,[6]=10,', 7),
          ('[3]=ITEM3_SLEEP,[5]=ITEM5_FRIENDSHIP_ALL,[6]=5,[7]=5,[8]=10,', 9),
          ('[3]=ITEM3_SLEEP|ITEM3_SLEEP,', 6), ('[3]=ITEM3_SLEEP,', 7)]:
            with self.subTest(body=body), self.assertRaises(compiler.Unsupported): compiler.compile_effect(body, size)

    def test_conditional_and_comment_handling(self):
        body = '[4]=ITEM4_HEAL_HP,\n#if I_SITRUS_BERRY_HEAL >= GEN_4\n[6]=ITEM6_HEAL_HP_QUARTER,\n#else\n[6]=30,\n#endif'
        self.assertEqual(compiler.compile_effect(body, 7), {'heal': 'quarter'})
        self.assertEqual(compiler.compile_effect('[3]=ITEM3_SLEEP, // harmless\n/*[0]=UNKNOWN,*/', 6), {'cure': ['slp']})
        for body in ['#if UNKNOWN\n[3]=ITEM3_SLEEP,\n#endif', '#else', '#if I_SITRUS_BERRY_HEAL >= GEN_4\n[3]=ITEM3_SLEEP,']:
            with self.subTest(body=body), self.assertRaises(compiler.Unsupported): compiler.compile_effect(body, 6)

    def test_routing_and_consumption_are_required(self):
        effects = {'gItemEffect_Test': ('[3]=ITEM3_SLEEP,', 6)}
        block = '.type=ITEM_USE_PARTY_MENU,\n.fieldUseFunc=ItemUseOutOfBattle_Medicine,\n.effect=gItemEffect_Test,\n.notConsumed=TRUE,'
        self.assertEqual(compiler.compile_item(block, effects), ({'cure': ['slp']}, False, 'gItemEffect_Test'))
        # Cosmetic conditional never controls mechanics.
        self.assertEqual(compiler.compile_item('#if UNKNOWN_PRICE\n.price=10,\n#else\n.price=20,\n#endif\n'+block, effects)[1], False)
        for candidate in [block.replace('TRUE', 'UNKNOWN'), block.replace('Medicine', 'CannotUse'),
             block.replace('gItemEffect_Test', 'missing'), block.replace('PARTY_MENU', 'BAG_MENU'),
             block+'\n.effect=gItemEffect_Test,', '#if UNKNOWN\n'+block+'\n#endif',
             block.replace('.notConsumed', '#if UNKNOWN\n.notConsumed')]:
            with self.subTest(candidate=candidate), self.assertRaises(compiler.Unsupported): compiler.compile_item(candidate, effects)

    def test_duplicate_source_records_rejected(self):
        item = '    [ITEM_POTION] =\n    {\n    },\n'
        effect = 'const u8 gItemEffect_Test[6] = {[3]=ITEM3_SLEEP,};'
        with self.assertRaises(ValueError): compiler.indexes(item*2, effect)
        with self.assertRaises(ValueError): compiler.indexes(item, effect*2)

    def test_pinned_batch_and_reproducibility(self):
        manifest, audit = compiler.build(compiler.ROOT/'.godot/item_mochi_v13/references')
        self.assertEqual(len(manifest['items']), 42)
        self.assertEqual(audit['new_field_ids'], ['blue_flute'])
        self.assertEqual(audit['catalog_count'], 2222)
        self.assertEqual(sum(audit['counts'].values()), 2222)
        self.assertEqual(len({row['id'] for row in audit['rows']}), 2222)
        self.assertEqual(len(audit['preserved_existing_ids']), 41)
        self.assertEqual(manifest['items']['blue_flute']['consume'], False)
        self.assertEqual(compiler.encode(manifest), compiler.MANIFEST.read_text(encoding='utf-8'))
        self.assertEqual(compiler.encode(audit), compiler.AUDIT.read_text(encoding='utf-8'))
        self.assertEqual(compiler.build(compiler.ROOT/'.godot/item_mochi_v13/references'), (manifest, audit))
        for id in ['revive', 'revival_herb', 'sacred_ash', 'yellow_flute', 'red_flute', 'persim_berry', 'rare_candy']:
            with self.subTest(id=id): self.assertNotIn(id, manifest['items'])

    def test_hash_mismatch_cannot_publish(self):
        with tempfile.TemporaryDirectory() as tmp:
            for name in compiler.HASHES:
                raw = (compiler.ROOT/'.godot/item_mochi_v13/references'/name).read_bytes()
                (Path(tmp)/name).write_bytes(raw + (b'\n' if name == 'items.h' else b''))
            with self.assertRaisesRegex(ValueError, 'hash mismatch'): compiler.build(Path(tmp))

    def test_profile_conflict_cannot_publish(self):
        original = compiler.load
        def changed(path):
            value = original(path)
            if path.name == 'field_recovery_profile.json': value['items']['fresh_water']['heal'] = 999
            return value
        with patch.object(compiler, 'load', changed), self.assertRaisesRegex(ValueError, 'fresh_water'):
            compiler.build(compiler.ROOT/'.godot/item_mochi_v13/references')

    def test_policy_applies_before_activation(self):
        original = compiler.load
        def changed(path):
            value = copy.deepcopy(original(path))
            if path.name == 'item_selection_v1.json': value['excluded_ids']['blue_flute'] = 'test ban'
            return value
        with patch.object(compiler, 'load', changed):
            manifest, audit = compiler.build(compiler.ROOT/'.godot/item_mochi_v13/references')
            self.assertNotIn('blue_flute', manifest['items'])
            self.assertEqual(next(row for row in audit['rows'] if row['id'] == 'blue_flute')['status'], 'POLICY_EXCLUDED')

if __name__ == '__main__': unittest.main(verbosity=2)
