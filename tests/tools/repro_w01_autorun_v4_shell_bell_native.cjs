'use strict';
// W01 TANDA04/06 — genuine Shell Bell healing proportional to HP actually lost by foe.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(species_id,instance_id,moves,item='',current_hp=null)=>({
 species_id,instance_id,level:100,moves,held_item_id:item,
 ...(current_hp===null?{}:{current_hp})
});
const get=(r,side,id)=>r.roster[side].pokemon.find(p=>p.instance_id===id);
function trial(mode){
 const engine=new NativeEngine(),id='shell_'+mode,active=mode==='active'||mode==='immune'||mode==='status';
 const reserved=mode==='reserve', foe=mode==='immune'?'gengar':'mew';
 try{
  engine.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[pokemon('mew','own',['tackle','reflect','shadow_ball'],active?'shell_bell':'',150),
       pokemon('mew','reserve',['reflect'],reserved?'shell_bell':'')],
   p2:[pokemon(foe,'foe',['amnesia'])]}});
  const before=engine.execute({op:'checkpoint',id});
  const choice=mode==='status'?'move 2':'move 1';
  const draft=engine.execute({op:'prepare',id,expected_hash:before.state_hash,
   choices:{p1:choice,p2:'move 1'}});
  assert.equal(engine.execute({op:'checkpoint',id}).state_hash,before.state_hash,
   'prepare cannot heal owner or consume Shell Bell');
  const after=engine.execute({op:'commit',id,draft_token:draft.draft_token});
  const dealt=get(before,1,'foe').hp-get(after,1,'foe').hp;
  const gain=get(after,0,'own').hp-get(before,0,'own').hp;
  const expected=active&&dealt>0?Math.max(1,Math.floor(dealt/8)):0;
  assert.equal(gain,expected,'Shell Bell heal must equal 1/8 real damage dealt '+mode);
  assert.equal(dealt>0,['active','none','reserve'].includes(mode),
   'immune/status negative must not inflict damage '+mode);
  assert.equal(get(after,0,'own').item,active?'shellbell':'',
    'nonconsumable active item must not disappear '+mode);
  assert.equal(get(after,0,'reserve').item,reserved?'shellbell':'',
    'reserve Shell Bell must retain identity');
  const copy=new NativeEngine();try{
   copy.execute({op:'restore',id:'restored',snapshot:after.snapshot});
   assert.equal(copy.execute({op:'checkpoint',id:'restored'}).state_hash,after.state_hash);
  }finally{copy.close()}
  return {mode,dealt,gain};
 }finally{engine.close()}
}
const rows=['active','none','reserve','immune','status'].map(trial);
assert(rows[0].dealt>0&&rows[0].gain>0);
assert(rows.slice(1).every(x=>x.gain===0));
assert(rows[0].dealt===rows[1].dealt&&rows[1].dealt===rows[2].dealt,
 'Shell Bell heals but must not boost attack damage');
console.log('W01_V4_NATIVE PASS id=shell_bell modes=5 proportional=1 no_damage=2 snapshots=5');
