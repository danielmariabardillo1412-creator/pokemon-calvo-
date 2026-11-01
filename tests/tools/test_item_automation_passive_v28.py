"""Reject incomplete contracts, fake effects and wrong-owner observations."""
from pathlib import Path
import copy
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_audit'))
import automation_v28 as tool
from automation_contracts_v28 import check_observations, validate_passive_report, reviewed_attribute_gap


class PassiveContracts(unittest.TestCase):
    def setUp(self): self.d=tool.read(ROOT/tool.PASSIVE_DESCRIPTOR)
    def spec(self,id): return next(s for s in self.d['items'] if s['id']==id)
    def case(self,spec,id): return next(c for c in spec['cases'] if c['id']==id)
    def test_complete_descriptor(self): self.assertEqual(len(tool.validate_descriptor(self.d)['items']),3)
    def test_missing_owner_control(self):
        self.d['variants'].remove('reserve')
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_missing_negative_trigger(self):
        self.spec('rocky_helmet')['cases'].pop(1)
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_unreviewed_fraction(self):
        self.spec('leftovers')['effect']['divisor']=8
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_unreviewed_opcode(self):
        self.spec('life_orb')['effect']['op']='equip_only'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_wrong_contact_flag(self):
        self.case(self.spec('rocky_helmet'),'physical_no_contact')['activates']=True
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_switch_target_required(self):
        self.case(self.spec('leftovers'),'heal_switched_owner')['target']='own'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_duplicate_item(self):
        self.d['items'][2]=copy.deepcopy(self.d['items'][0])
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)

    def sample(self,case,changes):
        obs={}
        for mode in ['active','none','reserve']:
            frames=[]
            state={'target_hp':160,'target_max_hp':160,'foe_hp':180,'foe_max_hp':180,'active_id':case['target']}
            for i,command in enumerate(case['commands']):
                before=dict(state); state.update(changes(mode,i,dict(state)))
                frames.append({'before':before,'after':dict(state),'command':command})
            obs[mode]={'valid':True,'restored':True,'frames':frames}
        return obs

    def test_healing_cap_negative_control(self):
        s=self.spec('leftovers'); c=self.case(s,'heal_cap')
        obs=self.sample(c,lambda m,i,b:{})
        for mode,v in obs.items():
            v['frames'][0]['before']['target_hp']=159
            v['frames'][0]['after']['target_hp']=160 if mode=='active' else 159
        self.assertTrue(check_observations(s,c,obs))
        obs['active']['frames'][0]['after']['target_hp']=169
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_life_orb_requires_both_boost_and_recoil(self):
        s=self.spec('life_orb');c=self.case(s,'physical_boost_recoil')
        obs=self.sample(c,lambda m,i,b:{'target_hp':b['target_hp']-16 if m=='active' else b['target_hp'],'foe_hp':b['foe_hp']-(26 if m=='active' else 20)})
        self.assertTrue(check_observations(s,c,obs))
        obs['active']['frames'][0]['after']['target_hp']=160
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_life_orb_status_has_no_recoil(self):
        s=self.spec('life_orb');c=self.case(s,'status_no_recoil');obs=self.sample(c,lambda m,i,b:{})
        self.assertTrue(check_observations(s,c,obs))
        obs['active']['frames'][0]['after']['target_hp']=144
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_immune_damage_is_not_a_positive_hit(self):
        s=self.spec('life_orb');c=self.case(s,'immune_no_recoil');obs=self.sample(c,lambda m,i,b:{})
        obs['active']['frames'][0]['after']['foe_hp']=150
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_noncontact_physical_is_not_contact(self):
        s=self.spec('rocky_helmet');c=self.case(s,'physical_no_contact')
        obs=self.sample(c,lambda m,i,b:{'target_hp':140})
        self.assertTrue(check_observations(s,c,obs))
        obs['active']['frames'][0]['after']['foe_hp']=150
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_effect_follows_new_active_owner(self):
        s=self.spec('rocky_helmet');c=self.case(s,'contact_switched_owner')
        obs=self.sample(c,lambda m,i,b:{'target_hp':b['target_hp']-20,'foe_hp':b['foe_hp']-(30 if m=='reserve' else 0)})
        self.assertTrue(check_observations(s,c,obs))
        obs['active']['frames'][0]['after']['foe_hp']=150
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_missing_timeline_or_restore_rejected(self):
        s=self.spec('leftovers');c=self.case(s,'full_hp_control');obs=self.sample(c,lambda m,i,b:{})
        obs['none']['restored']=False
        with self.assertRaises(ValueError): check_observations(s,c,obs)
    def test_empty_green_report_rejected(self):
        with self.assertRaises(ValueError): validate_passive_report(self.d,{'status':'SCOPED_VERIFIED','errors':[],'scenarios':[]},ROOT,tool.digest)
    def test_metadata_gap_is_specific_and_has_independent_source_evidence(self):
        import json
        r=json.loads(tool.git('show',tool.BASE+':data/api/v2/item/583/index.json'))
        self.assertTrue(reviewed_attribute_gap('rocky_helmet',r))
        self.assertFalse(reviewed_attribute_gap('choice_band',r))
        r['effect_entries']=[]
        self.assertFalse(reviewed_attribute_gap('rocky_helmet',r))


if __name__=='__main__': unittest.main()
