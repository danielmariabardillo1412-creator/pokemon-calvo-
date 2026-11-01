"""Third-family negative controls: real consumption and real entry hazards."""
from pathlib import Path
import copy
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_audit'))
import automation_v28 as tool
from automation_entry_v28 import check_frames, validate_report, validate_collection, source_metadata_supported


class EntryContracts(unittest.TestCase):
    def setUp(self): self.d=tool.read(ROOT/tool.ENTRY_DESCRIPTOR)
    def test_reviewed_descriptor(self): self.assertEqual(len(tool.validate_descriptor(self.d)['items']),2)
    def test_owner_control_cannot_be_omitted(self):
        self.d['variants'].remove('reserve')
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_break_trigger_cannot_be_omitted(self):
        self.d['items'][0]['cases'].pop()
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_hazard_cannot_be_omitted(self):
        self.d['items'][1]['cases'].pop(0)
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_wrong_pop_phase(self):
        self.d['items'][0]['cases'][0]['phases'][1]='status'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_fake_hazard_move(self):
        self.d['items'][1]['cases'][0]['foe_moves'][0]='amnesia'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_unknown_case(self):
        self.d['items'][1]['cases'][0]['op']='equip_only'
        with self.assertRaises(ValueError): tool.validate_descriptor(self.d)
    def test_metadata_blob_is_exact(self):
        import json
        from automation_entry_v28 import SOURCE_BLOBS
        r=json.loads(tool.git('show',tool.BASE+':data/api/v2/item/1178/index.json'))
        self.assertTrue(source_metadata_supported('heavy_duty_boots',r,SOURCE_BLOBS['heavy_duty_boots']))
        self.assertFalse(source_metadata_supported('heavy_duty_boots',r,'not-the-reviewed-blob'))

    def balloon(self):
        spec=self.d['items'][0];c=spec['cases'][0]
        before={'own':{'hp':100,'item':'airballoon','consumed':False},'reserve':{'hp':100,'item':'','consumed':False}}
        frames=[]
        for i,(hp,item,popped,logs) in enumerate([(100,'airballoon',False,[]),(90,'',True,['|-enditem|p1a: own|Air Balloon']),(65,'',True,[])]):
            after=copy.deepcopy(before);after['own'].update(hp=hp,item=item,consumed=popped)
            frames.append({'before':copy.deepcopy(before),'after':after,'p1':c['p1'][i],'p2':c['p2'][i],'log':logs})
            before=after
        return spec,c,frames
    def test_real_transition_then_lost_immunity(self):
        s,c,f=self.balloon();self.assertTrue(check_frames(s,c,'active',f))
    def test_pop_label_without_native_notification_rejected(self):
        s,c,f=self.balloon();f[1]['log']=[]
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_equipped_but_does_not_block_ground_rejected(self):
        s,c,f=self.balloon();f[0]['after']['own']['hp']=75
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_consumed_but_still_immune_rejected(self):
        s,c,f=self.balloon();f[2]['after']['own']['hp']=90
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_wrong_equipment_owner_rejected(self):
        s,c,f=self.balloon()
        with self.assertRaises(ValueError): check_frames(s,c,'reserve',f)

    def boots(self):
        spec=self.d['items'][1];c=spec['cases'][0]
        before={'active_id':'own','hazards':{},'own':{'hp':160,'max_hp':160,'item':'heavydutyboots','spe':0,'status':''},'reserve':{'hp':160,'max_hp':160,'item':'','spe':0,'status':''}}
        frames=[]
        for i in range(5):
            after=copy.deepcopy(before);after['hazards']={'stealthrock':{}}
            if i:
                incoming='reserve' if i in [1,3] else 'own';after['active_id']=incoming
                if incoming=='reserve':after['reserve']['hp']-=20
            frames.append({'before':copy.deepcopy(before),'after':after,'p1':['move 1','switch_reserve','switch_own','switch_reserve','switch_own'][i],
                           'p2':'move 1' if i==0 else 'move 2','log':['|-sidestart|p1: Player|move: Stealth Rock'] if i==0 else []})
            before=after
        return spec,c,frames
    def test_hazard_owner_withdrawal_and_reentry(self):
        s,c,f=self.boots();self.assertTrue(check_frames(s,c,'active',f))
    def test_no_actual_hazard_not_a_positive(self):
        s,c,f=self.boots();f[0]['after']['hazards']={}
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_injected_hazard_rejected(self):
        s,c,f=self.boots();f[0]['before']['hazards']={'stealthrock':{}}
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_missing_placement_event_rejected(self):
        s,c,f=self.boots();f[0]['log']=[]
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_protected_owner_takes_entry_damage_rejected(self):
        s,c,f=self.boots();f[2]['after']['own']['hp']=140
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_no_reentry_rejected(self):
        s,c,f=self.boots();f.pop()
        with self.assertRaises(ValueError): check_frames(s,c,'active',f)
    def test_empty_green_report_rejected(self):
        with self.assertRaises(ValueError): validate_report(self.d,{'status':'SCOPED_VERIFIED','errors':[],'scenarios':[]},ROOT,tool.digest)

    def saved_balloon(self):
        return {'creatures':[{'instance_id':'own','held_item_id':'air_balloon','held_item_consumed':True,'current_hp':230},
                             {'instance_id':'reserve','held_item_id':'','held_item_consumed':False,'current_hp':341}],
                'inventory':{'quantities':{'air_balloon':1}}}
    def test_consumed_balloon_persists_without_recreation(self):
        validate_collection(self.saved_balloon(),'air_balloon','own','reserve','active',True,230)
    def test_saved_balloon_recreated_rejected(self):
        d=self.saved_balloon();d['creatures'][0]['held_item_consumed']=False
        with self.assertRaises(ValueError): validate_collection(d,'air_balloon','own','reserve','active',True,230)
    def test_saved_inventory_duplication_rejected(self):
        d=self.saved_balloon();d['inventory']['quantities']['air_balloon']=2
        with self.assertRaises(ValueError): validate_collection(d,'air_balloon','own','reserve','active',True,230)
    def test_saved_hp_not_native_rejected(self):
        with self.assertRaises(ValueError): validate_collection(self.saved_balloon(),'air_balloon','own','reserve','active',True,341)
    def test_saved_wrong_owner_rejected(self):
        d=self.saved_balloon();d['creatures'][0]['held_item_id']='';d['creatures'][1]['held_item_id']='air_balloon'
        with self.assertRaises(ValueError): validate_collection(d,'air_balloon','own','reserve','active',True,230)


if __name__=='__main__': unittest.main()
