'use strict';
// T04/03 native Choice Band: actual physical damage, move lock, switching reset.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(id,moves,item='')=>({instance_id:id,species_id:'mew',level:100,moves,held_item_id:item});
function trial(mode){
 const e=new NativeEngine(),id='choice_'+mode;
 const p1=[pokemon('own',['tackle','close_combat'],mode==='active'?'choice_band':''),
   pokemon('reserve',['reflect'],mode==='reserve'?'choice_band':'')];
 const p2=[pokemon('foe',['amnesia'])];
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{p1,p2}});
  const cp=()=>e.execute({op:'checkpoint',id});
  const get=(r,side,cid)=>r.roster[side].pokemon.find(p=>p.instance_id===cid);
  const take=(command)=>{
   const before=cp(),draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
     choices:{p1:command,p2:'move 1'}});
   assert.equal(cp().state_hash,before.state_hash,'prepare must be pure');
   return e.execute({op:'commit',id,draft_token:draft.draft_token});
  };
  const slot=(cid)=>{
   const sess=e.sessions.get(id),idx=sess.battle.p1.pokemon.findIndex(p=>sess.identities[p.name]===cid);
   assert(idx>=0,'target must remain in real team');return 'switch '+(idx+1);
  };
  const before=cp(),after=take('move 1');
  const damage=get(before,1,'foe').hp-get(after,1,'foe').hp;
  assert(damage>0,'genuine first physical hit');
  assert.equal(get(after,0,'own').item,mode==='active'?'choiceband':'');
  assert.equal(get(after,0,'reserve').item,mode==='reserve'?'choiceband':'');
  assert.equal(after.views.p1.request.active[0].moves[1].disabled===true,mode==='active');
  if(mode==='active'){
   assert.throws(()=>take('move 2'),'native must reject locked move');
   assert.equal(cp().state_hash,after.state_hash,'rejected move must not mutate state');
  }
  const bench=take(slot('reserve'));
  assert.equal(bench.roster[0].active_id,'reserve');
  const back=take(slot('own'));
  assert.equal(back.roster[0].active_id,'own');
  const alternate=take('move 2');
  assert.equal(get(alternate,0,'own').item,mode==='active'?'choiceband':'');
  assert(get(alternate,1,'foe').hp<=get(back,1,'foe').hp,'alternate choice real');
  if(mode==='active'){
   assert.equal(alternate.views.p1.request.active[0].moves[0].disabled,true,
      'reentry resets lock to the newly selected second move');
  }
  const restore=new NativeEngine();
  try{
   restore.execute({op:'restore',id:'copy',snapshot:alternate.snapshot});
   assert.equal(restore.execute({op:'checkpoint',id:'copy'}).state_hash,alternate.state_hash);
  }finally{restore.close()}
  return {mode,damage};
 }finally{e.close()}
}
const a=trial('active'),n=trial('none'),r=trial('reserve');
assert(a.damage>n.damage&&n.damage===r.damage,
 'Choice Band only boosts its own physical attack');
console.log('W01_V4_NATIVE PASS id=choice_band modes=3 boost=1 lock=1 reset=1 snapshots=3');
