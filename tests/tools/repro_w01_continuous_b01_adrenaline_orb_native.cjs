'use strict';
// W01 CONTINUOUS_V2 B01/03: Adrenaline Orb on Intimidate -1 Atk -> +1 Spe and spend.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(id,moves,item='',species_id='mew',ability_id='')=>({
 species_id,instance_id:id,level:100,moves,held_item_id:item,...(ability_id?{ability_id}:{})
});
function one(mode){
 const e=new NativeEngine(),id='b01_orb_'+mode;
 const neutral=mode==='neutral',held=mode==='active'||neutral,reserve=mode==='reserve';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('own',['reflect','thunder_shock'],held?'adrenaline_orb':'','mew','synchronize'),
       mon('reserve',['reflect'],reserve?'adrenaline_orb':'','mew','synchronize')],
   p2:[neutral?mon('foe',['tackle'],'','mew','synchronize'):
       mon('foe',['tackle'],'','gyarados','intimidate')]}});
  const cp=()=>e.execute({op:'checkpoint',id});
  const before=cp();
  const d=e.execute({op:'prepare',id,expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(cp().state_hash,before.state_hash,'preparing a turn cannot change boosted speed');
  const after=e.execute({op:'commit',id,draft_token:d.draft_token});
  const own=after.roster[0].pokemon.find(p=>p.instance_id==='own');
  const bench=after.roster[0].pokemon.find(p=>p.instance_id==='reserve');
  assert.equal(own.boosts.atk,neutral?0:-1,'Intimidate must truly lower Attack of current actor');
  assert.equal(own.boosts.spe,mode==='active'?1:0,
   'Adrenaline Orb only raises holder Speed when actual Intimidate lowered Attack');
  assert.equal(own.item,neutral?'adrenalineorb':'',
   'Adrenaline Orb is spent only after qualifying Intimidate');
  assert.equal(bench.item,reserve?'adrenalineorb':'','reserve Orb is not used');
  const clone=new NativeEngine();try{
   clone.execute({op:'restore',id:'reloaded',snapshot:after.snapshot});
   assert.equal(clone.execute({op:'checkpoint',id:'reloaded'}).state_hash,after.state_hash);
  }finally{clone.close()}
  return {mode,atk:own.boosts.atk,spe:own.boosts.spe};
 }finally{e.close()}
}
const result=['active','none','reserve','neutral'].map(one);
assert.deepEqual(result.map(x=>x.spe),[1,0,0,0]);
console.log('W01_B01_NATIVE PASS id=adrenaline_orb modes=4 intimidate=1 controls=3 restore=4');
