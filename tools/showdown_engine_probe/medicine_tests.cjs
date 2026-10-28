'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {NativeEngine,ROOT,protocolFor}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const checks=[];
const e=new NativeEngine();
const poke=id=>({instance_id:id,species_id:'mew',level:50,moves:['tackle','reflect']});
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(error){checks.push({name,status:'FAIL',error:error.stack});}}
function start(id,bench=false){e.execute({op:'start',id,seed:[1,2,3,4],teams:{p1:bench?[poke('own'),poke('bench')]:[poke('own')],p2:[poke('enemy')]}});return e.sessions.get(id).battle;}
const hpItems={potion:20,super_potion:60,hyper_potion:120,max_potion:Infinity,full_restore:Infinity};
const cures={antidote:'tox',burn_heal:'brn',ice_heal:'frz',awakening:'slp',paralyze_heal:'par',full_heal:'psn'};
const ppItems={ether:[10,'one'],max_ether:[Infinity,'one'],elixir:[10,'all'],max_elixir:[Infinity,'all']};
for(const id of [...Object.keys(hpItems),...Object.keys(cures),...Object.keys(ppItems)])check('medicine '+id,()=>{
 const b=start(id), p=b.p1.active[0];p.hp=5;
 if(cures[id])p.setStatus(cures[id]);
 if(id==='full_restore')p.setStatus('psn');
 if(ppItems[id])for(const m of p.moveSlots)m.pp=1;
 const before=e.execute({op:'checkpoint',id});
 const medicine={item_id:id,target_id:'own',move_slot:ppItems[id]?.[1]==='one'?0:-1};
 const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,reaction:'medicine',medicine,choices:{p2:'move 2'}});
 const pAfter=draft.checkpoint.roster[0].pokemon[0];
 assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash);
 assert.equal(draft.checkpoint.snapshot.native.turn,before.snapshot.native.turn+1);
 if(hpItems[id])assert.equal(pAfter.hp,Math.min(p.maxhp,5+hpItems[id]));
 if(cures[id]||id==='full_restore')assert.equal(pAfter.status_id,'');
 if(ppItems[id])pAfter.moves.forEach((m,i)=>assert.equal(m.pp,Math.min(m.max_pp,1+(i===0||ppItems[id][1]==='all'?ppItems[id][0]:0))));
 else assert.deepEqual(pAfter.moves,before.roster[0].pokemon[0].moves);
 const moves=draft.checkpoint.snapshot.native.log.slice(before.snapshot.native.log.length).filter(l=>l.startsWith('|move|'));
 assert.equal(moves.length,1);assert(moves[0].startsWith('|move|p2a:'));
 const committed=e.execute({op:'commit',id,draft_token:draft.draft_token});assert.equal(committed.state_hash,draft.checkpoint.state_hash);
 e.execute({op:'drop',id});
});
check('healing a reserve keeps its HP and identity private',()=>{
 const b=start('bench',true);b.p1.pokemon[1].hp=2;
 const before=e.execute({op:'checkpoint',id:'bench'});
 const draft=e.execute({op:'prepare',id:'bench',expected_hash:before.state_hash,reaction:'medicine',medicine:{item_id:'potion',target_id:'bench'},choices:{p2:'move 2'}});
 const log=draft.checkpoint.snapshot.native.log.slice(before.snapshot.native.log.length);
 assert(protocolFor(log,'p1').some(l=>l.includes('calvo_p1_1')));
 assert(!protocolFor(log,'p2').some(l=>l.includes('calvo_p1_1')));
 assert.equal(draft.checkpoint.roster[0].pokemon[1].hp,22);
 e.execute({op:'drop',id:'bench'});
});
check('full heal cures confusion even with no major status',()=>{
 const b=start('confusion');b.p1.active[0].addVolatile('confusion');
 const before=e.execute({op:'checkpoint',id:'confusion'});
 const d=e.execute({op:'prepare',id:'confusion',expected_hash:before.state_hash,reaction:'medicine',medicine:{item_id:'full_heal',target_id:'own'},choices:{p2:'move 2'}});
 assert(!d.checkpoint.roster[0].pokemon[0].volatiles.includes('confusion'));e.execute({op:'drop',id:'confusion'});
});
check('invalid and ineffective items roll back native state and RNG',()=>{
 start('invalid');const before=e.execute({op:'checkpoint',id:'invalid'});
 for(const medicine of [{item_id:'potion',target_id:'own'},{item_id:'antidote',target_id:'own'},{item_id:'revive',target_id:'own'},
  {item_id:'potion',target_id:'enemy'},{item_id:'ether',target_id:'own',move_slot:99}]){
  assert.throws(()=>e.execute({op:'prepare',id:'invalid',expected_hash:before.state_hash,reaction:'medicine',medicine,choices:{p2:'move 2'}}));
  assert.equal(e.execute({op:'checkpoint',id:'invalid'}).state_hash,before.state_hash);
 }
 e.execute({op:'drop',id:'invalid'});
});
check('medicine cannot revive a KO',()=>{
 const b=start('ko',true);b.p1.pokemon[1].hp=0;b.p1.pokemon[1].fainted=true;
 const before=e.execute({op:'checkpoint',id:'ko'});
 assert.throws(()=>e.execute({op:'prepare',id:'ko',expected_hash:before.state_hash,reaction:'medicine',medicine:{item_id:'max_potion',target_id:'bench'},choices:{p2:'move 2'}}));
 assert.equal(e.execute({op:'checkpoint',id:'ko'}).state_hash,before.state_hash);e.execute({op:'drop',id:'ko'});
});
check('Embargo blocks bag medicine, Heal Block does not block a potion',()=>{
 const b=start('restrictions');const p=b.p1.active[0];p.hp=5;p.addVolatile('embargo');
 let before=e.execute({op:'checkpoint',id:'restrictions'});
 const command={op:'prepare',id:'restrictions',reaction:'medicine',medicine:{item_id:'potion',target_id:'own'},choices:{p2:'move 2'}};
 assert.throws(()=>e.execute({...command,expected_hash:before.state_hash}));assert.equal(e.execute({op:'checkpoint',id:'restrictions'}).state_hash,before.state_hash);
 p.removeVolatile('embargo');p.addVolatile('healblock');before=e.execute({op:'checkpoint',id:'restrictions'});
 const draft=e.execute({...command,expected_hash:before.state_hash});assert.equal(draft.checkpoint.roster[0].pokemon[0].hp,25);
 e.execute({op:'drop',id:'restrictions'});
});
check('saved continuation is deterministic across different wall-clock seconds',()=>{
 start('clock');const before=e.execute({op:'checkpoint',id:'clock'});
 const originalNow=Date.now;
 try{
  Date.now=()=>1700000000000;
  const a=e.execute({op:'prepare',id:'clock',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 2'}});
  e.execute({op:'abort',id:'clock',draft_token:a.draft_token});
  Date.now=()=>1900000000000;
  const b=e.execute({op:'prepare',id:'clock',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 2'}});
  assert.equal(a.checkpoint.state_hash,b.checkpoint.state_hash);assert.deepEqual(a.checkpoint.snapshot,b.checkpoint.snapshot);
 }finally{Date.now=originalNow;e.execute({op:'drop',id:'clock'});}
});
e.close();
const report={status:checks.every(c=>c.status==='PASS')?'PASS':'FAIL',checks};
fs.writeFileSync(path.join(ROOT,'.godot/showdown_medicine_checks/native.json'),JSON.stringify(report,null,2));
console.log('SHOWDOWN_MEDICINES_NATIVE',report.status,checks.length);
for(const c of checks.filter(c=>c.status==='FAIL'))console.error(c.name,c.error);
process.exitCode=report.status==='PASS'?0:1;
