'use strict';
// IA1/W01 AUTORUN_V1: native Showdown real, ten canonical Gems and 3 control modes.
// The item's actual onSourceTryPrimaryHit hook supplies damage, no fake multiplier.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const rows=[
 ['electric_gem','electric','thunderbolt','tackle','thunder_wave'],
 ['grass_gem','grass','energy_ball','tackle','grassy_terrain'],
 ['ice_gem','ice','ice_beam','tackle','haze'],
 ['fighting_gem','fighting','brick_break','tackle','bulk_up'],
 ['poison_gem','poison','sludge_bomb','tackle','toxic_spikes'],
 ['ground_gem','ground','earth_power','tackle','spikes'],
 ['flying_gem','flying','aerial_ace','tackle','roost'],
 ['psychic_gem','psychic','psychic','tackle','calm_mind'],
 ['bug_gem','bug','bug_buzz','tackle','sticky_web'],
 ['rock_gem','rock','smack_down','tackle','stealth_rock']
];
const mon=(species_id,instance_id,moves,item='')=>({
 species_id,instance_id,level:100,moves,held_item_id:item});
let activations=0,negative=0,restores=0,reentries=0,ppChecks=0;
function play({id,typ,move,seed=19,mode='active',double=false}){
 const equipped=mode==='active'?id:'';
 const bench=mode==='reserve'?id:'';
 const e=new NativeEngine();
 try{
  e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',seed:[seed,2,3,4],
   teams:{p1:[mon('mew','own',[move,'reflect'],equipped),
      mon('mew','reserve',['reflect'],bench)],p2:[mon('mew','foe',['amnesia'])]}});
  const battle=e.sessions.get('a').battle;
  const moveId=move.replace(/_/g,'');
  const rule=battle.dex.moves.get(moveId);
  assert.equal(rule.exists,true,'Missing native move '+move);
  if(typ)assert.equal(rule.type.toLowerCase(),typ,
   'Canonical move type diverges for '+move);
  const slots=battle.p1.active[0].moveSlots;
  const slot=slots.find(z=>z.id===moveId);
  assert(slot&&slot.pp>1,'No native PP to spend for '+move);
  const initialPP=slot.pp;
  const initial=e.execute({op:'checkpoint',id:'a'});
  const take=choice=>{
   const cp=e.execute({op:'checkpoint',id:'a'});
   const draft=e.execute({op:'prepare',id:'a',expected_hash:cp.state_hash,
      choices:{p1:choice,p2:'move 1'}});
   assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,cp.state_hash,
      'Prepare cannot spend item or PP');
   return e.execute({op:'commit',id:'a',draft_token:draft.draft_token});
  };
  const after=take('move 1');
  const own=after.roster[0].pokemon.find(z=>z.instance_id==='own');
  const foe=after.roster[1].pokemon.find(z=>z.instance_id==='foe');
  const foeBefore=initial.roster[1].pokemon.find(z=>z.instance_id==='foe');
  assert(own&&foe&&foeBefore,'Roster identity lost');
  const damage=foeBefore.hp-foe.hp;
  const postPP=e.sessions.get('a').battle.p1.active[0].moveSlots.find(z=>z.id===moveId)?.pp;
  assert.equal(initialPP-postPP,1,'First legal move must use exactly one PP');
  ppChecks++;
  const save=(snapshot)=>{
   const restored=new NativeEngine();
   try{
    restored.execute({op:'restore',id:'check',snapshot:snapshot.snapshot});
    assert.equal(restored.execute({op:'checkpoint',id:'check'}).state_hash,
       snapshot.state_hash,'Restore must preserve native item state and PP');
    restores++;
   }finally{restored.close();}
  };
  save(after);
  let finalPP=postPP,secondDamage=null;
  if(double){
   assert.equal(mode,'active');
   assert.equal(own.item,'','Gem must be consumed by matching hit '+id);
   const switched=take('switch 2');
   assert.equal(switched.roster[0].active_id,'reserve','Switch must be real');
   const returned=take('switch 2');
   assert.equal(returned.roster[0].active_id,'own','Holder must re-enter combat');
   assert.equal(returned.roster[0].pokemon.find(z=>z.instance_id==='own').item,'',
      'Spent gem cannot reappear after re-entry');
   reentries++;
   const after2=take('move 1');
   const own2=after2.roster[0].pokemon.find(z=>z.instance_id==='own');
   const foe2=after2.roster[1].pokemon.find(z=>z.instance_id==='foe');
   finalPP=e.sessions.get('a').battle.p1.active[0].moveSlots.find(z=>z.id===moveId)?.pp;
   assert.equal(postPP-finalPP,1,'Second move must spend one more PP');
   ppChecks++;
   assert.equal(own2.item,'','Spent Gem cannot trigger twice');
   secondDamage=foe.hp-foe2.hp;
   assert(secondDamage>0,'Second hit must actually damage after re-entry');
   save(after2);
  }
  return {item:own.item,damage,initialPP,postPP,finalPP,secondDamage,
    reserveItem:after.roster[0].pokemon.find(z=>z.instance_id==='reserve')?.item};
 }finally{e.close();}
}
for(let i=0;i<rows.length;i++){
 const [id,typ,attack,wrong,status]=rows[i],row=String(i+1).padStart(2,'0');
 let rowPositives=0;
 for(const seed of [19,23]){
  const active=play({id,typ,move:attack,seed,double:true});
  const plain=play({id,typ,move:attack,seed,mode:'none'});
  const reserve=play({id,typ,move:attack,seed,mode:'reserve'});
  assert(active.damage>plain.damage&&plain.damage>0&&plain.damage===reserve.damage,
    'Positive matching-type damage only on active holder '+id);
  assert.equal(plain.item,'','None must retain empty holder');
  assert.equal(reserve.item,'','Reserve cannot apply holder boost');
  assert.equal(reserve.reserveItem,id.replace(/_/g,''),'Reserve gem must remain');
  rowPositives++; activations++;
 }
 const bad=play({id,typ:null,move:wrong});
 const badNone=play({id,typ:null,move:wrong,mode:'none'});
 const statusGem=play({id,typ,move:status});
 const statusNone=play({id,typ,move:status,mode:'none'});
 assert.equal(bad.damage,badNone.damage,'Wrong-type move cannot receive boost '+id);
 assert(bad.damage>0,'Wrong-type negative must be real damaging move');
 assert.equal(bad.item,id.replace(/_/g,''),'Wrong-type move must not consume gem '+id);
 assert.equal(statusGem.damage,0,'Same-type status must not deal damage '+id);
 assert.equal(statusGem.item,id.replace(/_/g,''),'Same-type status must not consume '+id);
 assert.equal(statusNone.damage,0,'Status control must not deal damage');
 negative+=2;
 console.log('W01_AUTORUN_NATIVE_ROW PASS row='+row+' id='+id+
   ' positives='+rowPositives+' negatives=2 reentry=2');
}
console.log('W01_AUTORUN_NATIVE PASS rows=10 activations='+activations+
 ' negatives='+negative+' reentries='+reentries+
 ' pp_checks='+ppChecks+' snapshots='+restores);
