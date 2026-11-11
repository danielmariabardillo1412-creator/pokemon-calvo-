'use strict';
// W01 T04/07 Eviolite from actual pinned Gen9 native stats, not synthetic boost.
// Only unevolved Pidgeotto gets Defense/SpD benefit. Final Pidgeot does not.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(species_id,instance_id,moves,item='')=>({
 species_id,instance_id,level:100,moves,held_item_id:item
});
const get=(r,side,id)=>r.roster[side].pokemon.find(p=>p.instance_id===id);
function trial(species,attack,mode,seed){
 const e=new NativeEngine(),id='eviolite_'+species+'_'+attack+'_'+mode+'_'+seed;
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[seed,2,3,4],teams:{
   p1:[pokemon(species,'own',['growl','aerial_ace'],mode==='active'?'eviolite':''),
       pokemon('mew','reserve',['reflect'],mode==='reserve'?'eviolite':'')],
   p2:[pokemon('mew','foe',[attack])]}});
  const before=e.execute({op:'checkpoint',id});
  const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
     choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash,
    'prepare must not modify eviolite holder stats or party');
  const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const dealt=get(before,0,'own').hp-get(after,0,'own').hp;
  assert(dealt>0,'opponent must actually damage the native holder');
  assert.equal(get(after,0,'own').item,mode==='active'?'eviolite':'');
  assert.equal(get(after,0,'reserve').item,mode==='reserve'?'eviolite':'');
  const copy=new NativeEngine();try{
   copy.execute({op:'restore',id:'copy',snapshot:after.snapshot});
   assert.equal(copy.execute({op:'checkpoint',id:'copy'}).state_hash,after.state_hash);
  }finally{copy.close()}
  return {dealt,mode};
 }finally{e.close()}
}
let snapshots=0,positives=0,finals=0;
for(const attack of ['tackle','psychic'])for(const seed of [19,23]){
 const pre=['active','none','reserve'].map(m=>trial('pidgeotto',attack,m,seed));
 snapshots+=3;
 assert(pre[0].dealt<pre[1].dealt&&pre[1].dealt===pre[2].dealt,
  'Eviolite must reduce incoming '+attack+' only for evolving holder');
 positives++;
 const last=['active','none'].map(m=>trial('pidgeot',attack,m,seed));
 snapshots+=2;
 assert.equal(last[0].dealt,last[1].dealt,
  'fully evolved Pidgeot must not receive defensive Eviolite boost');
 finals++;
}
console.log('W01_V4_NATIVE PASS id=eviolite types=2 seeds=2 pre_positive=4 final_negative=4 snapshots='+snapshots);
