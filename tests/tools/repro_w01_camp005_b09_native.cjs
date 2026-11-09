'use strict';
// W01 CAMPAÑA_005 B09. Native Showdown only; reproducible seeds, no fake RNG.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(species_id,instance_id,moves,item='')=>({species_id,instance_id,level:100,moves,held_item_id:item});
function play(item='',ownMove='reflect',foeMove='tackle',foeSpecies='snorlax',seed=19,reserveItem=''){
 const e=new NativeEngine();
 try{
  e.execute({op:'start',id:'b',format:'gen9calvounifiedv1',seed:[seed,2,3,4],
    teams:{p1:[mon('mew','own',[ownMove,'reflect'],item),mon('mew','reserve',['reflect'],reserveItem)],
      p2:[mon(foeSpecies,'foe',[foeMove])]}});
  const before=e.execute({op:'checkpoint',id:'b'});
  const draft=e.execute({op:'prepare',id:'b',expected_hash:before.state_hash,
    choices:{p1:'move 1',p2:'move 1'}});
  const after=e.execute({op:'commit',id:'b',draft_token:draft.draft_token});
  const log=e.sessions.get('b').battle.log;
  const first=log.find(l=>l.startsWith('|move|'));
  assert(first,'Native action log must include a real move');
  const own=after.roster[0].pokemon.find(p=>p.instance_id==='own');
  const foe=after.roster[1].pokemon.find(p=>p.instance_id==='foe');
  assert.equal(own.item,item.replace(/_/g,''),'Native holder must retain its item');
  const restored=new NativeEngine();
  try{
    restored.execute({op:'restore',id:'snapshot',snapshot:after.snapshot});
    assert.equal(restored.execute({op:'checkpoint',id:'snapshot'}).state_hash,after.state_hash,
      'Snapshot must restore bit-identically');
  }finally{restored.close();}
  return {ownHP:own.hp,ownMaxHP:own.max_hp,foeHP:foe.hp,
    firstOwn:first.startsWith('|move|p1a:'),foeMiss:log.some(l=>l.startsWith('|-miss|p2a:'))};
 }finally{e.close();}
}
const water=play('sea_incense','water_gun','amnesia','mew');
const noneWater=play('','water_gun','amnesia','mew');
const benchWater=play('','water_gun','amnesia','mew',19,'sea_incense');
assert(water.foeHP<noneWater.foeHP&&noneWater.foeHP===benchWater.foeHP,
 'Sea Incense must boost only active-holder Water damage');
assert.equal(play('sea_incense','tackle','amnesia','mew').foeHP,
 play('','tackle','amnesia','mew').foeHP,'Normal attacks do not get a Water boost');
const last=play('full_incense'),baseline=play('');
const bench=play('','reflect','tackle','snorlax',19,'full_incense');
assert(!last.firstOwn&&baseline.firstOwn&&bench.firstOwn,
 'Full Incense must act last at equal priority, but bench must not');
assert(play('full_incense','quick_attack').firstOwn,
 'Full Incense must preserve priority +1 before ordinary Tackle');
const misses=[],hits=[];
for(let seed=1;seed<=64;seed++){
  const a=play('lax_incense','reflect','tackle','snorlax',seed);
  const n=play('','reflect','tackle','snorlax',seed);
  assert(!n.foeMiss,'Normal Tackle must not miss without incense');
  if(a.foeMiss){
    assert(a.ownHP>n.ownHP,'Native Lax miss must prevent damage');
    misses.push(seed);
  }else{
    assert.equal(a.ownHP,n.ownHP,'Lax Incense must not modify hit damage');
    hits.push(seed);
  }
}
assert(misses.length>0&&hits.length>0,'Both RNG branches must be demonstrated naturally');
const never=play('lax_incense','reflect','aerial_ace');
assert(!never.foeMiss&&never.ownHP<never.ownMaxHP,'Aerial Ace must never miss');
console.log('W01_B09_RNG_SEEDS miss='+misses.join(',')+' hit='+hits.slice(0,10).join(','));
console.log('W01_B09_NATIVE PASS water=1 order=1 misses='+misses.length+' hits='+hits.length);
