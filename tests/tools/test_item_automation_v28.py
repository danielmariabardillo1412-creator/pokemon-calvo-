"""Negative controls for the declarative runner contract, not mechanics copies."""
from pathlib import Path
import copy
import importlib.util
import unittest
import tempfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('automation_v28', ROOT/'tools/item_audit/automation_v28.py')
tool = importlib.util.module_from_spec(spec); spec.loader.exec_module(tool)


class Contract(unittest.TestCase):
    def setUp(self): self.d = tool.read(ROOT/tool.DESCRIPTOR)
    def test_reviewed_contract(self): self.assertEqual(len(tool.validate_descriptor(self.d)['items']),3)
    def test_missing_control(self):
        self.d['variants'].remove('reserve')
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_duplicate_item(self):
        self.d['items'][1] = copy.deepcopy(self.d['items'][0])
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_wrong_expectation(self):
        self.d['items'][0]['special_damage'] = 'greater'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_unknown_opcode(self):
        self.d['execute_shell'] = 'anything'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_omitted_scenario(self):
        self.d['scenarios'].pop()
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_unknown_item(self):
        self.d['items'][0]['id'] = 'wide_lens'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_green_label_is_not_execution(self):
        r = {'status':'SCOPED_VERIFIED','errors':[],'checks':1000,'items':3,'scenarios':[]}
        with self.assertRaises(ValueError): tool.validate_report(self.d,r,ROOT)
    def test_zero_assertions_rejected(self):
        with self.assertRaises(ValueError): tool.validate_report(self.d,{'status':'SCOPED_VERIFIED','checks':0},ROOT)

    def _consistent_receipt(self, out):
        path = out/'raw.json'; path.write_text('{}',encoding='utf-8')
        proof = {'valid':True,'evidence':'raw.json','sha256':tool.digest(path)}
        rows = []
        for spec in self.d['items']:
            for scenario in self.d['scenarios']:
                if scenario == 'map_bag_owner_save':
                    obs = {**proof,'physical_units':2,'battle_owner':'own','second_owner':'reserve'}
                else:
                    obs = {mode:dict(proof) for mode in self.d['variants']}
                    for mode,v in obs.items():
                        if scenario.endswith('_damage'):
                            v['damage'] = 20 if mode=='active' and spec[scenario]=='greater' else 10
                        elif scenario=='speed_order':
                            v['first_actor'] = 'own' if mode=='active' and spec[scenario]=='reversed' else 'foe'
                        else:
                            v.update(restored=True,disabled=mode=='active',alternate_accepted=mode!='active',unlocked_after_switch=True)
                rows.append({'id':spec['id'],'scenario':scenario,'status':'SCOPED_VERIFIED','checks':10,'errors':[],'observed':obs})
        return {'status':'SCOPED_VERIFIED','items':3,'checks':150,'errors':[],'scenarios':rows}

    def test_consistent_receipt_structure(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            self.assertTrue(tool.validate_report(self.d,self._consistent_receipt(out),out))
    def test_false_effect_with_green_label(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp); r=self._consistent_receipt(out)
            r['scenarios'][0]['observed']['active']['damage']=10
            with self.assertRaises(ValueError): tool.validate_report(self.d,r,out)
    def test_reserve_leaking_bonus(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp); r=self._consistent_receipt(out)
            r['scenarios'][0]['observed']['reserve']['damage']=20
            with self.assertRaises(ValueError): tool.validate_report(self.d,r,out)
    def test_forged_lock(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp); r=self._consistent_receipt(out)
            r['scenarios'][3]['observed']['active']['alternate_accepted']=True
            with self.assertRaises(ValueError): tool.validate_report(self.d,r,out)
    def test_corrupt_raw_hash(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp); r=self._consistent_receipt(out)
            (out/'raw.json').write_text('{"changed":true}',encoding='utf-8')
            with self.assertRaises(ValueError): tool.validate_report(self.d,r,out)


if __name__ == '__main__': unittest.main()
