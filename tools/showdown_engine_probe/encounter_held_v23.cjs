'use strict';
// Independent native expectations: pinned RHH Fling powers 30/10, Gen 2/4.
const path=require('node:path'),assert=require('node:assert/strict'),fs=require('node:fs');
const ROOT=path.resolve(__dirname,'../..');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {Dex}=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim'));
const field=require('../../modules/battle/backends/showdown/field_held_items.cjs');
const rows=[['cleanse_tag','Cleanse Tag',2,30],['pure_incense','Pure Incense',4,10]];
const checks=[];
function test(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.message});}}
const norm=id=>id.replaceAll('_','');
const cp=e=>e.execute({op:'checkpoint',id:'a'});
const own=e=>cp(e).roster[0].pokemon[0];
function start(item,format='gen9calvounifiedv1',moves=['growl'],foe='growl'){
 const e=new NativeEngine();
 try{e.execute({op:'start',id:'a',format,seed:[23,19,29,43],teams:{
  p1:[{instance_id:'own',species_id:'mew',level:50,moves,held_item_id:item}],
  p2:[{instance_id:'foe',species_id:'mew',level:50,moves:[foe]}]}});return e;
 }catch(err){e.close();throw err;}
}
function turn(e,move='move 1'){return e.execute({op:'choose',id:'a',choices:{p1:move,p2:'move 1'}});}
function stable(v){
 if(typeof v==='string')return v.startsWith('|t:|')?'|t:|0':v;
 if(Array.isArray(v))return v.map(stable);
 if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).filter(([k])=>k!=='elapsed_ms').map(([k,x])=>[k,stable(x)]));
 return v;
}
for(const [id,name,gen,power]of rows){
 test(id+' exact identity and native-only metadata',()=>{
  assert.deepEqual(field.DEFINITIONS[norm(id)],{name,gen,fling:{basePower:power}});
  const old=Dex.items.all().filter(x=>x.exists&&!Object.hasOwn(field.DEFINITIONS,x.id)).map(x=>[x.id,x]);
  field.install(Dex);
  for(const [key,value]of old)assert.equal(Dex.items.get(key),value);
  assert.equal(Dex.mod('gen8').items.get(id).exists,true);
 });
 for(const format of ['gen8customgame','gen9customgame','gen9calvounifiedv1'])test(id+' save and deterministic continuation '+format,()=>{
  const e=start(id,format),r=new NativeEngine();try{
   assert.equal(own(e).item,norm(id));turn(e);const saved=cp(e);
   r.execute({op:'restore',id:'a',snapshot:saved.snapshot});assert.deepEqual(stable(cp(r)),stable(saved));
   turn(e);turn(r);assert.deepEqual(stable(cp(e)),stable(cp(r)));
  }finally{e.close();r.close();}
 });
 test(id+' Fling power and transaction match native reference',()=>{
  const e=start(id,undefined,['fling','growl']),reference=start(power===30?'x_attack':'mental_herb',undefined,['fling','growl']);
  try{
   const before=cp(e);const draft=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
   assert.equal(draft.checkpoint.roster[0].pokemon[0].item,'');assert.equal(cp(e).state_hash,before.state_hash);
   e.execute({op:'abort',id:'a',draft_token:draft.draft_token});assert.equal(cp(e).state_hash,before.state_hash);
   const next=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
   e.execute({op:'commit',id:'a',draft_token:next.draft_token});turn(reference);
   assert.equal(own(e).item,'');assert.equal(cp(e).roster[1].pokemon[0].hp,cp(reference).roster[1].pokemon[0].hp);
  }finally{e.close();reference.close();}
 });
 test(id+' Trick moves the actual item to the other side',()=>{
  const e=start(id,undefined,['trick']);try{turn(e);assert.equal(own(e).item,'');assert.equal(cp(e).roster[1].pokemon[0].item,norm(id));}finally{e.close();}
 });
 test(id+' Knock Off removes the actual item',()=>{
  const e=start(id,undefined,['growl'],'knock_off');try{turn(e);assert.equal(own(e).item,'');}finally{e.close();}
 });
 test(id+' no fabricated passive battle effect or RNG draws',()=>{
  const e=start(id),plain=start('');try{turn(e);turn(plain);
   for(const key of ['hp','boosts','stats','status_id','moves'])assert.deepEqual(own(e)[key],own(plain)[key]);
   assert.deepEqual(cp(e).snapshot.native.prng,cp(plain).snapshot.native.prng);
  }finally{e.close();plain.close();}
 });
}
test('four remaining metadata gaps stay absent, not neutral',()=>{
 const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json')));
 const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/item_selection_v1.json')));
 const connections=JSON.parse(fs.readFileSync(path.join(ROOT,'modules/inventory/item_connections_v1.json')));
 const allowed=connections.holdable_ids.filter(id=>!Object.hasOwn(policy.excluded_ids,id)&&!Object.hasOwn(policy.excluded_categories,data.items[id].category));
 const missing=allowed.filter(id=>{let key=id;if(id.endsWith('_z_held')&&Dex.items.get(id.slice(0,-5)).zMove)key=id.slice(0,-5);return !Dex.items.get(key).exists;});
 assert.equal(allowed.length,625);assert.deepEqual(missing.sort(),['amulet_coin','exp_share','linking_cord','luck_incense']);
});
console.log(JSON.stringify({checks:checks.length,failed:checks.filter(x=>x.status==='FAIL').length,results:checks},null,2));
process.exitCode=checks.some(x=>x.status==='FAIL')?1:0;
