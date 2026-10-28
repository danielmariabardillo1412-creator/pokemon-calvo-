'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {performance} = require('node:perf_hooks');
const {Probe,lookup,auditCatalog,hash,ROOT,version} = require('./engine.cjs');
const OUTPUT = path.join(ROOT,'.godot/showdown_engine_probe');
fs.mkdirSync(OUTPUT,{recursive:true});
const started=performance.now(), checks=[];
const probes=[];
function check(name,fn) {
  try {fn();checks.push({name,status:'PASS'});}
  catch(e) {checks.push({name,status:'FAIL',error:e.stack});console.error(name,e.message);}
}
function pokemon(id,moves,extra={}) {return {instance_id:id,species_id:'mew',level:50,moves,...extra};}
function start(p1,p2,extra={}) {
  const p=new Probe();probes.push(p);
  p.execute({op:'start',id:'battle',seed:[1,2,3,4],teams:{p1,p2},...extra});
  return p;
}
const view=(p,side='p1')=>p.execute({op:'view',id:'battle',perspective:side});
const turn=(p,p1='move 1',p2='move 1')=>p.execute({op:'choose',id:'battle',choices:{p1,p2}});
const snap=p=>p.execute({op:'snapshot',id:'battle'}).snapshot;
const line=(r,s)=>r.protocol.some(x=>x.startsWith(s));

