import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tools/item_audit'))
from replay_v28 import select,validate

class ReplayProof(unittest.TestCase):
    def source(self,status='NATIVE_SCENARIO_PASS'):
        return [([{'id':'sample','case_id':'sample/case/1','commands':[{}],'steps':[{}]}],{'results':[{'case_id':'sample/case/1','status':status}]})]
    def test_original_proof_accepted(self): self.assertEqual(len(select(self.source(),['sample'])),1)
    def test_failed_native_oracle_rejected(self):
        with self.assertRaises(ValueError): select(self.source('FAIL_NATIVE_OR_FIXTURE'),['sample'])
    def test_missing_item_rejected(self):
        with self.assertRaises(ValueError): select(self.source(),['sample','missing'])
    def test_missing_command_rejected(self):
        s=self.source();s[0][0][0]['commands']=[]
        with self.assertRaises(ValueError): select(s,['sample'])
    def type_source(self):
        cases = [
            {'id':'silk_scarf','family':family,'seed':seed,
             'case_id':f'silk_scarf/{family}/{seed}','commands':[{}],'steps':[{}]}
            for family in ('type_boost','type_boost_nonmatching') for seed in (1,19)
        ]
        proof = {'results':[{'case_id':row['case_id'],'status':'NATIVE_SCENARIO_PASS'} for row in cases]}
        return [(cases,proof)]
    def test_complete_type_pair_accepted(self):
        self.assertEqual(len(select(self.type_source(),['silk_scarf'],type_ids=['silk_scarf'])),4)
    def test_type_pair_missing_control_rejected(self):
        source = self.type_source()
        source[0][0].pop()
        with self.assertRaises(ValueError): select(source,['silk_scarf'],type_ids=['silk_scarf'])
    def test_type_pair_duplicate_seed_rejected(self):
        source = self.type_source()
        source[0][0][-1]['seed'] = 1
        with self.assertRaises(ValueError): select(source,['silk_scarf'],type_ids=['silk_scarf'])
    def test_type_pair_missing_original_assertion_rejected(self):
        source = self.type_source()
        source[0][1]['results'][-1]['status'] = 'FAIL_NATIVE_OR_FIXTURE'
        with self.assertRaises(ValueError): select(source,['silk_scarf'],type_ids=['silk_scarf'])
    def test_full_certification_claim_rejected(self):
        with self.assertRaises(ValueError): validate([],{'status':'REPLAY_INTEGRATION_PASS','errors':[],'full_item_certification':True},Path('.'))
    def test_empty_green_report_rejected(self):
        with self.assertRaises(ValueError): validate([],{'status':'REPLAY_INTEGRATION_PASS','checks':1,'errors':[],'full_item_certification':False},Path('.'))

if __name__=='__main__': unittest.main()
