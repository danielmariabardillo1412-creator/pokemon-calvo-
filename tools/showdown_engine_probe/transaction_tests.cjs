'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {NativeEngine,ROOT}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const engine=new NativeEngine();
const checks=[];
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.stack});}}
const pokemon=(id,moves)=>({instance_id:id,species_id:'mew',level:50,moves});
engine.execute({op:'start',id:'a',seed:[1,2,3,4],teams:{p1:[pokemon('p1',['tackle','reflect'])],p2:[pokemon('p2',['protect'])]}});
const checkpoint=()=>engine.execute({op:'checkpoint',id:'a'});
const before=checkpoint();let draft;
check('prepare computes a detached native candidate',()=>{
 draft=engine.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 2',p2:'move 1'}});
 assert.equal(checkpoint().state_hash,before.state_hash);assert.notEqual(draft.checkpoint.state_hash,before.state_hash);
});
check('abort drops speculative side effects and RNG',()=>{
 engine.execute({op:'abort',id:'a',draft_token:draft.draft_token});assert.equal(checkpoint().state_hash,before.state_hash);assert.equal(engine.drafts.size,0);
});
check('aborted token cannot be committed',()=>assert.throws(()=>engine.execute({op:'commit',id:'a',draft_token:draft.draft_token})));
check('stale prepare fails before computing a candidate',()=>assert.throws(()=>engine.execute({op:'prepare',id:'a',expected_hash:'stale',choices:{p1:'move 1',p2:'move 1'}})));
check('accepted commit exactly matches the validated candidate',()=>{
 draft=engine.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 2',p2:'move 1'}});
 const committed=engine.execute({op:'commit',id:'a',draft_token:draft.draft_token});assert.equal(committed.state_hash,draft.checkpoint.state_hash);assert.equal(engine.drafts.size,0);
 assert(committed.snapshot.native.sides[0].sideConditions.reflect);
});
check('commit cannot be replayed twice',()=>assert.throws(()=>engine.execute({op:'commit',id:'a',draft_token:draft.draft_token})));
check('invalid choice does not leave a candidate or mutate the source',()=>{
 const hash=checkpoint().state_hash;assert.throws(()=>engine.execute({op:'prepare',id:'a',expected_hash:hash,choices:{p1:'switch 99',p2:'move 1'}}));
 assert.equal(checkpoint().state_hash,hash);assert.equal(engine.drafts.size,0);
});
check('new draft replaces previous pending draft with bounded lifetime',()=>{
 const hash=checkpoint().state_hash;
 const one=engine.execute({op:'prepare',id:'a',expected_hash:hash,choices:{p1:'move 1',p2:'move 1'}});
 draft=engine.execute({op:'prepare',id:'a',expected_hash:hash,choices:{p1:'move 1',p2:'move 1'}});
 assert.equal(engine.drafts.size,1);assert.throws(()=>engine.execute({op:'commit',id:'a',draft_token:one.draft_token}));
});
check('changed native revision invalidates an outstanding draft',()=>{
 engine.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
 assert.throws(()=>engine.execute({op:'commit',id:'a',draft_token:draft.draft_token}));
});
check('drop cleans both live battle and pending drafts',()=>{
 engine.execute({op:'drop',id:'a'});assert.equal(engine.sessions.size,0);assert.equal(engine.drafts.size,0);
});
engine.close();
const report={status:checks.every(x=>x.status==='PASS')?'PASS':'FAIL',checks};
fs.writeFileSync(path.join(ROOT,'.godot/showdown_backend_checks/transactions.json'),JSON.stringify(report,null,2));
console.log('SHOWDOWN_TRANSACTIONS',report.status,checks.length);
process.exitCode=report.status==='PASS'?0:1;
