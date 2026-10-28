"""Negative controls for the comparison gate, plus optional real-adapter checks."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import unittest

from fixtures import STATS, stat_stage_cases, fixed_damage_cases, variable_power_cases, binding_cases, healing_cases, validate_manifest
from compare import compare
from run import ROOT, CACHE, read, write


class GateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases = validate_manifest(stat_stage_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves']))

    def setUp(self):
        self.case = self.cases[0]
        zero = dict.fromkeys(STATS, 0)
        self.row = {'id': self.case['id'], 'status': 'ok',
                    'actor': {'stages': zero.copy(), 'pp_spent': 1, 'move_used': True, 'substitute_present': False},
                    'target': {'stages': zero.copy(), 'substitute_present': False},
                    'benches': copy.deepcopy(self.case['bench_stages'])}
        self.payload = {'schema_version': 1, 'results': [self.row]}

    def changed(self, change):
        actual = copy.deepcopy(self.payload)
        change(actual['results'][0])
        return compare([self.case], self.payload, actual)

    def test_fixture_coverage(self):
        self.assertEqual(len(self.cases), 600)
        self.assertEqual({c['actor_side'] for c in self.cases}, {'side_a', 'side_b'})
        covered = {key for c in self.cases if c['move_id'] == 'acupressure' for key, value in c['actor']['stages'].items() if value < 6}
        self.assertEqual(covered, set(STATS))

    def test_equal_observations_match(self):
        self.assertEqual(compare([self.case], self.payload, self.payload)['counts'], {'MATCH': 1, 'MISMATCH': 0, 'NOT_COMPARABLE': 0})

    def test_one_stage_difference_is_localized(self):
        report = self.changed(lambda r: r['target']['stages'].update(attack=1))
        self.assertEqual(report['status'], 'NEEDS_REVIEW')
        self.assertEqual(report['results'][0]['differences'], [{'field':'target.stages.attack', 'reference':0, 'godot':1}])

    def test_pp_difference(self):
        self.assertEqual(self.changed(lambda r: r['actor'].update(pp_spent=0))['counts']['MISMATCH'], 1)

    def test_action_not_executed(self):
        self.assertEqual(self.changed(lambda r: r['actor'].update(move_used=False))['counts']['MISMATCH'], 1)

    def test_substitute_difference(self):
        self.assertEqual(self.changed(lambda r: r['target'].update(substitute_present=True))['counts']['MISMATCH'], 1)

    def test_bench_difference(self):
        self.assertEqual(self.changed(lambda r: r['benches']['actor'].update(speed=0))['counts']['MISMATCH'], 1)

    def test_unsupported_not_a_match(self):
        report = self.changed(lambda r: r.update(status='unsupported', reason='Outside adapter scope'))
        self.assertEqual(report['counts'], {'MATCH':0, 'MISMATCH':0, 'NOT_COMPARABLE':1})

    def test_adapter_error_not_a_match(self):
        self.assertEqual(self.changed(lambda r: r.update(status='error', reason='Adapter failed'))['status'], 'NEEDS_REVIEW')

    def test_both_engines_doing_nothing_is_not_success(self):
        self.row['actor'].update(move_used=False, pp_spent=0)
        self.assertEqual(compare([self.case], self.payload, self.payload)['counts']['NOT_COMPARABLE'], 1)

    def test_missing_result_fails(self):
        with self.assertRaises(ValueError): compare([self.case], self.payload, {'schema_version':1, 'results':[]})

    def test_duplicate_result_fails(self):
        with self.assertRaises(ValueError): compare([self.case], self.payload, {'schema_version':1, 'results':[self.row, self.row]})

    def test_unknown_result_fails(self):
        with self.assertRaises(ValueError): self.changed(lambda r: r.update(id='wrong'))

    def test_incomplete_observation_fails(self):
        with self.assertRaises(ValueError): self.changed(lambda r: r['target']['stages'].pop('accuracy'))

    def test_boolean_stage_is_not_an_integer(self):
        with self.assertRaises(ValueError): self.changed(lambda r: r['actor']['stages'].update(attack=True))

    def test_empty_and_duplicate_manifests_fail(self):
        for invalid in ([], [self.case, self.case]):
            with self.assertRaises(ValueError): validate_manifest(invalid)
        with self.assertRaises(ValueError): compare([], {'schema_version':1,'results':[]}, {'schema_version':1,'results':[]})

    def test_random_selection_not_silently_aligned(self):
        case = copy.deepcopy(next(c for c in self.cases if c['move_id'] == 'acupressure'))
        case['actor']['stages'] = dict.fromkeys(STATS, 0)
        with self.assertRaises(ValueError): validate_manifest([case])

    def test_random_accuracy_not_silently_aligned(self):
        case = copy.deepcopy(next(c for c in self.cases if c['move_id'] == 'spectral_thief'))
        case['actor']['stages']['accuracy'] = -6
        case['target']['stages']['evasion'] = 6
        with self.assertRaises(ValueError): validate_manifest([case])

    def fixed_payload(self):
        case = fixed_damage_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves'])[0]
        row = copy.deepcopy(self.row)
        row['id'] = case['id']
        row['actor'].update(hp=20000, substitute_hp=0, knocked_out=False)
        row['target'].update(hp=0, substitute_hp=0, knocked_out=True)
        return case, {'schema_version':1, 'results':[row]}

    def test_fixed_fixture_coverage(self):
        cases = validate_manifest(fixed_damage_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves']))
        self.assertEqual(len(cases), 1332)
        self.assertEqual({c['actor']['level'] for c in cases}, {1,50,100})
        self.assertEqual(len({c['move_id'] for c in cases}), 7)

    def test_fixed_hp_difference_localized(self):
        case, reference = self.fixed_payload()
        actual = copy.deepcopy(reference)
        actual['results'][0]['target'].update(hp=1, knocked_out=False)
        differences = compare([case], reference, actual)['results'][0]['differences']
        self.assertIn({'field':'target.hp','reference':0,'godot':1}, differences)

    def test_missing_fixed_hp_rejected(self):
        case, actual = self.fixed_payload()
        actual['results'][0]['target'].pop('hp')
        with self.assertRaises(ValueError): compare([case], actual, actual)

    def test_inconsistent_knockout_rejected(self):
        case, actual = self.fixed_payload()
        actual['results'][0]['target']['knocked_out'] = False
        with self.assertRaises(ValueError): compare([case], actual, actual)

    def test_remaining_doll_hp_difference_detected(self):
        case, reference = self.fixed_payload()
        reference['results'][0]['target'].update(hp=101, knocked_out=False, substitute_present=True, substitute_hp=450)
        actual = copy.deepcopy(reference)
        actual['results'][0]['target']['substitute_hp'] = 449
        self.assertEqual(compare([case], reference, actual)['counts']['MISMATCH'], 1)

    def test_fixed_random_accuracy_rejected(self):
        case, _ = self.fixed_payload()
        case['actor']['stages']['accuracy'] = -6
        with self.assertRaises(ValueError): validate_manifest([case])

    def variable_payload(self):
        case = variable_power_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves'])[0]
        row = copy.deepcopy(self.row)
        row.update(id=case['id'], power=60, contact=False, hit_received=True)
        return case, {'schema_version':1,'results':[row]}

    def test_variable_fixture_coverage(self):
        cases = validate_manifest(variable_power_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves']))
        self.assertEqual(len(cases), 3018)
        self.assertEqual(len({c['move_id'] for c in cases}),11)
        self.assertTrue(all(c['id'].startswith('variable_power/') for c in cases))

    def test_variable_power_difference_localized(self):
        case, reference = self.variable_payload()
        actual = copy.deepcopy(reference);actual['results'][0]['power'] = 61
        self.assertEqual(compare([case],reference,actual)['results'][0]['differences'],[{'field':'power','reference':60,'godot':61}])

    def test_missing_power_observation_rejected(self):
        case, actual = self.variable_payload();actual['results'][0].pop('power')
        with self.assertRaises(ValueError): compare([case],actual,actual)

    def test_contact_difference_detected(self):
        case, reference = self.variable_payload()
        actual = copy.deepcopy(reference);actual['results'][0]['contact'] = True
        self.assertEqual(compare([case],reference,actual)['counts']['MISMATCH'],1)

    def test_inconsistent_hit_observation_rejected(self):
        case, actual = self.variable_payload();actual['results'][0]['hit_received'] = False
        with self.assertRaises(ValueError): compare([case],actual,actual)

    def test_zero_pp_fixture_rejected(self):
        case,_ = self.variable_payload();case['actor']['pp'] = 0
        with self.assertRaises(ValueError): validate_manifest([case])

    def binding_payload(self):
        case=binding_cases(read(ROOT/'data/normalized/pokemon_api.json')['moves'])[0]
        row=copy.deepcopy(self.row)
        row.update(id=case['id'],binding={'present':True,'blocked':True,'residual_damage':32,'move_id':case['move_id'],'clock_valid':True},lifecycle=[])
        return case,{'schema_version':1,'results':[row]}

    def test_binding_fixture_coverage(self):
        cases=validate_manifest(binding_cases(read(ROOT/'data/normalized/pokemon_api.json')['moves']))
        self.assertEqual(len(cases),960)
        self.assertEqual(sum(c.get('lifecycle_turns')==8 for c in cases),60)

    def test_residual_damage_difference_detected(self):
        case,reference=self.binding_payload();actual=copy.deepcopy(reference)
        actual['results'][0]['binding']['residual_damage']=31
        self.assertEqual(compare([case],reference,actual)['results'][0]['differences'],[{'field':'binding.residual_damage','reference':32,'godot':31}])

    def test_switch_block_difference_detected(self):
        case,reference=self.binding_payload();actual=copy.deepcopy(reference)
        actual['results'][0]['binding']['blocked']=False
        self.assertEqual(compare([case],reference,actual)['counts']['MISMATCH'],1)

    def test_invalid_reference_clock_never_passes(self):
        case,reference=self.binding_payload();reference['results'][0]['binding']['clock_valid']=False
        self.assertEqual(compare([case],reference,reference)['counts']['NOT_COMPARABLE'],1)

    def test_missing_binding_observation_rejected(self):
        case,actual=self.binding_payload();actual['results'][0]['binding'].pop('present')
        with self.assertRaises(ValueError):compare([case],actual,actual)

    def test_missing_lifecycle_ticks_rejected(self):
        case,actual=self.binding_payload();case['lifecycle_turns']=8;case['actor']['item_id']='grip_claw'
        with self.assertRaises(ValueError):compare([case],actual,actual)


    def healing_payload(self):
        case=healing_cases(read(ROOT/'data/normalized/pokemon_api.json')['moves'])[0]
        row=copy.deepcopy(self.row);row['id']=case['id']
        for owner in ('actor','target'):row[owner].update(hp=55,status_id='burn')
        row['healing_benches']={'actor':{'hp':55,'status_id':''},'target':{'hp':55,'status_id':'poison'}}
        return case,{'schema_version':1,'results':[row]}

    def test_healing_fixture_coverage(self):
        cases=validate_manifest(healing_cases(read(ROOT/'data/normalized/pokemon_api.json')['moves']))
        self.assertEqual(len(cases),1374)
        self.assertEqual(len({c['move_id'] for c in cases}),8)

    def test_healing_hp_difference_detected(self):
        case,ref=self.healing_payload();actual=copy.deepcopy(ref);actual['results'][0]['actor']['hp']-=1
        result=compare([case],ref,actual)
        self.assertEqual(result['counts']['MISMATCH'],1)
        self.assertEqual(result['results'][0]['differences'][0]['field'],'actor.hp')

    def test_healing_status_difference_detected(self):
        case,ref=self.healing_payload();actual=copy.deepcopy(ref);actual['results'][0]['healing_benches']['actor']['status_id']='burn'
        result=compare([case],ref,actual)
        self.assertEqual(result['results'][0]['differences'][0]['field'],'healing_benches.actor.status_id')

    def test_healing_missing_status_rejected(self):
        case,ref=self.healing_payload();ref['results'][0]['target'].pop('status_id')
        with self.assertRaises(ValueError):compare([case],ref,ref)

    def test_healing_missing_bench_rejected(self):
        case,ref=self.healing_payload();ref['results'][0]['healing_benches'].pop('actor')
        with self.assertRaises(ValueError):compare([case],ref,ref)

    def test_healing_unknown_context_rejected(self):
        case,_=self.healing_payload();case['actor']['terrain']='electric'
        with self.assertRaises(ValueError):validate_manifest([case])


def integration_checks():
    folder = CACHE / 'negative_controls'
    folder.mkdir(parents=True, exist_ok=True)
    cases = stat_stage_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves'])
    case = cases[0]
    # Valid fixture schema, incompatible frozen move shape. Both real adapters
    # must decline it and the CLI must exit nonzero, never invent a match.
    case['contract']['pp'] += 1
    manifest = folder / 'unsupported_input.json'
    write(manifest, {'schema_version':1, 'cases':[case]})
    args = [sys.executable, str(Path(__file__).with_name('run.py')), '--manifest', str(manifest), '--output', str(folder / 'unsupported')]
    process = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=120)
    report = read(folder / 'unsupported/report.json')
    if process.returncode != 1 or report.get('counts') != {'MATCH':0,'MISMATCH':0,'NOT_COMPARABLE':1}:
        raise AssertionError((process.returncode, process.stdout, process.stderr, report))
    ruination = next(c for c in fixed_damage_cases(read(ROOT / 'data/normalized/pokemon_api.json')['moves']) if c['move_id'] == 'ruination')
    ruination['contract']['power'] = 2
    write(manifest, {'schema_version':1, 'cases':[ruination]})
    process = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=120)
    normalization_report = read(folder / 'unsupported/report.json')
    if process.returncode != 1 or normalization_report.get('counts') != {'MATCH':0,'MISMATCH':0,'NOT_COMPARABLE':1}:
        raise AssertionError(normalization_report)
    # Reuse that output directory deliberately: bad input must replace the old
    # verdict with ERROR, rather than leave a stale successful/partial report.
    write(manifest, {'schema_version':1, 'cases':[]})
    process = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=120)
    error_report = read(folder / 'unsupported/report.json')
    if process.returncode != 2 or error_report['status'] != 'ERROR': raise AssertionError(error_report)
    write(folder / 'checks.json', {'status':'PASS', 'checks':3,
                                 'unsupported_case':report, 'ruination_normalization_guard':normalization_report, 'empty_manifest':error_report})
    print('REAL_ADAPTER_NEGATIVE_CONTROLS PASS checks=3')


if __name__ == '__main__':
    integration = '--integration' in sys.argv
    if integration: sys.argv.remove('--integration')
    result = unittest.main(exit=False)
    if not result.result.wasSuccessful(): sys.exit(1)
    if integration: integration_checks()
