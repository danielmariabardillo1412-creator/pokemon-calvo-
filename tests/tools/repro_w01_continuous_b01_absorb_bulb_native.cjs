'use strict';
// W01 CONTINUOUS_V2 B01/02 Absorb Bulb: Water-type damaging hit -> +1 SpA, consumed.
// Wrong type, unequipped and reserve controls must never trigger.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(id,moves,item='')=>({species_id:'mew',instance_id:id,level:100,moves,held_item_id:item});
function trial(mode){
 const e=new NativeEngine(),id='w01_b1_bulb_'+mode;
 const active=mode==='active'||mode==='nonwater',reserve=mode==='reserve';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('own',['reflect','psychic'],active?'absorb_bulb':''),
       mon('reserve',['reflect'],reserve?'absorb_bulb':'')],
   p2:[mon('foe',[mode==='nonwater'?'tackle':'water_gun'])]}});
  const cp=()=>e.execute({op:'checkpoint',id}),before=cp();
  const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
    choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(cp().state_hash,before.state_hash,'prepare may not consume a held Bulb');
  const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const start=before.roster[0].pokemon.find(p=>p.instance_id==='own');
  const own=after.roster[0].pokemon.find(p=>p.instance_id==='own');
  const bench=after.roster[0].pokemon.find(p=>p.instance_id==='reserve');
  const triggered=mode==='active';
  assert(own.hp<start.hp,'actual hit must deal damage');
  assert.equal(own.boosts.spa,triggered?1:0,
    'Absorb Bulb only boosts SpA on a damaging Water move to current holder');
  assert.equal(own.item,active&&!triggered?'absorbbulb':'',
    'Water hit consumes exactly the eligible active held Bulb');
  assert.equal(bench.item,reserve?'absorbbulb':'',
    'Bulb on party reserve is not consumed');
  const copy=new NativeEngine();
  try{
   copy.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   const restored=copy.execute({op:'checkpoint',id:'copy'});
   assert.equal(restored.state_hash,after.state_hash,'item consumption/SpA boost must survive snapshot');
  }finally{copy.close()}
  return {mode,triggered,damage:start.hp-own.hp};
 }finally{e.close()}
}
const rows=['active','none','reserve','nonwater'].map(trial);
assert(rows.every(x=>x.damage>0)&&rows.filter(x=>x.triggered).length===1);
console.log('W01_B01_NATIVE PASS id=absorb_bulb modes=4 water_boost=1 negatives=3 snapshots=4');
