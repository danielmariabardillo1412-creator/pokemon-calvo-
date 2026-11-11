'use strict';
// W01/10 Sitrus Berry HE﻿LD battle QA only. No edits to W02 field-healing ownership.
// Native trigger at <= 50% HP, 1/4 maximum recovery, spent exactly once.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(species_id,instance_id,moves,item='',hp=null)=>({
 species_id,instance_id,level:100,moves,held_item_id:item,
 ...(hp===null?{}:{current_hp:hp})
});
const get=(cp,id)=>cp.roster[0].pokemon.find(p=>p.instance_id===id);
const cases=[
 {name:'active_low',holder:'active',hp:120,consume:true},
 {name:'active_at_half',holder:'active',hp:170,consume:true},
 {name:'active_above_half',holder:'active',hp:171,consume:false},
 {name:'active_full',holder:'active',hp:null,consume:false},
 {name:'none_low',holder:'none',hp:120,consume:false},
 {name:'reserve_low',holder:'reserve',hp:120,consume:false}
];
function run(t){
 const e=new NativeEngine(),id='sitrus_'+t.name;
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[pokemon('mew','own',['reflect','tackle'],t.holder==='active'?'sitrus_berry':'',t.hp),
       pokemon('mew','reserve',['reflect'],t.holder==='reserve'?'sitrus_berry':'')],
   p2:[pokemon('caterpie','foe',['growl'])]}});
  const cp=()=>e.execute({op:'checkpoint',id});
  const initial=cp(),mon=get(initial,'own');
  assert(mon&&mon.max_hp>=340,'canonical Mew stats must be available');
  assert(t.name!=='active_at_half'|| t.hp===Math.floor(mon.max_hp/2),
   'boundary half case must match actual max HP exactly');
  assert(t.name!=='active_above_half'|| t.hp===Math.floor(mon.max_hp/2)+1,
   'above-half case must match native max HP exactly');
  const step=()=>{
   const before=cp(),d=e.execute({op:'prepare',id,expected_hash:before.state_hash,
     choices:{p1:'move 1',p2:'move 1'}});
   assert.equal(cp().state_hash,before.state_hash,'Sitrus cannot trigger in prepare');
   return e.execute({op:'commit',id,draft_token:d.draft_token});
  };
  // Showdown may eat a held Sitrus immediately at battle entry when HP
  // already satisfies the trigger. Test the true native start checkpoint,
  // then ensure neither subsequent turn re-applies the effect.
  const quarter=Math.floor(mon.max_hp/4);
  const heal=t.consume?quarter:0;
  const rawHP=t.hp===null?mon.max_hp:t.hp;
  assert.equal(mon.hp,rawHP+heal,
   'native battle entry must heal exactly one quarter at or below half HP');
  assert.equal(mon.item,(t.holder==='active'&&!t.consume)?'sitrusberry':'',
   'battle entry consumes only eligible active holder');
  const first=step(),own1=get(first,'own'),bench1=get(first,'reserve');
  assert.equal(own1.hp,mon.hp,'no second consumption or duplicate heal on first turn');
  assert.equal(own1.item,mon.item,'spent state must survive first turn');
  assert.equal(bench1.item,t.holder==='reserve'?'sitrusberry':'',
   'Reserve berry must never trigger');
  const again=step(),own2=get(again,'own');
  assert.equal(own2.hp,own1.hp,'second native turn cannot consume duplicate or double heal');
  assert.equal(own2.item,own1.item,'spent status must persist across turns');
  const copy=new NativeEngine();
  try{
   copy.execute({op:'restore',id:'reload',snapshot:again.snapshot});
   assert.equal(copy.execute({op:'checkpoint',id:'reload'}).state_hash,again.state_hash,
    'Sitrus consumed flag and HP persist in native snapshot');
  }finally{copy.close()}
  return {name:t.name,healed:heal,consumed:t.consume};
 }finally{e.close()}
}
const results=cases.map(run);
assert.equal(results.filter(r=>r.consumed).length,2);
console.log('W01_V4_NATIVE PASS id=sitrus_berry modes=6 threshold=2 one_use=1 snapshots=6');
