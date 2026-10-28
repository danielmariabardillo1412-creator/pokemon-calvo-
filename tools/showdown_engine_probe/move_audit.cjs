'use strict';
// Exhaustive inventory + bounded native multi-turn candidates. Read-only: does
// not admit moves, rewrite definitions, or treat a valid failed move as a pass.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {NativeEngine,lookup,ROOT,serialize,hash}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=process.env.CALVO_AUDIT_OUT??path.join(ROOT,'.godot/move_functional_audit');
const FORMAT=process.env.CALVO_AUDIT_FORMAT??'gen9customgame';
const MAX_FORMAT=process.env.CALVO_AUDIT_MAX_FORMAT??'gen8customgame';
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/randomlock_content_v1.json'),'utf8'));
const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const excluded=new Set(policy.move_exclusions.flatMap(g=>g.ids));
const z=new Set(policy.z_moves.ids);
const inventory=[],results=[],oracle=[],batches=[];
const canonicalByNative=new Map(Object.keys(data.moves).map(id=>[lookup('moves',id).id,id]));
let batch=[],caseCount=0;
function pokemon(id,moveIds,species='mew',extra={}){
 const p=clone(prototypes[species]);p.instance_id=id;p.move_ids=moveIds;
 p.moveset=moveIds.map(id=>({move_id:id,current_pp:data.moves[id].pp,max_pp:data.moves[id].pp}));
 return Object.assign(p,extra);
}
function compact(c){return {roster:c.roster,views:{p1:{ended:c.views.p1.ended,winner:c.views.p1.winner,request:c.views.p1.request},p2:{ended:c.views.p2.ended,winner:c.views.p2.winner,request:c.views.p2.request}},snapshot:{identities:c.snapshot.identities,native:{turn:c.snapshot.native.turn,log:c.snapshot.native.log,field:c.snapshot.native.field}}};}
function writeBatch(){if(!batch.length)return;const file=`batch_${String(batches.length).padStart(3,'0')}.json`;fs.writeFileSync(path.join(OUT,file),JSON.stringify(batch));batches.push(file);batch=[];console.log('MOVE_AUDIT_NATIVE',caseCount,'cases',file);}
function choice(b,side){
 const s=b[side],r=s.activeRequest;
 if(!r||r.wait||s.isChoiceDone())return null;
 if(r.forceSwitch?.[0]){const i=s.pokemon.findIndex(p=>!p.isActive&&!p.fainted&&p.hp>0);return i<0?'pass':`switch ${i+1}`;}
 const moves=r.active?.[0]?.moves??[];
 const index=moves.findIndex(m=>!m.disabled&&(m.pp===undefined||m.pp>0));
 return index<0?'default':`move ${index+1}`;
}
function teamsFor(id,scenario){
 const own=pokemon('actor',[id]);const target=pokemon('target',[scenario==='healthy'?'reflect':'tackle']);
 if(scenario==='conditioned'){
  own.current_hp=Math.floor(own.stats.max_hp*.4);target.current_hp=Math.floor(target.stats.max_hp*.6);
  own.status_state.persistent_id='poison';own.status_ids=['poison'];own.held_item_id='leftovers';
  target.held_item_id='hard_stone';
 }
 return {p1:[own,pokemon('own_reserve',['tackle'])],p2:[target,pokemon('enemy_reserve',['tackle'])]};
}
function checkInvariants(c){
 for(const s of c.roster)for(const p of s.pokemon){
  assert(Number.isInteger(p.hp)&&p.hp>=0&&p.hp<=p.max_hp,'HP range');
  for(const m of p.moves)assert(Number.isInteger(m.pp)&&m.pp>=0&&m.pp<=m.max_pp,'PP range');
 }
}
function runCase(id,seed,scenario,teams=teamsFor(id,scenario),expect=null,format=FORMAT,firstSuffix=''){
 const e=new NativeEngine();const case_id=`${id}/${scenario}/${seed}`;
 const row={case_id,id,seed,scenario,format,origin:teams,steps:[]};
 const result={case_id,id,seed,scenario,steps:0,executed_actor:false,failed_context:false,missed:false,roundtrips:0,replay:false,oracle:expect?.label??null};
 try{
  e.execute({op:'start',id:'a',seed:[seed,2,3,4],teams,format});
  let checkpoint=e.execute({op:'checkpoint',id:'a'});row.before=compact(checkpoint);
  let live=e.sessions.get('a').battle;
  let first=true;
  for(let step=0;step<4&&!live.ended;step++){
   const choices=Object.fromEntries(['p1','p2'].map(s=>[s,choice(live,s)]).filter(([,c])=>c!==null));
   if(step===0&&firstSuffix)choices.p1+=firstSuffix;
   const before=checkpoint;
   const draft=e.execute({op:'prepare',id:'a',expected_hash:checkpoint.state_hash,choices});
   assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,before.state_hash,'prepare changed source');
   checkpoint=e.execute({op:'commit',id:'a',draft_token:draft.draft_token});
   assert.equal(checkpoint.state_hash,draft.checkpoint.state_hash,'commit differs');checkInvariants(checkpoint);
   const delta=checkpoint.snapshot.native.log.slice(before.snapshot.native.log.length);
   result.executed_actor ||= delta.some(x=>x.startsWith('|move|p1a:'));
   result.failed_context ||= delta.some(x=>x.startsWith('|-fail|p1')||x.startsWith('|cant|p1'));
   result.missed ||= delta.some(x=>x.startsWith('|-miss|'));
   row.steps.push(compact(checkpoint));result.steps++;
   e.execute({op:'restore',id:'r',snapshot:checkpoint.snapshot});
   assert.equal(e.execute({op:'checkpoint',id:'r'}).state_hash,checkpoint.state_hash,'snapshot roundtrip');result.roundtrips++;
   e.execute({op:'drop',id:'r'});
   if(first&&expect){
    try{expect.check(before,checkpoint);oracle.push({case_id,id,label:expect.label,status:'PASS'});}
    catch(error){oracle.push({case_id,id,label:expect.label,status:'FAIL',error:error.message});}
   }
   first=false;live=e.sessions.get('a').battle;
   // A forced replacement is continued in the next step. This counts the real
   // request, not an invented new full turn or silently auto-selected move.
  }
  if(!live.ended){
   const choices=Object.fromEntries(['p1','p2'].map(s=>[s,choice(live,s)]).filter(([,c])=>c!==null));
   e.execute({op:'restore',id:'r',snapshot:checkpoint.snapshot});
   const a=e.execute({op:'choose',id:'a',choices});const b=e.execute({op:'choose',id:'r',choices});
   assert.equal(hash(serialize(e.sessions.get('a').battle)),hash(serialize(e.sessions.get('r').battle)),'saved continuation RNG/state');
   result.replay=true;
  }
  result.status='NATIVE_EXECUTED';batch.push(row);caseCount++;if(batch.length===32)writeBatch();
 }catch(error){result.status='NATIVE_ERROR';result.error=error.stack;}
 finally{e.close();}
 results.push(result);
}
for(const id of Object.keys(data.moves).sort()){
 const native=lookup('moves',id);
 const classification=excluded.has(id)?'EXCLUDED':z.has(id)?'Z_PENDING':native.isMax?'MAX_PROFILE_PENDING':!native.exists?'MISSING_NATIVE':'ORDINARY';
 inventory.push({id,classification,native_id:native.id,native_gen:native.gen});
 if(classification==='ORDINARY')for(const scenario of ['healthy','conditioned'])for(const seed of [1,19])runCase(id,seed,scenario);
}
// Independent expected outcomes: no simulator callback/formula used to compute
// these contracts. Complements, never replaces, contexts for the full inventory.
for(const [id,amount] of Object.entries({dragon_rage:40,sonic_boom:20,seismic_toss:50,night_shade:50})){
 runCase(id,1,'contract',teamsFor(id,'healthy'),{label:`fixed HP loss ${amount}`,check:(a,b)=>assert.equal(a.roster[1].pokemon[0].hp-b.roster[1].pokemon[0].hp,amount)});
}
for(const id of ['super_fang','natures_madness','ruination'])runCase(id,1,'contract',teamsFor(id,'healthy'),{label:'half current HP',check:(a,b)=>assert.equal(a.roster[1].pokemon[0].hp-b.roster[1].pokemon[0].hp,Math.max(1,Math.floor(a.roster[1].pokemon[0].hp/2)))});
for(const [id,stat,amount] of [['swords_dance','atk',2],['tail_whip','def',-1]])runCase(id,1,'contract',teamsFor(id,'healthy'),{label:`stage ${stat} ${amount}`,check:(a,b)=>assert.equal(b.roster[amount>0?0:1].pokemon[0].boosts[stat],amount)});
runCase('protect',1,'contract',teamsFor('protect','conditioned'),{label:'Protect blocks damage',check:(a,b)=>{
 const own=a.roster[0].pokemon[0];const after=b.roster[0].pokemon[0];
 assert.equal(after.hp,own.hp-Math.floor(own.max_hp/8)+Math.floor(own.max_hp/16));
}});
for(const id of ['recover','roost','soft_boiled']){
 const teams=teamsFor(id,'healthy');teams.p1[0].current_hp=10;
 runCase(id,1,'contract',teams,{label:'restore half maximum HP',check:(a,b)=>assert.equal(b.roster[0].pokemon[0].hp,10+Math.round(a.roster[0].pokemon[0].max_hp/2))});
}
runCase('spore',1,'contract',teamsFor('spore','healthy'),{label:'sleep applied',check:(a,b)=>assert.equal(b.roster[1].pokemon[0].status_id,'sleep')});
runCase('glare',1,'contract',teamsFor('glare','healthy'),{label:'paralysis applied',check:(a,b)=>assert.equal(b.roster[1].pokemon[0].status_id,'paralysis')});
writeBatch();
const special=[];
for(const row of inventory.filter(r=>r.classification==='MAX_PROFILE_PENDING')){
 const id=row.id;const move=lookup('moves',id);const e=new NativeEngine();
 try{
  const Dex=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim')).Dex;
  const base=Dex.moves.all().find(m=>!m.isMax&&!m.isZ&&m.exists&&canonicalByNative.has(m.id)&&(id==='max_guard'?m.id==='protect':m.type===move.type&&m.category!=='Status'));
  if(!base)throw Error('No base move');
  const canonical=canonicalByNative.get(base.id);
  e.execute({op:'start',id:'max',format:MAX_FORMAT,seed:[1,2,3,4],teams:{p1:[pokemon('max_actor',[canonical])],p2:[pokemon('max_target',['reflect'])]}});
  const r=e.execute({op:'choose',id:'max',choices:{p1:'move 1 dynamax',p2:'move 1'}});
  assert(r.protocol.some(l=>l.startsWith('|move|p1a:')&&l.split('|')[3].replace(/[^a-z0-9]/gi,'').toLowerCase()===move.id));
  special.push({id,format:MAX_FORMAT,status:MAX_FORMAT==='gen8customgame'?'NATIVE_GEN8_ONLY':'NATIVE_UNIFIED_MAX_VERIFIED',godot:'NATIVE_MAX_AUDIT_ROW'});
  runCase(id,1,'max', {p1:[pokemon('actor',[canonical]),pokemon('own_reserve',['tackle'])],p2:[pokemon('target',['reflect']),pokemon('enemy_reserve',['tackle'])]},null,MAX_FORMAT,' dynamax');
 }catch(error){special.push({id,status:'ERROR',error:error.message});}finally{e.close();}
}
writeBatch();
fs.writeFileSync(path.join(OUT,'manifest.json'),JSON.stringify({batches,cases:caseCount,inventory}));
fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({inventory,results,oracle,special},null,2));
console.log('MOVE_AUDIT_NATIVE_COMPLETE',JSON.stringify({inventory:inventory.length,cases:caseCount,errors:results.filter(r=>r.status==='NATIVE_ERROR').length,oracles:oracle.length,oracle_failures:oracle.filter(r=>r.status==='FAIL').length,max:special.length}));
