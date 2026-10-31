'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const results=[];
function check(name,fn){try{fn();results.push({name,status:'PASS'});}catch(e){results.push({name,status:'FAIL',error:e.stack});}}
const mon=()=>({instance_id:'own',species_id:'mew',moves:['tackle'],level:50});
function start(p){const e=new NativeEngine();try{e.execute({op:'start',id:'a',teams:{p1:[p],p2:[{instance_id:'enemy',species_id:'mew',moves:['reflect']}]},seed:[1,2,3,4]});return e;}catch(error){e.close();throw error;}}
const asleep=(time=2)=>({...mon(),status_state:{persistent_id:'sleep',turns_remaining:time},native_sleep:{version:'0.10.11',start_time:3,time}});
check('Legacy sleep cannot masquerade as an observed clock',()=>assert.throws(()=>start({...mon(),status_state:{persistent_id:'sleep',turns_remaining:2}})));
check('Observed sleep imports exactly and uses no random draw',()=>{
 const plain=start(mon()),sleep=start(asleep());try{
 const a=plain.execute({op:'checkpoint',id:'a'}),b=sleep.execute({op:'checkpoint',id:'a'});
 assert.deepEqual(a.snapshot.native.prng,b.snapshot.native.prng);
 assert.equal(sleep.sessions.get('a').battle.p1.active[0].statusState.time,2);
 assert.deepEqual(b.roster[0].pokemon[0].sleep_clock,asleep().native_sleep);
 }finally{plain.close();sleep.close();}
});
check('Remaining sleep and continuation survive native recovery',()=>{
 const e=start(asleep()),r=new NativeEngine();try{
 const saved=e.execute({op:'checkpoint',id:'a'});r.execute({op:'restore',id:'b',snapshot:saved.snapshot});
 for(const [engine,id] of [[e,'a'],[r,'b']])engine.execute({op:'choose',id,choices:{p1:'move 1',p2:'move 1'}});
 const a=e.execute({op:'checkpoint',id:'a'}),b=r.execute({op:'checkpoint',id:'b'});
 assert.equal(a.state_hash,b.state_hash);assert.equal(a.roster[0].pokemon[0].sleep_clock.time,1);
 }finally{e.close();r.close();}
});
for(const change of [{version:'future'},{start_time:5},{time:4},{time:-1},{time:1.5}])check('Malformed clock rejected '+JSON.stringify(change),()=>{
 const p=asleep();Object.assign(p.native_sleep,change);assert.throws(()=>start(p));
});
const out=path.join(ROOT,'.godot/field_native_checks/native_clocks.json');
fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,JSON.stringify({status:results.every(r=>r.status==='PASS')?'PASS':'FAIL',checks:results},null,2));
for(const r of results.filter(r=>r.status==='FAIL'))console.log(r.name,r.error);
console.log('FIELD_NATIVE_CLOCKS',results.every(r=>r.status==='PASS')?'PASS':'FAIL',results.length);process.exitCode=results.some(r=>r.status==='FAIL')?1:0;
