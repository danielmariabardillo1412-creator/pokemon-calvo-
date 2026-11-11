'use strict';
// W01 CONTINUOUS_V2 B01/04: Big Root boosts draining heal, not attack damage.
// Real native Absorb vs Swampert 4x weak to Grass; no synthetic multipliers.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(id,moves,item='',species_id='mew',hp=null)=>({
 species_id,instance_id:id,level:100,moves,held_item_id:item,
 ...(hp===null?{}:{current_hp:hp})
});
const own=cp=>cp.roster[0].pokemon.find(x=>x.instance_id==='own');
const foe=cp=>cp.roster[1].pokemon.find(x=>x.instance_id==='foe');
function trial(mode){
 const e=new NativeEngine(),id='b01_big_root_'+mode;
 const held=mode==='active'||mode==='no_drain',reserve=mode==='reserve';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('own',[mode==='no_drain'?'tackle':'absorb','psychic'],held?'big_root':'','mew',120),
       mon('reserve',['reflect'],reserve?'big_root':'')],
   p2:[mon('foe',['growl'],'','swampert',200)]}});
  const cp=()=>e.execute({op:'checkpoint',id}),before=cp();
  const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
   choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(cp().state_hash,before.state_hash,'prepare must not heal owner');
  const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const damaged=foe(before).hp-foe(after).hp;
  const healed=own(after).hp-own(before).hp;
  assert(damaged>0,'genuine native move must damage foe');
  assert(healed>=0,'no initial negative HP delta');
  if(mode==='no_drain')assert.equal(healed,0,'Big Root cannot heal non-draining Tackle');
  else assert(healed>0,'Absorb must actually restore lost HP');
  assert.equal(own(after).item,held?'bigroot':'','Big Root is not consumable');
  assert.equal(after.roster[0].pokemon.find(x=>x.instance_id==='reserve').item,
   reserve?'bigroot':'','reserve Big Root remains held');
  const restored=new NativeEngine();try{
   restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(restored.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
  }finally{restored.close()}
  return {mode,healed,damaged};
 }finally{e.close()}
}
const rows=['active','none','reserve','no_drain'].map(trial);
assert.equal(rows[0].damaged,rows[1].damaged,
 'Big Root must not increase Grass damage');
assert.equal(rows[1].damaged,rows[2].damaged,
 'reserve must not alter damage');
assert(rows[0].healed>rows[1].healed&&rows[1].healed===rows[2].healed,
 'Big Root boosts ONLY drain healing for active holder');
assert.equal(rows[3].healed,0);
console.log('W01_B01_NATIVE PASS id=big_root modes=4 drain_boost=1 wrong_move=1 snapshots=4');
