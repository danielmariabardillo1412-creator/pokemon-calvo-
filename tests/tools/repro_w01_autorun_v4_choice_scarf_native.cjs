'use strict';
// W01 TANDA04/05: authoritative @pkmn/sim speed-order and priority, not fake RNG.
// A Choice Scarf changes speed and choice-lock, never move priority.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const make=(species_id,id,moves,item='')=>({species_id,instance_id:id,level:100,moves,held_item_id:item});
function trial(mode){
 const e=new NativeEngine(),id='w01scarf_'+mode;
 const equipped=mode==='active'||mode==='priority';
 const p1=[make('mew','own',['tackle','earth_power'],equipped?'choice_scarf':''),
           make('mew','reserve',['reflect'],mode==='reserve'?'choice_scarf':'')];
 const p2=[make('jolteon','foe',['tackle','quick_attack'])];
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{p1,p2}});
  const battle=e.sessions.get(id).battle;
  const p1Speed=battle.p1.active[0].getStat('spe');
  const p2Speed=battle.p2.active[0].getStat('spe');
  assert(equipped?p1Speed>p2Speed:p1Speed<p2Speed,
    'native stat must reflect Choice Scarf speed, not fake initiative');
  const cp=()=>e.execute({op:'checkpoint',id});
  const take=(own='move 1',other='move 1')=>{
   const before=cp(),draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
    choices:{p1:own,p2:other}});
   assert.equal(cp().state_hash,before.state_hash,'preparation mutates combat');
   return e.execute({op:'commit',id,draft_token:draft.draft_token});
  };
  const first=take('move 1',mode==='priority'?'move 2':'move 1');
  // NativeEngine checkpoints own the official log; battle.log is empty by adapter design.
  // Parse the actual committed snapshot log, never a fake move-order assumption.
  const turns=first.snapshot.native.log.filter(x=>x.startsWith('|move|'));
  assert(turns.length>=2,'must observe two actual committed native move events');
  const order=turns.slice(-2).map(row=>{
    const m=/^\|move\|p([12])a:/.exec(row);return m?Number(m[1]):null;
  });
  const expectOrder=equipped&&mode!=='priority'?[1,2]:[2,1];
  assert.deepEqual(order,expectOrder,
    'Choice Scarf must reverse speed order, not move priority '+mode);
  const held=first.roster[0].pokemon;
  assert.equal(held.find(x=>x.instance_id==='own').item,equipped?'choicescarf':'');
  assert.equal(held.find(x=>x.instance_id==='reserve').item,mode==='reserve'?'choicescarf':'');
  assert.equal(first.views.p1.request.active[0].moves[1].disabled===true,equipped);
  if(equipped){
   assert.throws(()=>take('move 2'),'native choice lock must reject alternate');
   assert.equal(cp().state_hash,first.state_hash,'rejected choice must be pure');
  }
  const switchTo=cid=>{
   const ix=battle.p1.pokemon.findIndex(p=>e.sessions.get(id).identities[p.name]===cid);
   assert(ix>=0,'canonical bench identity required');return 'switch '+(ix+1);
  };
  const bench=take(switchTo('reserve'));
  assert.equal(bench.roster[0].active_id,'reserve');
  const back=take(switchTo('own'));
  assert.equal(back.roster[0].active_id,'own');
  if(equipped)assert.equal(back.views.p1.request.active[0].moves[1].disabled,false,
   'switch must reset choice lock to allow a new move');
  const newMove=take('move 2');
  if(equipped)assert.equal(newMove.views.p1.request.active[0].moves[0].disabled,true,
    'new chosen move must become exclusively available');
  const restore=new NativeEngine();
  try{
   restore.execute({op:'restore',id:'copy',snapshot:newMove.snapshot});
   assert.equal(restore.execute({op:'checkpoint',id:'copy'}).state_hash,newMove.state_hash);
  }finally{restore.close()}
  return {mode,order,p1Speed,p2Speed};
 }finally{e.close()}
}
const cases=['active','none','reserve','priority'].map(trial);
assert.deepEqual(cases[0].order,[1,2]);
assert.deepEqual(cases[1].order,[2,1]);
assert.deepEqual(cases[2].order,[2,1]);
assert.deepEqual(cases[3].order,[2,1]);
console.log('W01_V4_NATIVE PASS id=choice_scarf modes=4 speed_order=1 priority_override=1 lock_reset=1 snapshots=4');