check('Protect resolves natively without damage',()=>{
  const p=start([pokemon('a',['tackle'])],[pokemon('b',['protect'])]);
  const before=view(p,'p2').own[0].hp;const r=turn(p);
  assert.equal(view(p,'p2').own[0].hp,before);assert(line(r,'|-activate|'));assert.equal(r.own[0].moves[0].pp,55);
});
check('Reflect creates a native side condition',()=>{
  const p=start([pokemon('a',['reflect'])],[pokemon('b',['splash'])]);
  const r=turn(p);assert(line(r,'|-sidestart|'));assert(snap(p).native.sides[0].sideConditions.reflect);
});
check('Terrain supplies native field state',()=>{
  const p=start([pokemon('a',['electric_terrain'])],[pokemon('b',['splash'])]);
  turn(p);assert.equal(snap(p).native.field.terrain,'electricterrain');
});
check('Stealth Rock applies damage on switch',()=>{
  const p=start([pokemon('a',['stealth_rock'])],[pokemon('b',['splash']),pokemon('c',['splash'],{species_id:'charizard'})]);
  turn(p);const r=turn(p,'move 1','switch 2');assert.equal(view(p,'p2').own.find(x=>x.instance_id==='c').hp,Math.ceil(view(p,'p2').own.find(x=>x.instance_id==='c').max_hp/2));assert(line(r,'|-damage|'));
});
check('Multi-turn charging retains the native continuation',()=>{
  const p=start([pokemon('a',['solar_beam'])],[pokemon('b',['splash'])]);
  const hp=view(p,'p2').own[0].hp;const a=turn(p);assert.equal(view(p,'p2').own[0].hp,hp);assert(line(a,'|-prepare|'));
  turn(p);assert(view(p,'p2').own[0].hp<hp);
});
check('Compound healing, sleep and native save/restore',()=>{
  const p=start([pokemon('a',['rest','splash'],{current_hp:100,status_state:{persistent_id:'burn'}})],[pokemon('b',['splash'])]);
  const first=turn(p);assert.equal(first.own[0].hp,first.own[0].max_hp);assert.equal(first.own[0].status_id,'sleep');
  const saved=snap(p);const q=new Probe();probes.push(q);q.execute({op:'restore',id:'battle',snapshot:saved});
  for(let i=0;i<3;i++) {const a=turn(p,'move 2'),b=turn(q,'move 2');delete a.elapsed_ms;delete b.elapsed_ms;assert.deepEqual(a,b);assert.equal(hash(snap(p)),hash(snap(q)));}
  assert.equal(view(p).own[0].status_id,'');
});
check('Held Leftovers heals through native item mechanics',()=>{
  const p=start([pokemon('a',['splash'],{current_hp:100,held_item_id:'leftovers'})],[pokemon('b',['splash'])]);
  const r=turn(p);assert.equal(r.own[0].hp,110);assert(line(r,'|-heal|'));
});
check('Native berry consumption is observable',()=>{
  const p=start([pokemon('a',['belly_drum'],{current_hp:174,held_item_id:'sitrus_berry'})],[pokemon('b',['splash'])]);
  const r=turn(p);assert.equal(r.own[0].held_item_id,'');assert(line(r,'|-enditem|'));
});
check('Intimidate is a native switch-in ability',()=>{
  const p=start([pokemon('a',['splash'],{ability_id:'intimidate'})],[pokemon('b',['splash'])]);
  assert.equal(snap(p).native.sides[1].pokemon[0].boosts.atk,-1);
});
check('Legacy generation 8 supports native Dynamax',()=>{
  const p=start([pokemon('a',['flamethrower'])],[pokemon('b',['splash'])],{format:'gen8customgame'});
  const r=turn(p,'move 1 dynamax');assert(line(r,'|-start|'));assert(r.protocol.some(x=>x.includes('|Max Flare|')));
});
check('Generation 9 does not silently accept Dynamax',()=>{
  const p=start([pokemon('a',['flamethrower'])],[pokemon('b',['splash'])]);
  const before=hash(snap(p));assert.throws(()=>turn(p,'move 1 dynamax'));assert.equal(hash(snap(p)),before);
});
check('Pivot pauses for an actual replacement request',()=>{
  const p=start([pokemon('a',['u_turn']),pokemon('c',['splash'])],[pokemon('b',['splash'])]);
  const r=turn(p);assert.equal(r.request_state,'switch');assert(r.request.forceSwitch[0]);
  p.execute({op:'choose',id:'battle',choices:{p1:'switch 2'}});assert.equal(view(p).own.find(x=>x.active).instance_id,'c');
});
check('Invalid choices are atomic and preserve RNG/state',()=>{
  const p=start([pokemon('a',['tackle'])],[pokemon('b',['splash'])]);
  const before=hash(snap(p));assert.throws(()=>turn(p,'switch 99'));assert.equal(hash(snap(p)),before);
});
check('Ordinary bag/capture skipped turn is not a native pass command',()=>{
  const p=start([pokemon('a',['tackle'])],[pokemon('b',['splash'])]);
  assert.throws(()=>turn(p,'pass'));
});
check('Player projection does not expose opponent moves/item/stats',()=>{
  const p=start([pokemon('a',['tackle'])],[pokemon('b',['protect'],{held_item_id:'choice_band',ability_id:'pressure'})]);
  const r=view(p);const text=JSON.stringify(r.opponent);
  assert(!text.includes('choiceband'));assert(!text.includes('protect'));assert(!text.includes('pressure'));
  assert(!JSON.stringify(r.request).includes('calvo_p2'));
});
check('Batched search forks leave live state unchanged',()=>{
  const p=start([pokemon('a',['tackle','protect'])],[pokemon('b',['splash'])]);
  const before=hash(snap(p));const r=p.execute({op:'branches',id:'battle',candidates:Array.from({length:64},(_,i)=>({p1:'move '+(1+i%2),p2:'move 1'}))});
  assert(r.source_unchanged);assert(r.results.every(x=>x.ok));assert.equal(hash(snap(p)),before);
  checks.push({name:'64 native snapshot/choice forks timing',status:'MEASUREMENT',elapsed_ms:r.elapsed_ms});
});
check('Persistent starting PP imported before battle decisions',()=>{
  const p=start([pokemon('a',['tackle'],{moveset:[{move_id:'tackle',current_pp:2,max_pp:35}]})],[pokemon('b',['splash'])]);
  assert.equal(view(p).own[0].moves[0].pp,2);assert.equal(turn(p).own[0].moves[0].pp,1);
});
check('Unsupported legacy sleep import fails instead of inventing a clock',()=>{
  assert.throws(()=>start([pokemon('a',['tackle'],{status_state:{persistent_id:'sleep',turns_remaining:2}})],[pokemon('b',['splash'])]));
});
check('Invalid persistent stats are rejected without modifying canonical data',()=>{
  assert.throws(()=>start([pokemon('a',['tackle'],{stats:{max_hp:9999}})],[pokemon('b',['splash'])]));
});
for(const [source,expected] of [
  ['tackle','max_strike'],['flamethrower','max_flare'],['surf','max_geyser'],['thunderbolt','max_lightning'],
  ['energy_ball','max_overgrowth'],['ice_beam','max_hailstorm'],['close_combat','max_knuckle'],
  ['sludge_bomb','max_ooze'],['earth_power','max_quake'],['air_slash','max_airstream'],
  ['psychic','max_mindstorm'],['bug_buzz','max_flutterby'],['rock_slide','max_rockfall'],
  ['shadow_ball','max_phantasm'],['dragon_pulse','max_wyrmwind'],['dark_pulse','max_darkness'],
  ['flash_cannon','max_steelspike'],['moonblast','max_starfall'],['protect','max_guard']]) {
  check('Generation 8 native '+expected,()=>{
    const p=start([pokemon('a',[source])],[pokemon('b',['splash'])],{format:'gen8customgame'});
    const r=turn(p,'move 1 dynamax');
    assert(r.protocol.some(x=>x.startsWith('|move|') && x.includes('|'+lookup('moves',expected).name+'|')));
  });
}
for(const p of probes)p.close();
const catalog=auditCatalog();
fs.writeFileSync(path.join(OUTPUT,'catalog.json'),JSON.stringify(catalog,null,2));
// Broad first-turn/serialization smoke. A context failure is legitimate; this
// does not certify the intended effect or translate it into the production UI.
const definitions=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/randomlock_content_v1.json'),'utf8'));
const excluded=new Set(policy.move_exclusions.flatMap(x=>x.ids));
const z=new Set(policy.z_moves.ids);
const smoke=[],kinds={};
for(const id of Object.keys(definitions.moves)) {
  const definition=lookup('moves',id);
  if(excluded.has(id) || z.has(id) || definition.isMax || definition.isZ) continue;
  for(const seed of [1,7,19]) {
    const p=new Probe();
    try {
      p.execute({op:'start',id:'s',seed:[seed,2,3,4],teams:{p1:[pokemon('a',[id]),pokemon('a2',['splash'])],p2:[pokemon('b',['splash']),pokemon('b2',['splash'])]}});
      let result;
      try {result=p.execute({op:'choose',id:'s',choices:{p1:'move 1',p2:'move 1'}});}
      catch(e) {smoke.push({id,seed,status:'NEEDS_CONTEXT',reason:e.message});continue;}
      const saved=p.execute({op:'snapshot',id:'s'}).snapshot;
      const restored=p.execute({op:'restore',id:'r',snapshot:saved});
      const savedAgain=p.execute({op:'snapshot',id:'r'}).snapshot;
      assert.equal(hash(savedAgain),hash(saved));
      for(const row of result.protocol) {const k=row.split('|')[1];if(k)kinds[k]=(kinds[k]??0)+1;}
      const actor=result.own.find(x=>x.instance_id==='a');
      smoke.push({id,seed,status:'EXECUTED_AND_SERIALIZED',phase:restored.request_state,pp:actor.moves[0].pp,
        failed_in_fixture:result.protocol.some(x=>x.startsWith('|-fail|')),snapshot_roundtrip:true});
    } catch(e) {smoke.push({id,seed,status:'ERROR',reason:e.stack});}
    finally {p.close();}
  }
}
const smokeCounts={};for(const row of smoke)smokeCounts[row.status]=(smokeCounts[row.status]??0)+1;
fs.writeFileSync(path.join(OUTPUT,'native_smoke.json'),JSON.stringify({counts:smokeCounts,cases:smoke,protocol_kinds:kinds,
  exclusions:'Local excluded/pending Z and native special Z/Max entries are skipped. Gen 8 Dynamax is tested explicitly above.',
  caveat:'Native first-turn and snapshot robustness, not independent mechanic certification; context failures are not automatically engine defects or admissions.'},null,2));
checks.push({name:'broad native smoke has no uncaught engine/serialization errors',status:smokeCounts.ERROR?'FAIL':'PASS',counts:smokeCounts});
const report={status:checks.some(x=>x.status==='FAIL')?'FAIL':'PASS',version,checks,elapsed_ms:performance.now()-started,
  coverage_note:'Concrete integration scenarios, not proof of every move/interaction. Native simulator is the tested implementation, not an independent oracle for itself.'};
fs.writeFileSync(path.join(OUTPUT,'node_tests.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify({status:report.status,checks:checks.length,smoke:smokeCounts,failures:checks.filter(x=>x.status==='FAIL').map(x=>x.name),catalog:Object.fromEntries(Object.entries(catalog).filter(([,v])=>v&&typeof v==='object').map(([k,v])=>[k,{total:v.total,matched:v.matched,missing:v.missing.length,differences:v.data_differences.length}]))}));
process.exitCode=report.status==='PASS'?0:1;
