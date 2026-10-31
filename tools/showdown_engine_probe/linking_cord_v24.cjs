'use strict';
const path=require('node:path'),assert=require('node:assert/strict'),fs=require('node:fs');
const ROOT=path.resolve(__dirname,'../..');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {Dex}=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim'));
const field=require('../../modules/battle/backends/showdown/field_held_items.cjs');
const checks=[];
function test(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.message});}}
function start(item='linking_cord',format='gen9calvounifiedv1',move='growl',enemy='growl'){
 const e=new NativeEngine();try{e.execute({op:'start',id:'a',format,seed:[23,19,29,43],teams:{
  p1:[{instance_id:'own',species_id:'haunter',level:50,moves:[move,'growl'],held_item_id:item}],
  p2:[{instance_id:'foe',species_id:'mew',level:50,moves:[enemy]}]}});return e;}catch(err){e.close();throw err;}
}
const cp=e=>e.execute({op:'checkpoint',id:'a'});
const turn=e=>e.execute({op:'choose',id:'a',choices:{p1:'move 1',p2:'move 1'}});
function stable(v){if(typeof v==='string')return v.startsWith('|t:|')?'|t:|0':v;if(Array.isArray(v))return v.map(stable);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).filter(([k])=>k!=='elapsed_ms').map(([k,x])=>[k,stable(x)]));return v;}
test('exact descriptor, no callbacks, competitive entries preserved',()=>{
 assert.deepEqual(field.DEFINITIONS.linkingcord,{name:'Linking Cord',gen:8,fling:{basePower:30}});
 const prior=Dex.items.all().filter(x=>x.exists&&!Object.hasOwn(field.DEFINITIONS,x.id));field.install(Dex);
 for(const item of prior)assert.equal(Dex.items.get(item.id),item);
 for(const id of ['cleansetag','pureincense','smokeball'])assert.equal(Dex.items.get(id).exists,true);
});
for(const format of ['gen8customgame','gen9customgame','gen9calvounifiedv1'])test('holding never evolves; restore and deterministic continuation '+format,()=>{
 const e=start('linking_cord',format),r=new NativeEngine();try{
  turn(e);const saved=cp(e);assert.equal(saved.roster[0].pokemon[0].species_id,'haunter');assert.equal(saved.roster[0].pokemon[0].item,'linkingcord');
  r.execute({op:'restore',id:'a',snapshot:saved.snapshot});assert.deepEqual(stable(cp(r)),stable(saved));turn(e);turn(r);assert.deepEqual(stable(cp(r)),stable(cp(e)));
 }finally{e.close();r.close();}
});
test('native Fling power 30, prepare/abort/commit',()=>{
 const e=start('linking_cord',undefined,'fling'),reference=start('x_attack',undefined,'fling');try{
  const before=cp(e),draft=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  assert.equal(draft.checkpoint.roster[0].pokemon[0].item,'');assert.equal(cp(e).state_hash,before.state_hash);
  e.execute({op:'abort',id:'a',draft_token:draft.draft_token});assert.equal(cp(e).state_hash,before.state_hash);
  const next=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:'move 1',p2:'move 1'}});
  e.execute({op:'commit',id:'a',draft_token:next.draft_token});turn(reference);
  assert.equal(cp(e).roster[1].pokemon[0].hp,cp(reference).roster[1].pokemon[0].hp);assert.equal(cp(e).roster[0].pokemon[0].item,'');
 }finally{e.close();reference.close();}
});
test('Trick transfers the cord without using it',()=>{const e=start('linking_cord',undefined,'trick');try{turn(e);assert.equal(cp(e).roster[1].pokemon[0].item,'linkingcord');assert.equal(cp(e).roster[0].pokemon[0].species_id,'haunter');}finally{e.close();}});
test('Knock Off removes it without evolution',()=>{const e=start('linking_cord',undefined,'growl','knock_off');try{turn(e);assert.equal(cp(e).roster[0].pokemon[0].item,'');assert.equal(cp(e).roster[0].pokemon[0].species_id,'haunter');}finally{e.close();}});
test('three remaining descriptors are still real dependencies',()=>{
 const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/item_selection_v1.json'))),data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'))),connections=JSON.parse(fs.readFileSync(path.join(ROOT,'modules/inventory/item_connections_v1.json')));
 const allowed=connections.holdable_ids.filter(id=>!Object.hasOwn(policy.excluded_ids,id)&&!Object.hasOwn(policy.excluded_categories,data.items[id].category));
 const missing=allowed.filter(id=>{let key=id;if(id.endsWith('_z_held')&&Dex.items.get(id.slice(0,-5)).zMove)key=id.slice(0,-5);return !Dex.items.get(key).exists;});
 assert.equal(allowed.length,625);assert.deepEqual(missing.sort(),['amulet_coin','exp_share','luck_incense']);
});
console.log(JSON.stringify({checks:checks.length,failed:checks.filter(x=>x.status==='FAIL').length,results:checks},null,2));process.exitCode=checks.some(x=>x.status==='FAIL')?1:0;
