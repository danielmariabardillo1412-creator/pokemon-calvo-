'use strict';
// CONTINUOUS_V2 B01/01 Ability Shield: real Gastro Acid suppression, holder vs controls.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(id,moves,item='')=>({species_id:'mew',instance_id:id,level:100,
  ability_id:'synchronize',moves,held_item_id:item});
function trial(mode){
 const e=new NativeEngine(),id='w01_b1_shield_'+mode;
 const isNeutral=mode==='neutral',active=mode==='active'||isNeutral,reserve=mode==='reserve';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[pokemon('own',['reflect','psychic'],active?'ability_shield':''),
       pokemon('reserve',['reflect'],reserve?'ability_shield':'')],
   p2:[pokemon('foe',[isNeutral?'amnesia':'gastro_acid'])]}});
  const cp=()=>e.execute({op:'checkpoint',id});
  const before=cp();
  assert.equal(e.sessions.get(id).battle.p1.active[0].ignoringAbility(),false,
    'initial real native ability active');
  const d=e.execute({op:'prepare',id,expected_hash:before.state_hash,
    choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(cp().state_hash,before.state_hash,'prepare must never change ability state');
  const after=e.execute({op:'commit',id,draft_token:d.draft_token});
  const live=e.sessions.get(id).battle.p1.active[0];
  const blocked=after.snapshot.native.log.some(x=>x.startsWith('|-block|')&&x.includes('Ability Shield'));
  const suppressed=live.ignoringAbility();
  assert.equal(blocked,active&&!isNeutral,
    'only held shield blocks actual Gastro Acid');
  assert.equal(suppressed,!active,
    'native ability suppression must differ between shield and unequipped controls');
  assert.equal(after.roster[0].pokemon.find(x=>x.instance_id==='own').item,
    active?'abilityshield':'');
  assert.equal(after.roster[0].pokemon.find(x=>x.instance_id==='reserve').item,
    reserve?'abilityshield':'');
  const restored=new NativeEngine();try{
   restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(restored.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
   assert.equal(restored.sessions.get('copy').battle.p1.active[0].ignoringAbility(),suppressed);
  }finally{restored.close()}
  return {mode,blocked,suppressed};
 }finally{e.close()}
}
const res=['active','none','reserve','neutral'].map(trial);
assert.deepEqual(res.map(x=>x.blocked),[true,false,false,false]);
assert.deepEqual(res.map(x=>x.suppressed),[false,true,true,false]);
console.log('W01_B01_NATIVE PASS id=ability_shield modes=4 block=1 controls=3 restore=4');
