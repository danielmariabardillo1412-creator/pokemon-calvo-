'use strict';
// IA1/W01 CAMP005 block07. Read-only native proof of Quick Powder speed and Transform.
// It runs the existing Showdown backend; no RNG mocking and no battle-rule edits.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const SPEC=(species_id,instance_id,moves,held_item_id='')=>({
  species_id,instance_id,level:100,moves,held_item_id
});
const format='gen9calvounifiedv1';
function probe(species,foeSpecies,move,foeMove,item='',reserveItem='',seed=19){
  const e=new NativeEngine();
  try{
    e.execute({op:'start',id:'battle',format,seed:[seed,2,3,4],teams:{
      p1:[SPEC(species,'own',[move,'reflect'],item),SPEC('mew','reserve',['reflect'],reserveItem)],
      p2:[SPEC(foeSpecies,'foe',[foeMove])]
    }});
    const before=e.execute({op:'checkpoint',id:'battle'});
    const draft=e.execute({op:'prepare',id:'battle',expected_hash:before.state_hash,
      choices:{p1:'move 1',p2:'move 1'}});
    const after=e.execute({op:'commit',id:'battle',draft_token:draft.draft_token});
    const battle=e.sessions.get('battle').battle;
    const own=battle.sides[0].active[0];
    const speed=own.getStat('spe');
    const roster=after.roster[0].pokemon.find(p=>p.instance_id==='own');
    const log=battle.log;
    const first=log.find(l=>l.startsWith('|move|'));
    assert(first,'Real attack or status action must appear in battle log');
    assert.equal(roster.transformed,move==='transform','Native Transform must really occur');
    assert.equal(roster.item,item.replace(/_/g,''),'Item identity must remain native');
    const restored=new NativeEngine();
    try{
      restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
      const cp=restored.execute({op:'checkpoint',id:'copy'});
      assert.equal(cp.state_hash,after.state_hash,'Round trip native checkpoint');
    }finally{restored.close();}
    return {speed,firstOwn:first.startsWith('|move|p1a:'),transformed:roster.transformed,
      item:roster.item,after};
  }finally{e.close();}
}
const active=probe('ditto','gyarados','reflect','tackle','quick_powder');
const none=probe('ditto','gyarados','reflect','tackle');
const reserve=probe('ditto','gyarados','reflect','tackle','','quick_powder');
assert.equal(active.speed,none.speed*2,'Quick Powder must double untransformed Ditto speed');
assert.equal(none.speed,reserve.speed,'Bench item must not affect active actor speed');
assert(active.firstOwn&&!none.firstOwn&&!reserve.firstOwn,
  'Doubling Ditto speed must reverse live move order against Gyarados');
const wrong=probe('mew','gyarados','reflect','tackle','quick_powder');
const wrongNone=probe('mew','gyarados','reflect','tackle');
assert.equal(wrong.speed,wrongNone.speed,'Quick Powder must not boost non-Ditto');
const transformed=probe('ditto','snorlax','transform','tackle','quick_powder');
const transformedNone=probe('ditto','snorlax','transform','tackle');
const transformedReserve=probe('ditto','snorlax','transform','tackle','','quick_powder');
assert(transformed.transformed&&transformedNone.transformed&&transformedReserve.transformed);
assert.equal(transformed.speed,transformedNone.speed,
  'Quick Powder must stop boosting speed immediately after real Transform');
assert.equal(transformedNone.speed,transformedReserve.speed,
  'Reserves cannot boost transformed Ditto');
assert.equal(transformed.item,'quickpowder','Quick Powder remains equipped, not consumed');
console.log('W01_B07_NATIVE_SPEED PASS cases=3');
