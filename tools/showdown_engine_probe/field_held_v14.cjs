'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {spawnSync,execFileSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const runtime=path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim');
const {Dex}=require(runtime);
// Exercise registration when generation data and the all-items cache were
// already read by another integration consumer, before loading the adapter.
Dex.mod('gen8').items.all();Dex.items.all();
const before=new Map(Dex.items.all().map(x=>[x.id,x]));
const Field=require('../../modules/battle/backends/showdown/field_held_items.cjs');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const checks=[];
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.stack});}}
const mon=(id,move,item='')=>({instance_id:id,species_id:'mew',level:50,nature_id:'hardy',ability_id:'',held_item_id:item,moves:Array.isArray(move)?move:[move],ivs:{hp:31,attack:31,defense:31,speed:31,special_attack:31,special_defense:31}});
function start(format,move,item='soothe_bell',otherMove='growl',otherItem=''){
 const e=new NativeEngine();try{e.execute({op:'start',id:'a',format,teams:{p1:[mon('own',move,item)],p2:[mon('foe',otherMove,otherItem)]},seed:[23,19,29,43]});return e;}catch(error){e.close();throw error;}
}
const cp=e=>e.execute({op:'checkpoint',id:'a'});
const pokemon=(data,side=0)=>data.roster[side].pokemon[0];
function semantic(value,omitHash=false){
 if(typeof value==='string')return value.startsWith('|t:|')?'|t:|0':value;
 if(Array.isArray(value))return value.map(x=>semantic(x,omitHash));
 if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).filter(([k])=>k!=='elapsed_ms'&&!(omitHash&&k==='state_hash')).map(([k,v])=>[k,semantic(v,omitHash)]));
 return value;
}
check('only one reviewed descriptor; no native callbacks',()=>{
 assert.deepEqual(Object.keys(Field.DEFINITIONS),['soothebell']);
 assert.deepEqual(Object.keys(Field.DEFINITIONS.soothebell).sort(),['fling','gen','name']);
 assert.equal(Dex.items.get('soothebell').name,'Soothe Bell');
 assert.equal(Dex.items.get('soothebell').fling.basePower,10);
 assert.equal(Dex.items.get('soothebell').gen,3);
 assert.equal(Dex.mod('gen8').items.get('soothebell').exists,true);
 for(const [id,item] of before)assert.equal(Dex.items.get(id),item);
 assert.equal(Dex.items.all().length,before.size+1);
 Field.install(Dex);assert.equal(Dex.items.all().length,before.size+1);
});
for(const format of ['gen9customgame','gen8customgame','gen9calvounifiedv1']){
 check(format+' retains Bell, serialization and deterministic continuation',()=>{
  const e=start(format,'growl'),restored=new NativeEngine();
  try{
   const saved=cp(e);assert.equal(pokemon(saved).item,'soothebell');
   restored.execute({op:'restore',id:'a',snapshot:saved.snapshot});
   // Legacy gen8/gen9 snapshots predate the unified formatid insertion-order
   // fix. Compare their actual state, without changing historical hashes.
   assert.deepEqual(semantic(cp(restored),true),semantic(saved,true));
   if(format==='gen9calvounifiedv1')assert.equal(cp(restored).state_hash,saved.state_hash);
   for(const engine of [e,restored])engine.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
   assert.deepEqual(semantic(cp(restored)),semantic(cp(e)));assert.equal(pokemon(cp(e)).item,'soothebell');
  }finally{e.close();restored.close();}
 });
}
check('unknown item still rejected; consumed reviewed item stays absent',()=>{
 assert.throws(()=>start('gen9customgame','growl','unreviewed_field_item'),/Unknown held item/);
 const e=new NativeEngine();try{
  e.execute({op:'start',id:'a',teams:{p1:[{...mon('own','growl','soothe_bell'),held_item_consumed:true}],p2:[mon('foe','growl')]},seed:[23,19,29,43]});
  assert.equal(pokemon(cp(e)).item,'');
 }finally{e.close();}
});
check('native Trick transfers Bell instead of dropping it',()=>{
 const e=start('gen9calvounifiedv1','trick');try{
  e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
  const p=cp(e);assert.equal(pokemon(p).item,'');assert.equal(pokemon(p,1).item,'soothebell');
  assert.ok(p.snapshot.native.log.some(x=>x.includes('|Soothe Bell')));
 }finally{e.close();}
});
check('native Knock Off removes Bell and applies its normal held-item damage boost',()=>{
 const bell=start('gen9customgame','growl','soothe_bell','knock_off'),none=start('gen9customgame','growl','','knock_off');
 try{
  const hp=pokemon(cp(bell)).hp;
  for(const e of [bell,none])e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(pokemon(cp(bell)).item,'');
  assert.ok(hp-pokemon(cp(bell)).hp > hp-pokemon(cp(none)).hp);
 }finally{bell.close();none.close();}
});
check('native Fling uses power ten; itemless Fling fails; suppression preserves Bell',()=>{
 const bell=start('gen9customgame','fling'),ten=start('gen9customgame','fling','shed_shell'),none=start('gen9customgame','fling','');
 try{
  const hp=pokemon(cp(bell),1).hp;
  for(const e of [bell,ten,none])e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(pokemon(cp(bell)).item,'');assert.equal(pokemon(cp(bell),1).hp,pokemon(cp(ten),1).hp);
  assert.ok(pokemon(cp(bell),1).hp < hp);assert.equal(pokemon(cp(none),1).hp,hp);
 }finally{bell.close();ten.close();none.close();}
 const e=start('gen9customgame',['magic_room','fling']);try{
  e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
  e.execute({op:'choose',id:'a',choices:{p1:'move 2',p2:'move 1'}});assert.equal(pokemon(cp(e)).item,'soothebell');
 }finally{e.close();}
});
check('prepare/abort cannot publish a lost Bell; restore and commit agree',()=>{
 const e=start('gen9calvounifiedv1','fling');try{
  const saved=cp(e);const draft=e.execute({op:'prepare',id:'a',expected_hash:saved.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(pokemon(draft.checkpoint).item,'');assert.deepEqual(semantic(cp(e)),semantic(saved));
  e.execute({op:'abort',id:'a',draft_token:draft.draft_token});assert.deepEqual(semantic(cp(e)),semantic(saved));
  const next=e.execute({op:'prepare',id:'a',expected_hash:saved.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  const committed=e.execute({op:'commit',id:'a',draft_token:next.draft_token});assert.equal(committed.state_hash,next.checkpoint.state_hash);assert.equal(pokemon(cp(e)).item,'');
 }finally{e.close();}
});
check('Bell on either reserve survives switch and keeps independent ownership',()=>{
 const e=new NativeEngine();try{
  e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:{p1:Array.from({length:6},(_,i)=>mon('own'+i,'growl',i===5?'soothe_bell':'')),p2:Array.from({length:6},(_,i)=>mon('foe'+i,'growl',i===5?'soothe_bell':''))},seed:[23,19,29,43]});
  for(const side of cp(e).roster)assert.equal(side.pokemon[5].item,'soothebell');
  e.execute({op:'choose',id:'a',choices:{p1:'switch 6',p2:'switch 6'}});
  const data=cp(e);assert.equal(data.roster[0].active_id,'own5');assert.equal(data.roster[1].active_id,'foe5');
  // Showdown reorders its party array on switching; stable instance IDs own
  // the items, not the old array index.
  assert.equal(data.roster[0].pokemon.find(p=>p.instance_id==='own5').item,'soothebell');
  assert.equal(data.roster[1].pokemon.find(p=>p.instance_id==='foe5').item,'soothebell');
 }finally{e.close();}
});
check('ordinary item trace is identical to the exact pre-fix adapter in a fresh process',()=>{
 const filename=path.join(ROOT,'modules/battle/backends/showdown/native_engine.cjs');
 const baseline=execFileSync('git',['show','cff1b50:modules/battle/backends/showdown/native_engine.cjs'],{cwd:ROOT,encoding:'utf8'});
 const body=`const fs=require('node:fs'),Module=require('node:module');const input=JSON.parse(fs.readFileSync(0,'utf8'));let E;if(input.source){const m=new Module(input.filename);m.filename=input.filename;m.paths=Module._nodeModulePaths(require('node:path').dirname(input.filename));m._compile(input.source,input.filename);E=m.exports.NativeEngine;}else E=require(input.filename).NativeEngine;const e=new E();const out=[];try{e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:{p1:[{instance_id:'p',species_id:'mew',level:50,moves:['tackle'],held_item_id:'leftovers'}],p2:[{instance_id:'q',species_id:'mew',level:50,moves:['growl']}]},seed:[23,19,29,43]});for(let i=0;i<4;i++){out.push(e.execute({op:'checkpoint',id:'a'}));e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});}out.push(e.execute({op:'checkpoint',id:'a'}));process.stdout.write(JSON.stringify(out));}finally{e.close();}`;
 const run=source=>{const r=spawnSync(process.execPath,['-e',body],{cwd:ROOT,input:JSON.stringify({source,filename}),encoding:'utf8',timeout:30000});assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout);};
 assert.deepEqual(semantic(run(baseline)),semantic(run(null)));
});
const result={status:checks.every(x=>x.status==='PASS')?'PASS':'FAIL',checks,baseline:'cff1b50'};
const dir=path.join(ROOT,'.godot/field_held_v14');fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,'node.json'),JSON.stringify(result,null,2));
const evidence=path.join(dir,'node_runs',String(Date.now()));fs.mkdirSync(evidence,{recursive:true});fs.writeFileSync(path.join(evidence,'results.json'),JSON.stringify(result,null,2));
for(const x of checks.filter(x=>x.status==='FAIL'))console.error(x.name,x.error);
console.log('FIELD_HELD_NATIVE_V14',result.status,'checks='+checks.length);process.exitCode=result.status==='PASS'?0:1;
