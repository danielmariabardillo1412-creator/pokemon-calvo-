"""Negative controls for the read-only comparator (no game data mutations)."""
import copy
import unittest

from audit_pokeapi_data import Audit, ROOT, evolution, learnset, resource, select_group, source_blob, serialized_effect, load_source, read
import hashlib
import json
from pathlib import Path
import tempfile
from unittest.mock import patch


class ComparatorContract(unittest.TestCase):
    def test_source_loader_detects_missing_corrupt_extra_and_changed_ids(self):
        data = b'{"id":1,"name":"slow"}'
        oid = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        tree = read(ROOT/'data/manifests/pokemon_api_manifest.json')['provenance']['source_api_tree']
        def fake_git(*args):
            return tree if args[0] == 'rev-parse' else f'100644 blob {oid}\tgrowth-rate/1/index.json'
        with tempfile.TemporaryDirectory(prefix='pokeapi_audit_control_', dir=ROOT/'.godot') as tmp:
            source = Path(tmp)
            self.assertTrue(source.resolve().is_relative_to((ROOT/'.godot').resolve()))
            entry = source/'growth-rate/1/index.json'; entry.parent.mkdir(parents=True)
            with patch('audit_pokeapi_data.git', side_effect=fake_git):
                audit = Audit(); load_source(source, audit)
                self.assertIn('MISSING_SOURCE_FILE', [f['kind'] for f in audit.findings])
                entry.write_bytes(data)
                audit = Audit(); load_source(source, audit)
                self.assertFalse(audit.findings)
                entry.write_text(json.dumps({'id': 2, 'name': 'slow'}), encoding='utf-8')
                extra = source/'growth-rate/2/index.json'; extra.parent.mkdir(); extra.write_bytes(data)
                audit = Audit(); load_source(source, audit)
                self.assertEqual({f['field'] for f in audit.findings}, {'git_blob','numeric_id','path'})
                entry.write_bytes(b'{invalid')
                audit = Audit(); load_source(source, audit)
                self.assertIn('INVALID_JSON', [f['kind'] for f in audit.findings])

    def test_checkout_line_endings_only(self):
        data = b'{\n"id":1\n}\n'
        oid = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        self.assertEqual(source_blob(data, oid), (oid, 'EXACT'))
        self.assertEqual(source_blob(data.replace(b'\n', b'\r\n'), oid), (oid, 'CRLF_TO_LF'))
        self.assertEqual(source_blob(data.replace(b':1', b':2'), oid)[1], 'MISMATCH')

    def test_effect_defaults_do_not_hide_real_value_changes(self):
        original = {'kind': 'chance', 'chance_basis_points': 1000,
                    'children': [{'kind': 'drain', 'ratio_basis_points': 5000}]}
        expanded = serialized_effect(original)
        audit = Audit()
        audit.check('import', 'moves', 'x', 'effect_specs', [expanded], [serialized_effect(expanded)])
        self.assertFalse(audit.findings)
        expanded['children'][0]['ratio_basis_points'] = 1000
        audit.check('import', 'moves', 'x', 'effect_specs', [serialized_effect(original)], [expanded])
        self.assertEqual(len(audit.findings), 1)
        self.assertEqual(expanded['chance_basis_points'], 1000)

    def test_zero_evolution_condition_is_not_false(self):
        row = evolution('hitmontop', {'trigger': {'name': 'level-up'}, 'min_level': 20,
            'relative_physical_stats': 0, 'needs_overworld_rain': False, 'held_item': None})
        self.assertEqual(row['conditions'], {'relative_physical_stats': 0})
        audit = Audit()
        wrong = copy.deepcopy(row); del wrong['conditions']
        audit.check('api', 'species', 'tyrogue', 'evolutions', [row], [wrong], True)
        self.assertEqual(len(audit.findings), 1)

    def test_trade_is_not_level_ten(self):
        row = evolution('gengar', {'trigger': {'name': 'trade'}, 'min_level': None})
        self.assertEqual(row['min_level'], 0)
        audit = Audit()
        audit.fields('api', 'species', 'haunter', row, dict(row, min_level=10, trigger='level_up'))
        self.assertEqual({f['field'] for f in audit.findings}, {'trigger', 'min_level'})

    def test_only_one_version_not_cross_generation_union(self):
        def detail(group, level):
            return {'version_group': {'name': group}, 'level_learned_at': level,
                    'move_learn_method': {'name': 'level-up'}, 'order': 1}
        p = {'moves': [{'move': {'name': 'shadow-ball'}, 'version_group_details':
                       [detail('red-blue', 10), detail('scarlet-violet', 48)]}]}
        group = select_group(p)
        rows = learnset(p, group)
        self.assertEqual(group, 'scarlet-violet')
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['level'], 48)
        audit = Audit()
        wrong = [dict(rows[0], level=10)]
        audit.check('api', 'species', 'haunter', 'learnset', rows, wrong, True)
        self.assertEqual(len(audit.findings), 1)

    def test_normalization_is_not_an_error(self):
        audit = Audit()
        audit.check('import', 'species', 'x', 'slots', [{'slot': 1}], [{'slot': 1.0}], True)
        audit.check('import', 'species', 'x', 'zero', 0, False)
        self.assertEqual(len(audit.findings), 1)

    def test_reorder_allowed_but_duplicate_missing_extra_detected(self):
        audit = Audit()
        audit.check('api', 'species', 'x', 'learnset', [{'level': 1}, {'level': 2}],
                    [{'level': 2.0}, {'level': 1.0}], True)
        self.assertFalse(audit.findings)
        for actual in [[{'level': 1}], [{'level': 1}, {'level': 1}, {'level': 2}],
                       [{'level': 1}, {'level': 3}]]:
            audit.check('api', 'species', 'x', 'learnset', [{'level': 1}, {'level': 2}], actual, True)
        self.assertEqual(len(audit.findings), 3)

    def test_scalar_errors_and_missing_fields_are_detected(self):
        audit = Audit()
        audit.fields('api', 'species', 'x', {'base_hp': 100, 'growth_rate': 'slow'}, {'base_hp': 10})
        self.assertEqual(len(audit.findings), 2)

    def test_localization_fallback_not_invented_translation(self):
        audit = Audit()
        source = {'name': 'move-x', 'names': [{'name': 'Nombre', 'language': {'name': 'es'}},
                                             {'name': 'Name', 'language': {'name': 'en'}}]}
        audit.label('moves', source, {'display_name': 'Name'})
        self.assertEqual(audit.localization[0]['language'], 'es')
        self.assertEqual(len(audit.findings), 1)
        source['effect_entries'] = [{'short_effect': 'Original English', 'language': {'name': 'en'}}]
        audit.description('moves', source, {'effect_summary': 'Original English'}, ['effect_summary'])
        self.assertEqual(len(audit.findings), 1)
        self.assertEqual(audit.localization[-1]['language'], 'en')

    def test_conditions_keep_item_time_gender_and_negative_values(self):
        row = evolution('target', {'trigger': {'name': 'level-up'}, 'gender': 1,
            'held_item': {'name': 'metal-coat'}, 'time_of_day': 'night',
            'relative_physical_stats': -1, 'is_default': False})
        self.assertEqual(row['conditions'], {'gender': 1, 'held_item': 'metal_coat',
                         'time_of_day': 'night', 'relative_physical_stats': -1})
        self.assertIs(row['is_default'], False)
        self.assertEqual(resource({'name': 'special-attack'}), 'special_attack')


if __name__ == '__main__':
    unittest.main()
