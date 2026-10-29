'use strict';
module.exports=function run(options){
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'../..'),OUT=path.join(ROOT,options.output);
const runtime=path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim');
const {Dex}=require(runtime);
Dex.mod('gen8').items.all();Dex.items.all();
const before=new Map(Dex.items.all().map(x=>[x.id,x]));
const Field=require('../../modules/battle/backends/showdown/field_held_items.cjs');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
// Expectations reviewed against RHH items.h, not inferred from the bridge.
const ROWS=options.rows;
const checks=[];
const norm=id=>id.replaceAll('_','');
function check(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.stack});}}
const mon=(id,move,item='',extra={})=>({instance_id:id,species_id:'mew',level:50,nature_id:'hardy',ability_id:'',held_item_id:item,moves:Array.isArray(move)?move:[move],ivs:{hp:31,attack:31,defense:31,speed:31,special_attack:31,special_defense:31},...extra});
function start(item,move='growl',otherMove='growl',format='gen9calvounifiedv1',ownExtra={},foeExtra={}){
 const e=new NativeEngine();try{e.execute({op:'start',id:'a',format,teams:{p1:[mon('own',move,item,ownExtra)],p2:[mon('foe',otherMove,'',foeExtra)]},seed:[23,19,29,43]});return e;}catch(error){e.close();throw error;}
}
const cp=e=>e.execute({op:'checkpoint',id:'a'});
const p=(e,side=0)=>cp(e).roster[side].pokemon[0];
const turn=(e,choice='move 1')=>e.execute({op:'choose',id:'a',choices:{p1:choice,p2:'move 1'}});
function semantic(v){
 if(typeof v==='string')return v.startsWith('|t:|')?'|t:|0':v;
 if(Array.isArray(v))return v.map(semantic);
 if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).filter(([k])=>k!=='elapsed_ms').map(([k,x])=>[k,semantic(x)]));
 return v;
}
check('exact reviewed list; cache safety; definitions are metadata only',()=>{
 assert.equal(ROWS.length,options.rowCount);
 assert.deepEqual(Object.keys(Field.DEFINITIONS).sort(),['soothebell',...options.allRows.map(r=>norm(r[0]))].sort());
 for(const [id,name,gen] of ROWS){
  assert.deepEqual(Field.DEFINITIONS[norm(id)],{name,gen,fling:{basePower:30}});
  assert.equal(Dex.items.get(id).name,name);assert.equal(Dex.items.get(id).gen,gen);
  assert.equal(Dex.mod('gen8').items.get(id).fling.basePower,30);
 }
 for(const [id,item] of before)assert.equal(Dex.items.get(id),item);
 assert.equal(Dex.items.all().length,before.size+1+options.allRows.length);
 Field.install(Dex);assert.equal(Dex.items.all().length,before.size+1+options.allRows.length);
 for(const id of ['revive','maxrevive','revivalherb','sacredash','amuletcoin','unreviewed_field_item']){
  assert.equal(Dex.items.get(id).exists,false);assert.throws(()=>start(id),/Unknown held item/);
 }
});
for(const [id] of ROWS){
 check(id+' entry, post-turn restore and deterministic continuation in three profiles',()=>{
  for(const format of ['gen8customgame','gen9customgame','gen9calvounifiedv1']){
   const e=start(id,'growl','growl',format),r=new NativeEngine();try{
    turn(e);const saved=cp(e);assert.equal(p(e).item,norm(id));
    r.execute({op:'restore',id:'a',snapshot:saved.snapshot});assert.deepEqual(semantic(cp(r)),semantic(saved));
    turn(e);turn(r);assert.deepEqual(semantic(cp(r)),semantic(cp(e)));
   }finally{e.close();r.close();}
  }
 });
 check(id+' holding does not use its HP/status/PP field effect',()=>{
  const state={current_hp:100,status_state:{persistent_id:'poison'},moveset:[{move_id:'growl',current_pp:3,max_pp:40}]};
  const e=start(id,'growl','growl','gen9calvounifiedv1',state),none=start('','growl','growl','gen9calvounifiedv1',state);try{
   turn(e);turn(none);assert.equal(p(e).item,norm(id));
   for(const key of ['hp','status_id','moves','stats','boosts','ability'])assert.deepEqual(p(e)[key],p(none)[key]);
   assert.equal(p(e).status_id,'poison');assert.ok(p(e).hp<100);assert.equal(p(e).moves[0].pp,2);
  }finally{e.close();none.close();}
 });
 check(id+' native Fling equals power 30 control and does not heal its recipient',()=>{
  const target={current_hp:100,status_state:{persistent_id:'poison'}};
  const e=start(id,'fling','growl','gen9calvounifiedv1',{},target),control=start('bottle_cap','fling','growl','gen9calvounifiedv1',{},target);try{
   turn(e);turn(control);assert.equal(p(e).item,'');
   assert.equal(p(e,1).hp,p(control,1).hp);assert.ok(p(e,1).hp<100);
   assert.equal(p(e,1).status_id,'poison');assert.deepEqual(p(e,1).moves,p(control,1).moves);
  }finally{e.close();control.close();}
 });
 check(id+' native Trick transfers the actual item; consumed imports stay absent',()=>{
  const e=start(id,'trick'),spent=start(id,'growl','growl','gen9calvounifiedv1',{held_item_consumed:true});try{
   turn(e);assert.equal(p(e).item,'');assert.equal(p(e,1).item,norm(id));
   turn(spent);assert.equal(p(spent).item,'');
  }finally{e.close();spent.close();}
 });
 check(id+' native Knock Off boost and Magic Room suppression',()=>{
  const e=start(id,'growl','knock_off'),none=start('','growl','knock_off'),room=start(id,['magic_room','fling']);try{
   turn(e);turn(none);assert.equal(p(e).item,'');assert.ok(p(e).hp<p(none).hp);
   turn(room);turn(room,'move 2');assert.equal(p(room).item,norm(id));assert.equal(p(room,1).hp,p(room,1).max_hp);
  }finally{e.close();none.close();room.close();}
 });
 check(id+' prepare/abort/commit keeps native transaction authority',()=>{
  const e=start(id,'fling');try{
   const saved=cp(e),draft=e.execute({op:'prepare',id:'a',expected_hash:saved.state_hash,choices:{p1:'move 1',p2:'move 1'}});
   assert.equal(draft.checkpoint.roster[0].pokemon[0].item,'');assert.equal(cp(e).state_hash,saved.state_hash);
   e.execute({op:'abort',id:'a',draft_token:draft.draft_token});assert.equal(cp(e).state_hash,saved.state_hash);
   const next=e.execute({op:'prepare',id:'a',expected_hash:saved.state_hash,choices:{p1:'move 1',p2:'move 1'}});
   const committed=e.execute({op:'commit',id:'a',draft_token:next.draft_token});assert.equal(committed.state_hash,next.checkpoint.state_hash);assert.equal(p(e).item,'');
  }finally{e.close();}
 });
}
const profile=JSON.parse(fs.readFileSync(path.join(ROOT,'modules/inventory/item_connections_v1.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/item_selection_v1.json'),'utf8'));
const allowed=profile.holdable_ids.filter(id=>!Object.hasOwn(policy.excluded_ids,id)&&!Object.hasOwn(policy.excluded_categories,data.items[id]?.category));
const missing=allowed.filter(id=>{let key=id;if(id.endsWith('_z_held')&&Dex.items.get(id.slice(0,-5)).zMove)key=id.slice(0,-5);return !Dex.items.get(key).exists;});
check('reviewed rows are permitted; all remaining definition gaps explicit',()=>{
 assert.equal(allowed.length,625);assert.equal(missing.length,options.expectedMissing);
 for(const [id] of ROWS)assert.ok(allowed.includes(id)&&!missing.includes(id));
});
const result={status:checks.every(x=>x.status==='PASS')?'PASS':'FAIL',checks,[options.reportKey]:ROWS,
 permitted_holdable:allowed.length,permitted_native_present:allowed.length-missing.length,permitted_missing:missing,baseline:options.baseline};
fs.mkdirSync(OUT,{recursive:true});fs.writeFileSync(path.join(OUT,'node.json'),JSON.stringify(result,null,2));
const evidence=path.join(OUT,'node_runs',String(Date.now()));fs.mkdirSync(evidence,{recursive:true});fs.writeFileSync(path.join(evidence,'results.json'),JSON.stringify(result,null,2));
for(const x of checks.filter(x=>x.status==='FAIL'))console.error(x.name,x.error);
console.log(options.label,result.status,'checks='+checks.length);process.exitCode=result.status==='PASS'?0:1;

return result;
};
