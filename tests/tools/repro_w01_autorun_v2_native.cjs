'use strict';
// W01 AUTORUN V2, TANDA02 — tests over the real pinned @pkmn/sim 0.10.11.
// Native held item consumption uses the existing onSourceTryPrimaryHit hook.
// No rule override, mocked outcome, invented boost multiplier, or production edit.
const assert = require('node:assert/strict');
const {NativeEngine} = require('../../modules/battle/backends/showdown/native_engine.cjs');
const fixture = require('../fixtures/parallel_items/w01_autorun_v2.json');
const v1 = require('../fixtures/parallel_items/w01_autorun_v1.json');
const original = [
  ['normal_gem','normal','tackle'],
  ['fire_gem','fire','fire_punch'],
  ['water_gem','water','surf']
];
const mon=(species_id,instance_id,moves,held_item_id='')=>
  ({species_id,instance_id,level:100,moves,held_item_id});
const start=(e,{id,move,mode='active',seed=19,foe='mew',foeMoves=['amnesia'],
  actor='mew',actorMoves=null})=>{
  const active=mode==='active'?id:'';
  const reserved=mode==='reserve'?id:'';
  e.execute({op:'start',id:'battle',format:'gen9calvounifiedv1',seed:[seed,2,3,4],
    teams:{p1:[mon(actor,'own',actorMoves??[move,'reflect'],active),
      mon('mew','reserve',['reflect'],reserved)],
      p2:[mon(foe,'foe',foeMoves)]}});
  return e.sessions.get('battle').battle;
};
const take=(e,choice='move 1')=>{
  const cp=e.execute({op:'checkpoint',id:'battle'});
  const draft=e.execute({op:'prepare',id:'battle',expected_hash:cp.state_hash,
    choices:{p1:choice,p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id:'battle'}).state_hash,cp.state_hash,
    'prepare cannot spend PP or consume item');
  return e.execute({op:'commit',id:'battle',draft_token:draft.draft_token});
};
let snapshots=0;
function save(snapshot) {
  const next=new NativeEngine();
  try{
    next.execute({op:'restore',id:'copy',snapshot:snapshot.snapshot});
    assert.equal(next.execute({op:'checkpoint',id:'copy'}).state_hash,snapshot.state_hash,
      'snapshot restore must retain authoritative item and PP state');
    snapshots++;
  }finally{next.close();}
}
const current=(e)=>e.execute({op:'checkpoint',id:'battle'});
const pick=(result,side,id)=>result.roster[side].pokemon.find(p=>p.instance_id===id);
const moveId=s=>s.replace(/_/g,'');
function play({id,move,mode='active',seed=19,type=null,twoTurns=false,foe='mew',
  foeMoves=['amnesia']}) {
  const e=new NativeEngine();
  try{
    const battle=start(e,{id,move,mode,seed,foe,foeMoves});
    const actualType=battle.dex.moves.get(moveId(move));
    assert(actualType.exists,'Missing move '+move);
    if(type)assert.equal(actualType.type.toLowerCase(),type,'Wrong move type for '+id);
    const slot=battle.p1.active[0].moveSlots.find(m=>m.id===moveId(move));
    assert(slot&&slot.pp>1,'Missing positive PP '+move);
    const pp0=slot.pp;
    const before=current(e),after=take(e),mine=pick(after,0,'own'),foe1=pick(after,1,'foe');
    assert(mine&&foe1,'Lost creature identity');
    const damage=pick(before,1,'foe').hp-foe1.hp;
    const live=e.sessions.get('battle').battle;
    const pp1=live.p1.active[0].moveSlots.find(m=>m.id===moveId(move))?.pp;
    assert.equal(pp0-pp1,1,'one PP consumed on first move');
    save(after);
    let after2=null;
    if(twoTurns){
      assert.equal(mode,'active');
      assert.equal(mine.item,'','first matching attack must consume once');
      const switched=take(e,'switch 2');
      assert.equal(switched.roster[0].active_id,'reserve');
      const returned=take(e,'switch 2');
      assert.equal(returned.roster[0].active_id,'own');
      assert.equal(pick(returned,0,'own').item,'','spent item restored on return');
      after2=take(e,'move 1');
      assert.equal(pick(after2,0,'own').item,'','item spent twice/returned');
      assert(pick(after2,1,'foe').hp<foe1.hp,'second hit must cause real damage');
      const pp2=e.sessions.get('battle').battle.p1.active[0].moveSlots.find(m=>m.id===moveId(move))?.pp;
      assert.equal(pp1-pp2,1,'PP must decrement again after reentry');
      save(after2);
    }
    return {item:mine.item,damage, reserveItem:pick(after,0,'reserve')?.item,
      log:after.snapshot.log||[],second:after2};
  }finally{e.close()}
}
function metadata() {
  const refs=[...original,...v1.items.map(x=>[x.id,x.type,x.attack]),
    ...fixture.items.map(x=>[x.id,x.type,x.attack])];
  assert.equal(refs.length,18,'exact 18 canonical gem types required');
  assert.equal(new Set(refs.map(x=>x[0])).size,18,'duplicate gem ID');
  assert.equal(new Set(refs.map(x=>x[1])).size,18,'missing or duplicate gem type');
  const engine=new NativeEngine();
  try{
    const b=start(engine,{id:'ghost_gem',move:'shadow_ball'});
    for(const [id,type,move] of refs){
      const item=b.dex.items.get(moveId(id));
      assert(item.exists,'No canonical native item '+id);
      assert.equal(b.dex.moves.get(moveId(move)).type.toLowerCase(),type,
        'Invalid canonical move mapping for '+id);
      assert(item.onSourceTryPrimaryHit||item.onBasePower,
        'No canonical held Gem offensive hook: '+id);
    }
  }finally{engine.close()}
  console.log('W01_V2_MATRIX PASS types=18 unique=18 old_c005=3 old_v1=10 new_v2=5');
}
let activations=0,negatives=0;
function primary(){
  for(let i=0;i<fixture.items.length;i++){
    const entry=fixture.items[i];
    const {id,type,attack,wrong,status}=entry;
    const row=String(i+1).padStart(2,'0');
    assert.equal(entry.row,row);
    for(const seed of [19,23]){
      const active=play({id,move:attack,type,seed,twoTurns:true});
      const none=play({id,move:attack,type,seed,mode:'none'});
      const reserve=play({id,move:attack,type,seed,mode:'reserve'});
      assert(active.damage>none.damage&&none.damage>0&&none.damage===reserve.damage,
        id+' active holder must be sole matching-type boost');
      assert.equal(active.item,'','activated Gem must disappear');
      assert.equal(reserve.reserveItem,moveId(id),'reserve must retain original Gem');
      activations++;
    }
    const bad=play({id,move:wrong}),badNone=play({id,move:wrong,mode:'none'});
    assert.equal(bad.damage,badNone.damage,'wrong type changed damage '+id);
    assert(bad.damage>0,'wrong type control not damaging '+id);
    assert.equal(bad.item,moveId(id),'wrong type consumed '+id);
    const statusGem=play({id,move:status,type});
    assert.equal(statusGem.item,moveId(id),'status wrongly consumed '+id);
    assert.equal(statusGem.damage,0,'same-type status caused direct damage '+id);
    negatives+=2;
    console.log('W01_V2_NATIVE_ROW PASS row='+row+' id='+id+
      ' positives=2 negatives=2 SaveV2=verified');
  }
}
function immune(){
  for(const [id,move,foe] of [
    ['ghost_gem','shadow_ball','snorlax'],
    ['fighting_gem','brick_break','gengar']]){
    const a=play({id,move,foe}),n=play({id,move,foe,mode:'none'});
    assert.equal(a.damage,0,'immunity must have zero damage for '+id);
    assert.equal(a.damage,n.damage,'immunity must not boost '+id);
    assert.equal(a.item,moveId(id),'immune defender consumed Gem '+id);
  }
  console.log('W01_V2_IMMUNITY PASS cases=2');
}
function miss(){
  let hits=0,misses=0;
  for(let seed=1;seed<=64;seed++){
    const a=play({id:'steel_gem',move:'iron_tail',seed});
    if(a.damage===0) {
      assert.equal(a.item,'steelgem','miss consumed Steel Gem at seed '+seed);
      misses++;
    } else {
      assert.equal(a.item,'','successful Steel hit must consume gem');
      hits++;
    }
  }
  assert(hits>0&&misses>0,'RNG witness positive and missed branches required');
  console.log('W01_V2_MISS PASS hits='+hits+' misses='+misses);
}
function swapSlots(){
  const e=new NativeEngine();
  try{
    const b=start(e,{id:'ghost_gem',move:'reflect',actorMoves:['reflect','shadow_ball']});
    assert.equal(b.p1.active[0].moveSlots.length,2);
    const original=current(e),afterStatus=take(e,'move 1');
    assert.equal(pick(afterStatus,0,'own').item,'ghostgem',
      'status first slot must retain Gem');
    assert.equal(pick(afterStatus,1,'foe').hp,pick(original,1,'foe').hp);
    save(afterStatus);
    const afterAttack=take(e,'move 2');
    assert.equal(pick(afterAttack,0,'own').item,'','second slot must consume Gem');
    assert(pick(afterAttack,1,'foe').hp<pick(afterStatus,1,'foe').hp);
    save(afterAttack);
    const switched=take(e,'switch 2');
    assert.equal(switched.roster[0].active_id,'reserve');
    const back=take(e,'switch 2');
    assert.equal(back.roster[0].active_id,'own');
    assert.equal(pick(back,0,'own').item,'','slot order switch re-equipped Gem');
    save(back);
    console.log('W01_V2_SLOTS PASS status_first=1 second_slot_trigger=1 switch_reentry=1');
  }finally{e.close()}
}
function transform(){
  const e=new NativeEngine();
  try{
    const b=start(e,{id:'ghost_gem',move:'transform',actor:'ditto',
      actorMoves:['transform','reflect'],foe:'mew',foeMoves:['shadow_ball','amnesia']});
    assert.equal(b.p1.active[0].species.id,'ditto');
    const initial=current(e),state=take(e,'move 1');
    assert.equal(pick(state,0,'own').item,'ghostgem',
      'Gem consumed during Transform status');
    assert(e.sessions.get('battle').battle.p1.active[0].transformed,
      'Ditto transform event absent');
    save(state);
    const next=take(e,'move 1');
    assert.equal(pick(next,0,'own').item,'','Gem must activate on transformed Ghost hit');
    assert(pick(next,1,'foe').hp<pick(state,1,'foe').hp,
      'transformed Ghost must produce real damage');
    save(next);
    console.log('W01_V2_TRANSFORM PASS status_retains=1 transformed_hit_consumes=1 snapshots=2');
  }finally{e.close()}
}
metadata();
primary();
immune();
miss();
swapSlots();
transform();
console.log('W01_V2_NATIVE PASS rows=5 activations='+activations+
  ' negatives='+negatives+' snapshots='+snapshots);
