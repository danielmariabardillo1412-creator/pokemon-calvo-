'use strict';
// W01/08 Safety Goggles. Real pinned Showdown powder/status and sandstorm residual.
// No production hooks altered; inspect committed native status, HP, log, and restore.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(species_id,instance_id,moves,item='')=>({species_id,instance_id,level:100,moves,held_item_id:item});
const own=cp=>cp.roster[0].pokemon.find(p=>p.instance_id==='own');
function probe(effect,mode){
 const e=new NativeEngine(),id='goggles_'+effect+'_'+mode;
 const foe=effect==='powder'?'breloom':'mew';
 const foeMove=effect==='powder'?'spore':effect==='weather'?'sandstorm':'amnesia';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[mon('mew','own',['reflect','psychic'],mode==='active'?'safety_goggles':''),
       mon('mew','reserve',['reflect'],mode==='reserve'?'safety_goggles':'')],
   p2:[mon(foe,'foe',[foeMove])]}});
  const before=e.execute({op:'checkpoint',id});
  const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
   choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash,
   'prepare must not apply weather, sleep or consume item');
  const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const battle=e.sessions.get(id).battle;
  const status=battle.p1.active[0].status;
  const loss=own(before).hp-own(after).hp;
  const expectedStatus=effect==='powder'&&mode!=='active'?'slp':'';
  assert.equal(status,expectedStatus, 'native Spore must affect only non-holder '+effect+'/'+mode);
  if(effect==='weather')assert(mode==='active'?loss===0:loss>0,
   'Safety Goggles must prevent native sandstorm residual only for holder '+mode);
  else assert.equal(loss,0,'powder and neutral control should not alter HP');
  assert.equal(own(after).item,mode==='active'?'safetygoggles':'');
  assert.equal(after.roster[0].pokemon.find(p=>p.instance_id==='reserve').item,
   mode==='reserve'?'safetygoggles':'');
  const moveLog=after.snapshot.native.log.filter(x=>x.startsWith('|move|'));
  assert(moveLog.some(x=>x.toLowerCase().includes(foeMove)),
   'foe must actually use '+foeMove);
  const other=new NativeEngine();try{
   other.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(other.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
  }finally{other.close()}
  return {effect,mode,status,loss};
 }finally{e.close()}
}
const entries=[];
for(const effect of ['powder','weather','neutral'])
 for(const mode of effect==='neutral'?['active','none']:['active','none','reserve'])
  entries.push(probe(effect,mode));
assert.equal(entries.length,8);
console.log('W01_V4_NATIVE PASS id=safety_goggles modes=8 powder=3 weather=3 neutral=2 snapshots=8');
