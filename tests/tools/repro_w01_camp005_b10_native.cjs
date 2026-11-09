'use strict';
// IA1/W01 CAMPAÑA_005 B10. Read-only tests of Showdown Gem semantics.
// No production modification, no RNG mocking. Real prepare/commit/restore.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const fixture=(species_id,instance_id,moves,item='')=>({
  species_id,instance_id,level:100,moves,held_item_id:item
});
const all=[
 ['normal_gem','tackle','water_gun','swords_dance'],
 ['fire_gem','fire_punch','tackle','sunny_day'],
 ['water_gem','surf','tackle','rain_dance']
];
let snapshots=0,consumed=0,retained=0,secondTurns=0;
function play(item,move,seed=19,reserveItem='',twoTurns=false) {
 const e=new NativeEngine();
 try{
  e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',seed:[seed,2,3,4],
   teams:{p1:[fixture('mew','own',[move,'reflect'],item),
     fixture('mew','reserve',['reflect'],reserveItem)],
     p2:[fixture('mew','foe',['amnesia'])]}});
  const cp0=e.execute({op:'checkpoint',id:'a'});
  const commit=()=>{
   const cp=e.execute({op:'checkpoint',id:'a'});
   const draft=e.execute({op:'prepare',id:'a',expected_hash:cp.state_hash,
       choices:{p1:'move 1',p2:'move 1'}});
   assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,cp.state_hash,
       'Prepare must not commit unexpectedly');
   return e.execute({op:'commit',id:'a',draft_token:draft.draft_token});
  };
  const after=commit();
  const cp1=e.execute({op:'checkpoint',id:'a'});
  const own=after.roster[0].pokemon.find(p=>p.instance_id==='own');
  const foe=after.roster[1].pokemon.find(p=>p.instance_id==='foe');
  const foeBefore=cp0.roster[1].pokemon.find(p=>p.instance_id==='foe');
  assert(own&&foe&&foeBefore,'Battle roster identities must remain stable');
  const damage=foeBefore.hp-foe.hp;
  const restored=new NativeEngine();
  try{
   restored.execute({op:'restore',id:'saved',snapshot:after.snapshot});
   assert.equal(restored.execute({op:'checkpoint',id:'saved'}).state_hash,after.state_hash,
      'Checkpoint must survive native restore without item duplication');
   snapshots++;
  }finally{restored.close();}
  let second=null;
  if(twoTurns){
   const after2=commit();
   const own2=after2.roster[0].pokemon.find(p=>p.instance_id==='own');
   const foe2=after2.roster[1].pokemon.find(p=>p.instance_id==='foe');
   second={item:own2.item,damage:foe.hp-foe2.hp};
   assert(second.damage>0,'Second legal attack must deal positive actual damage');
   const restored2=new NativeEngine();
   try{
    restored2.execute({op:'restore',id:'saved2',snapshot:after2.snapshot});
    assert.equal(restored2.execute({op:'checkpoint',id:'saved2'}).state_hash,after2.state_hash);
    snapshots++;
   }finally{restored2.close();}
   secondTurns++;
  }
  return {item:own.item,damage,second,cp1};
 }finally{e.close();}
}
for(const [id,move,other,status] of all){
 for(const seed of [19,23]){
  const active=play(id,move,seed,'',true);
  const none=play('',move,seed);
  const reserve=play('',move,seed,id);
  assert(active.damage>none.damage&&none.damage>0&&reserve.damage===none.damage,
    id+' must boost only matching type on real active holder');
  assert.equal(active.item,'',id+' must be removed on first damaging activation');
  assert.equal(active.second.item,'',id+' must not reappear or consume twice');
  assert.equal(none.item,'');
  assert.equal(reserve.item,'');
  consumed++;
 }
 const wrong=play(id,other,19);
 const wrongNone=play('',other,19);
 assert.equal(wrong.damage,wrongNone.damage,id+' cannot boost incorrect type');
 assert.equal(wrong.item,id.replace(/_/g,''),id+' must survive mismatched type');
 retained++;
 const state=play(id,status,19);
 assert.equal(state.damage,0,'A same-type status move cannot inflict damage');
 assert.equal(state.item,id.replace(/_/g,''),'Same-type status cannot consume '+id);
 retained++;
}
console.log('W01_B10_NATIVE PASS consumed='+consumed+' retained='+retained+
 ' double_actions='+secondTurns+' snapshots='+snapshots);
