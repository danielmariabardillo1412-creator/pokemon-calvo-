'use strict';
// W01 TANDA04/02. True pinned Showdown damage+recoil (no patched native item).
// Four modes plus a no-damage status control, state_hash/restore after commit.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(species_id,instance_id,moves,held_item_id='',hp=null)=>({
  species_id,instance_id,level:100,moves,held_item_id,
  ...(hp===null?{}:{current_hp:hp})
});
const get=(cp,side,id)=>cp.roster[side].pokemon.find(p=>p.instance_id===id);
function trial(mode){
  const e=new NativeEngine(),bid='w01lifeorb'+mode;
  const item=(mode==='active'||mode==='immune'||mode==='status')?'life_orb':'';
  const reserve=mode==='reserve'?'life_orb':'';
  const move=mode==='status'?'move 2':'move 1';
  const foe=mode==='immune'?'gengar':'mew';
  try{
    e.execute({op:'start',id:bid,format:'gen9calvounifiedv1',
      seed:[19,2,3,4],teams:{
        p1:[mon('mew','own',['tackle','reflect'],item,250),
            mon('mew','reserve',['reflect'],reserve)],
        p2:[mon(foe,'foe',['amnesia'])]}});
    const before=e.execute({op:'checkpoint',id:bid});
    const p=get(before,0,'own'),f=get(before,1,'foe');
    assert(p&&f&&p.hp===250&&p.max_hp>250,'genuine initial HP');
    const draft=e.execute({op:'prepare',id:bid,expected_hash:before.state_hash,
      choices:{p1:move,p2:'move 1'}});
    assert.equal(e.execute({op:'checkpoint',id:bid}).state_hash,before.state_hash,
      'prepare must remain pure even with Life Orb');
    const after=e.execute({op:'commit',id:bid,draft_token:draft.draft_token});
    const hp= get(after,0,'own'),target=get(after,1,'foe');
    const dealt=f.hp-target.hp, loss=p.hp-hp.hp;
    const active=(mode==='active');
    const shouldNotDamage=['immune','status'].includes(mode);
    if(shouldNotDamage)assert.equal(dealt,0,'immune/status must do zero direct damage');
    else assert(dealt>0,'physical attack must deal actual damage');
    assert.equal(loss,active&&dealt>0?Math.floor(p.max_hp/10):0,
      'recoil only on Life Orb damaging hit');
    assert.equal(hp.item,item.replaceAll('_',''),'Life Orb must never be consumed');
    if(mode==='reserve')assert.equal(get(after,0,'reserve').item,'lifeorb',
      'bench must retain its own Life Orb without activation');
    const restored=new NativeEngine();
    try{
      restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
      assert.equal(restored.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash,
        'restore must preserve both recoil and item');
    }finally{restored.close()}
    return {mode,dealt,loss};
  }finally{e.close()}
}
const r=['active','none','reserve','immune','status'].map(trial);
assert(r[0].dealt>r[1].dealt&&r[1].dealt===r[2].dealt,
  'only attacking Life Orb holder increases damage');
assert(r[0].loss>0&&r.slice(1).every(x=>x.loss===0),
  'no recoil from bench/no item/immunity/status');
console.log('W01_V4_NATIVE PASS id=life_orb variants=5 boost=1 recoil=1 immune=1 status=1 snapshots=5');
