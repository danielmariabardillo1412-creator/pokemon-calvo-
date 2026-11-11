'use strict';
// W01 T04/09 canonical Black Sludge end-turn effects, no invented mechanics.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const pokemon=(species_id,instance_id,moves,item='',current_hp=null)=>({
 species_id,instance_id,level:100,moves,held_item_id:item,
 ...(current_hp===null?{}:{current_hp})
});
const own=cp=>cp.roster[0].pokemon.find(x=>x.instance_id==='own');
function one(kind,mode){
 const e=new NativeEngine(),id='black_sludge_'+kind+'_'+mode;
 const species=kind==='poison'?'gengar':'mew',full=mode==='full',item=(mode==='active'||full)?'black_sludge':'';
 try{
  e.execute({op:'start',id,format:'gen9calvounifiedv1',seed:[19,2,3,4],teams:{
   p1:[pokemon(species,'own',['reflect','shadow_ball'],item,full?null:150),
       pokemon('mew','reserve',['reflect'],mode==='reserve'?'black_sludge':'')],
   p2:[pokemon('caterpie','foe',['growl'])]}});
  const b=e.execute({op:'checkpoint',id});
  const draft=e.execute({op:'prepare',id,expected_hash:b.state_hash,
   choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(e.execute({op:'checkpoint',id}).state_hash,b.state_hash,
    'Black Sludge cannot alter HP in prepare');
  const a=e.execute({op:'commit',id,draft_token:draft.draft_token});
  const delta=own(a).hp-own(b).hp;
  const expected=kind==='poison'?
    (mode==='active'?Math.max(1,Math.floor(own(a).max_hp/16)):0):
    (mode==='active'? -Math.max(1,Math.floor(own(a).max_hp/8)):0);
  assert.equal(delta,expected,'true canonical black sludge HP change '+kind+'/'+mode);
  assert.equal(own(a).item,item.replaceAll('_',''),'native item should remain equipped');
  assert.equal(a.roster[0].pokemon.find(x=>x.instance_id==='reserve').item,
   mode==='reserve'?'blacksludge':'','no activation on reserve');
  const copy=new NativeEngine();
  try{
   copy.execute({op:'restore',id:'copy',snapshot:a.snapshot});
   assert.equal(copy.execute({op:'checkpoint',id:'copy'}).state_hash,a.state_hash);
  }finally{copy.close()}
  return {kind,mode,delta,expected};
 }finally{e.close()}
}
const cases=[];
for(const mode of ['active','none','reserve','full'])cases.push(one('poison',mode));
for(const mode of ['active','none','reserve'])cases.push(one('nonpoison',mode));
assert(cases[0].delta>0&&cases[1].delta===0&&cases[2].delta===0&&cases[3].delta===0);
assert(cases[4].delta<0&&cases[5].delta===0&&cases[6].delta===0);
console.log('W01_V4_NATIVE PASS id=black_sludge modes=7 poison_heal=1 nonpoison_damage=1 full_hp=1 snapshots=7');
