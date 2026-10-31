'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {NativeEngine, ROOT} = require('../../modules/battle/backends/showdown/native_engine.cjs');
const checks = [];
const engine = new NativeEngine();
const p = id => ({instance_id:id,species_id:'mew',level:50,moves:['tackle','reflect']});
function check(name, fn) {try {fn();checks.push({name,status:'PASS'});} catch(e) {checks.push({name,status:'FAIL',error:e.stack});}}
const own = p('own'); own.status_state = {persistent_id:'poison'};
engine.execute({op:'start',id:'wild',seed:[1,2,3,4],teams:{p1:[own],p2:[p('wild')]}});
const get = () => engine.execute({op:'checkpoint',id:'wild'});
const before = get();
let draft;
check('ordinary player pass remains illegal', () => {
 assert.throws(() => engine.execute({op:'choose',id:'wild',choices:{p1:'pass',p2:'move 1'}}));
 assert.equal(get().state_hash,before.state_hash);
});
check('failed capture stages one enemy action and one native residual', () => {
 draft = engine.execute({op:'prepare',id:'wild',expected_hash:before.state_hash,reaction:'capture_failed',choices:{p2:'move 1'}});
 const candidate = draft.checkpoint;
 assert.equal(get().state_hash,before.state_hash);
 assert.equal(candidate.snapshot.native.turn,before.snapshot.native.turn+1);
 assert.deepEqual(candidate.roster[0].pokemon[0].moves,before.roster[0].pokemon[0].moves);
 assert.equal(candidate.roster[1].pokemon[0].moves[0].pp,before.roster[1].pokemon[0].moves[0].pp-1);
 const log = candidate.snapshot.native.log.slice(before.snapshot.native.log.length);
 assert.equal(log.filter(x=>x.startsWith('|move|p2a:')).length,1);
 assert.equal(log.filter(x=>x.startsWith('|move|p1a:')).length,0);
 assert.equal(log.filter(x=>x.includes('[from] psn')).length,2); // exact/public split of ONE damage event
 assert(candidate.roster[0].pokemon[0].hp<before.roster[0].pokemon[0].hp);
});
check('reaction abort restores all native RNG and side effects', () => {
 engine.execute({op:'abort',id:'wild',draft_token:draft.draft_token});
 assert.equal(get().state_hash,before.state_hash);
 const repeated=engine.execute({op:'prepare',id:'wild',expected_hash:before.state_hash,reaction:'capture_failed',choices:{p2:'move 1'}});
 assert.equal(repeated.checkpoint.state_hash,draft.checkpoint.state_hash);
 draft=repeated;
});
check('reaction commit equals the prevalidated turn', () => {
 assert.equal(engine.execute({op:'commit',id:'wild',draft_token:draft.draft_token}).state_hash,draft.checkpoint.state_hash);
});
check('invalid opponent reaction cannot mutate source', () => {
 const before=get();
 assert.throws(()=>engine.execute({op:'prepare',id:'wild',expected_hash:before.state_hash,reaction:'escape_failed',choices:{p2:'switch 99'}}));
 assert.equal(get().state_hash,before.state_hash);
});
check('reaction rejects forged player moves and unsupported action kinds', () => {
 const before=get();
 for(const command of [{reaction:'capture_failed',choices:{p1:'move 1',p2:'move 1'}},{reaction:'potion',choices:{p2:'move 1'}}]) {
  assert.throws(()=>engine.execute({op:'prepare',id:'wild',expected_hash:before.state_hash,...command}));
  assert.equal(get().state_hash,before.state_hash);
 }
});
check('mid-turn pivot cannot be replaced by an adventure action', () => {
 engine.execute({op:'start',id:'pivot',seed:[1,2,3,4],teams:{p1:[{...p('a'),moves:['u_turn']},p('b')],p2:[p('c')]}});
 engine.execute({op:'choose',id:'pivot',choices:{p1:'move 1',p2:'move 1'}});
 const snapshot=engine.execute({op:'checkpoint',id:'pivot'});
 assert.throws(()=>engine.execute({op:'prepare',id:'pivot',expected_hash:snapshot.state_hash,reaction:'escape_failed',choices:{p2:'move 1'}}));
 assert.equal(engine.execute({op:'checkpoint',id:'pivot'}).state_hash,snapshot.state_hash);
});
engine.close();
const report={status:checks.every(c=>c.status==='PASS')?'PASS':'FAIL',checks};
fs.writeFileSync(path.join(ROOT,'.godot/showdown_adventure_checks/native.json'),JSON.stringify(report,null,2));
console.log('SHOWDOWN_ADVENTURE_NATIVE',report.status,checks.length);
for(const c of checks.filter(c=>c.status==='FAIL')) console.error(c.name,c.error);
process.exitCode=report.status==='PASS'?0:1;
