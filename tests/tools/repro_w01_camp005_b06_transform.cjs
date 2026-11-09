'use strict';
// W01 CAMP005 B06. A/B/C native snapshot reproduction authorized by IA6
// 2026-11-09. No production changes, no weakened test assertions.
const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path');
const {NativeEngine, serialize, restore, hash} =
  require('../../modules/battle/backends/showdown/native_engine.cjs');
const SPEC = (species, instance_id, moves, held_item_id='') => ({
  species_id:species, instance_id, level:100, moves, held_item_id
});
const seed=[19,2,3,4], format='gen9calvounifiedv1';
function sourceDiagnostic() {
  const source=path.resolve(__dirname,
    '../../.godot/battle_reference/runtime/node_modules/@pkmn/sim/build/cjs/sim/state.js');
  const lines=fs.readFileSync(source,'utf8').split(String.fromCharCode(10));
  console.log('W01_B06_STATEJS_198_218');
  for(let index=197;index<218;index++)
    console.log('W01_B06_STATEJS',index+1,lines[index]);
}

function run(firstMove, actorItem, tag) {
  const engine=new NativeEngine();
  let first=null;
  try {
    engine.execute({op:'start',id:'battle',format,seed,
      teams:{p1:[SPEC('ditto','own',firstMove==='transform'?['transform','reflect']:['reflect'],actorItem),
                  SPEC('ditto','reserve',['reflect'])],
             p2:[SPEC('snorlax','foe',['tackle'])]}});
    const initial=engine.execute({op:'checkpoint',id:'battle'});
    const prepare=engine.execute({op:'prepare',id:'battle',
      expected_hash:initial.state_hash,
      choices:{p1:'move 1',p2:'move 1'}});
    first=engine.execute({op:'commit',id:'battle',draft_token:prepare.draft_token});
    const actor=first.roster[0].pokemon.find(p=>p.instance_id==='own');
    assert.equal(actor.transformed,firstMove==='transform');
    assert.equal(first.roster[0].pokemon[1].instance_id,'reserve');
    assert.equal(first.roster[0].pokemon[1].hp>0,true);
    assert.equal(first.roster[0].active_id,'own');
    const nativeSnapshot=serialize(engine.sessions.get('battle').battle);
    const originalHash=hash(nativeSnapshot);
    const transformedData=nativeSnapshot.p1?.pokemon?.find(p=>p.name==='calvo_p1_0') ??
      nativeSnapshot.p1?.pokemon?.[0] ?? {};
    console.log('W01_B06_TRANSFORM_SNAPSHOT_KEYS',tag,JSON.stringify({
      snapshotKeys:Object.keys(nativeSnapshot),pokemonKeys:Object.keys(transformedData),
      species:transformedData.species,
      baseSpecies:transformedData.baseSpecies,
      set:transformedData.set,
      transformed:transformedData.transformed,
      moveSlots:transformedData.moveSlots,
      baseMoveSlots:transformedData.baseMoveSlots
    }));

    console.log('W01_B06_REPRO_STATE',JSON.stringify({tag,transform:actor.transformed,
      species:actor.species_id,original_hash:originalHash,active:first.roster[0].active_id,
      reserve_hp:first.roster[0].pokemon[1].hp,
      move:actor.moves.map(m=>m.id),item:actor.item,
      seed,phase:first.views.p1.request?.active?.[0]?'move':'unknown'}));
    // A. Isolate the serializer, native fromJSON/restart, then public checkpoint.
    let direct;
    try {
      direct=restore(nativeSnapshot);
      const rebuiltHash=hash(serialize(direct));
      assert.equal(rebuiltHash,originalHash,'Native serialize->fromJSON round-trip');
      console.log('W01_B06_REPRO_RESTORE_OK',tag,rebuiltHash);
    } catch(err) {
      console.error('W01_B06_REPRO_RESTORE_ERROR',tag,err.stack||String(err));
      throw err;
    } finally {if(direct)direct.destroy();}
    // SaveV2 lower native layer: restore the actual exported snapshot and checkpoint.
    let sessionRestore=new NativeEngine();
    try {
      sessionRestore.execute({op:'restore',id:'roundtrip',snapshot:first.snapshot});
      const round=sessionRestore.execute({op:'checkpoint',id:'roundtrip'});
      assert.equal(round.state_hash,first.state_hash,'Native restored state equals exact native checkpoint');
      console.log('W01_B06_REPRO_SNAPSHOT_OK',tag);
    } catch(err) {
      console.error('W01_B06_REPRO_SNAPSHOT_ERROR',tag,err.stack||String(err));
      throw err;
    } finally {sessionRestore.close();}
    // B. Native prepare/choose switch: same active and healthy reserve.
    try {
      const move=engine.execute({op:'prepare',id:'battle',
        expected_hash:first.state_hash,choices:{p1:'switch 2',p2:'move 1'}});
      const committed=engine.execute({op:'commit',id:'battle',draft_token:move.draft_token});
      assert.equal(committed.roster[0].active_id,'reserve');
      assert(committed.roster[0].pokemon.some(p=>p.instance_id==='own'));
      assert(committed.roster[0].pokemon.some(p=>p.instance_id==='reserve'));
      console.log('W01_B06_REPRO_SWITCH_OK',tag);
    } catch(err) {
      console.error('W01_B06_REPRO_SWITCH_ERROR',tag,err.stack||String(err));
      throw err;
    }
    return true;
  }finally{engine.close();}
}
sourceDiagnostic();
let errors=0;
for(const [tag,firstMove,item] of [['A_TRANSFORM_ACTIVE','transform','metal_powder'],
                                   ['B_TRANSFORM_NO_ITEM','transform',''],
                                   ['C_NO_TRANSFORM','reflect','metal_powder']]) {
  try {run(firstMove,item,tag);} catch(err) {errors++;console.log('W01_B06_REPRO_FAIL',tag,err.message);}
}
assert.equal(errors,0,'All valid transformed and control snapshots must preserve native state and legal switch');
console.log('W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3');
