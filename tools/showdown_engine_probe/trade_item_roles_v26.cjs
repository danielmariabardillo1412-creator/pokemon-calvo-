'use strict';
// Read primary installed simulator definitions, not a guessed competitive list.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),{execFileSync}=require('node:child_process');
const ROOT=path.resolve(__dirname,'../..');
const {Dex}=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim'));
require('../../modules/battle/backends/showdown/field_held_items.cjs').install(Dex);
const load=file=>JSON.parse(fs.readFileSync(path.join(ROOT,file),'utf8'));
const candidates=load('docs/current/ITEM_SCOPE_V25.json').trade_item_candidates;
const retained=load('docs/current/ITEM_SCOPE_V25.json').retain_for_battle;
const policy=load('config/item_selection_v1.json'),data=load('data/normalized/pokemon_api.json'),connections=load('modules/inventory/item_connections_v1.json');
const base=JSON.parse(execFileSync('git',['show','e9a4812:config/item_selection_v1.json'],{cwd:ROOT,encoding:'utf8'}));
const checks=[],roles=[];
function test(name,fn){try{fn();checks.push({name,status:'PASS'});}catch(e){checks.push({name,status:'FAIL',error:e.message});}}
test('exactly the ten reviewed IDs added; prior bans and category rules unchanged',()=>{
 const added=Object.keys(policy.excluded_ids).filter(id=>!Object.hasOwn(base.excluded_ids,id)).sort();
 assert.equal(candidates.length,10);assert.deepEqual(added,candidates.map(x=>x.id).sort());
 for(const [id,reason]of Object.entries(base.excluded_ids))assert.equal(policy.excluded_ids[id],reason);
 assert.deepEqual(policy.excluded_categories,base.excluded_categories);
});
for(const row of candidates)test(row.id+' evolution role reviewed and excluded',()=>{
 const item=Dex.items.get(row.id),callbacks=Object.keys(item).filter(k=>/^on[A-Z]/.test(k)&&typeof item[k]==='function');
 assert.equal(item.exists,true);assert.match(item.desc||item.shortDesc,/Evolves .* when traded\./);
 assert.equal(callbacks.length,0);assert(item.fling&&item.fling.basePower>0);
 assert.equal(policy.excluded_ids[row.id],'trade_evolution_item_not_needed_in_level_evolution_design');
 assert(data.items[row.id]);assert(connections.holdable_ids.includes(row.id));
 roles.push({id:row.id,name_es:row.name_es,primary_description:item.desc||item.shortDesc,fling_power:item.fling.basePower,direct_battle_callbacks:callbacks,canonical_definition_preserved:true,status:'EXCLUDED_FROM_CURRENT_GAME'});
});
for(const row of retained)test(row.id+' distinct battle effect remains permitted',()=>{
 const item=Dex.items.get(row.id),callbacks=Object.keys(item).filter(k=>/^on[A-Z]/.test(k)&&typeof item[k]==='function');
 assert(callbacks.length>0);assert(!Object.hasOwn(policy.excluded_ids,row.id));assert(!Object.hasOwn(policy.excluded_categories,data.items[row.id].category));
 roles.push({id:row.id,name_es:row.name_es,primary_description:item.desc||item.shortDesc,direct_battle_callbacks:callbacks,status:'RETAINED_BATTLE_ROLE'});
});
let permitted=[],missing=[];
test('current policy and native coverage counted without deleting definitions',()=>{
 const excluded=Object.keys(data.items).filter(id=>Object.hasOwn(policy.excluded_ids,id)||Object.hasOwn(policy.excluded_categories,data.items[id].category));
 assert.equal(excluded.length,54);
 permitted=connections.holdable_ids.filter(id=>!Object.hasOwn(policy.excluded_ids,id)&&!Object.hasOwn(policy.excluded_categories,data.items[id].category));
 missing=permitted.filter(id=>{let key=id;if(id.endsWith('_z_held')&&Dex.items.get(id.slice(0,-5)).zMove)key=id.slice(0,-5);return !Dex.items.get(key).exists;}).sort();
 assert.equal(permitted.length,614);assert.deepEqual(missing,['amulet_coin','exp_share','luck_incense']);
});
console.log(JSON.stringify({checks:checks.length,failed:checks.filter(x=>x.status==='FAIL').length,results:checks,roles,counts:{excluded:54,permitted_holdable:permitted.length,native_present:permitted.length-missing.length,native_missing:missing}},null,2));
process.exitCode=checks.some(x=>x.status==='FAIL')?1:0;
