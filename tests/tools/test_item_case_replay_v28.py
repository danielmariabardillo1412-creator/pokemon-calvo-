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
    def test_full_certification_claim_rejected(self):
        with self.assertRaises(ValueError): validate([],{'status':'REPLAY_INTEGRATION_PASS','errors':[],'full_item_certification':True},Path('.'))
    def test_empty_green_report_rejected(self):
        with self.assertRaises(ValueError): validate([],{'status':'REPLAY_INTEGRATION_PASS','checks':1,'errors':[],'full_item_certification':False},Path('.'))

if __name__=='__main__': unittest.main()
