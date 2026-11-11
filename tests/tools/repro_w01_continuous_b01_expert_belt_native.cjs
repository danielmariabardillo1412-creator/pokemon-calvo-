'use strict';
// W01 CONTINUOUS_V2 B01/05 Expert Belt native: super-effective damage ONLY.
// Native Showdown already has onModifyDamage; no copied multipliers.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(id,moves,item='',species_id='mew',hp=null)=>({
 species_id,instance_id:id,level:100,moves,held_item_id:item,
 ...(hp===null?{}:{current_hp:hp})
});
function trial(mode){
 const e=new NativeEngine(),id='b01_expert_'+mode;
 const isNeutral=mode.startsWith('neutral'),active=mode.endsWith('active'),reserve=mode==='super_reserve';
 const move=isNeutral?'tackle':'thunder_shock';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('own',[move,'psychic'],active?'expert_belt':''),
       mon('reserve',['reflect'],reserve?'expert_belt':'')],
   p2:[mon('foe',['tackle'],'','gyarados',300)]}});
  const before=e.execute({op:'checkpoint',id}),draft=e.execute({op:'prepare',id,
   expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash);
  const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const foeBefore=before.roster[1].pokemon.find(x=>x.instance_id==='foe');
  const foeAfter=after.roster[1].pokemon.find(x=>x.instance_id==='foe');
  const dealt=foeBefore.hp-foeAfter.hp;
  assert(dealt>0&&foeAfter.hp>0,'real first hit must not end encounter by KO');
  const actor=after.roster[0].pokemon.find(x=>x.instance_id==='own');
  const bench=after.roster[0].pokemon.find(x=>x.instance_id==='reserve');
  assert.equal(actor.item,active?'expertbelt':'','nonconsumable Expert Belt owner');
  assert.equal(bench.item,reserve?'expertbelt':'','reserve cannot apply belt');
  const restored=new NativeEngine();try{
   restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(restored.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
  }finally{restored.close()}
  return {mode,dealt};
 }finally{e.close()}
}
const modes=['super_active','super_none','super_reserve','neutral_active','neutral_none'];
const rows=modes.map(trial);
assert(rows[0].dealt>rows[1].dealt,'Expert Belt must increase actual super-effective damage');
assert.equal(rows[1].dealt,rows[2].dealt,'reserve belt cannot boost');
assert.equal(rows[3].dealt,rows[4].dealt,'Expert Belt must not boost neutral Tackle');
console.log('W01_B01_NATIVE PASS id=expert_belt modes=5 super_effective=1 neutral=2 snapshots=5');
