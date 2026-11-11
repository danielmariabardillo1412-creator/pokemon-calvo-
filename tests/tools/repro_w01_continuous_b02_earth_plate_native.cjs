'use strict';
// W01 CONTINUOUS_V2 B02/10 Earth Plate: Ground-type damage only, no Arceus form changes.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(id,moves,item='',species_id='mew',hp=null)=>({
 species_id,instance_id:id,level:100,moves,held_item_id:item,
 ...(hp===null?{}:{current_hp:hp})
});
function trial(mode){
 const e=new NativeEngine(),id='b02_earth_'+mode;
 const ground=mode.endsWith('ground'),active=mode.startsWith('active'),reserve=mode.startsWith('reserve');
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('own',[ground?'earth_power':'tackle','psychic'],active?'earth_plate':''),
       mon('reserve',['reflect'],reserve?'earth_plate':'')],
   p2:[mon('foe',['tackle'],'','garchomp',300)]}});
  const before=e.execute({op:'checkpoint',id}),d=e.execute({op:'prepare',id,
   expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash);
  const after=e.execute({op:'commit',id,draft_token:d.draft_token});
  const bef=before.roster[1].pokemon.find(p=>p.instance_id==='foe');
  const aft=after.roster[1].pokemon.find(p=>p.instance_id==='foe');
  const delta=bef.hp-aft.hp;
  assert(delta>0&&aft.hp>0,'must measure actual nonlethal native damage');
  const own=after.roster[0].pokemon.find(p=>p.instance_id==='own');
  assert.equal(own.species_id,'mew','Plate must not change holder species or form');
  assert.equal(own.item,active?'earthplate':'','Earth Plate must not be consumed');
  assert.equal(after.roster[0].pokemon.find(p=>p.instance_id==='reserve').item,
    reserve?'earthplate':'','reserve must keep its Plate');
  const copy=new NativeEngine();try{
   copy.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(copy.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
  }finally{copy.close()}
  return {mode,delta};
 }finally{e.close()}
}
const rows=['active_ground','none_ground','reserve_ground','active_wrong','none_wrong'].map(trial);
assert(rows[0].delta>rows[1].delta,'Ground move must gain item boost only while held by attacker');
assert.equal(rows[1].delta,rows[2].delta,'reserve Plate does not boost');
assert.equal(rows[3].delta,rows[4].delta,'Earth Plate does not boost non-Ground Tackle');
console.log('W01_B02_NATIVE PASS id=earth_plate modes=5 type_boost=1 wrong_type=2 snapshots=5');
