'use strict';
// Evidence for contexts that cannot be certified by an ordinary held-item battle.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const read=p=>JSON.parse(fs.readFileSync(path.join(ROOT,p),'utf8'));
const previous=read('docs/current/ITEM_VERIFICATION_V2.json');
const prototypes=read('.godot/item_verification_v3/prototypes.json');
const catalog=read('data/normalized/pokemon_api.json');
const covered=new Set(read('.godot/item_verification_v3/native.json').results.map(x=>x.id));
const target=previous.rows.filter(r=>['HELD_COMBAT_CANDIDATE','BERRY'].includes(r.family)&&r.battle_effect_status==='SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING');
assert.equal(target.length,112);
const evBerries=new Set(['pomeg_berry','kelpsy_berry','qualot_berry','hondew_berry','grepa_berry','tamato_berry']);
const pending=[];
for(const row of target){
 if(covered.has(row.id))continue;
 const item=lookup('items',row.id);
 let group,reason;
 if(row.family==='BERRY'){
  group=evBerries.has(row.id)?'FIELD_TRAINING_BRIDGE':'FOOD_CONTEST_OR_WORLD_CONTEXT';
  reason=evBerries.has(row.id)?'EV/friendship reduction requires a permanent owned-state field-use route; FieldItemService currently rejects unconnected uses.':'No direct passive battle effect is certified. Contest/food/growing or other world use needs its own retained gameplay system; this is not a battle failure.';
 }else if(row.id==='destiny_knot'){
  group='GENDER_INFATUATION_AND_BREEDING_CONTEXT';
  reason='CreatureInstance/nativeSet has no explicit persisted gender contract. Infatuation cannot be certified with random implicit genders; breeding is also not connected.';
 }else{
  group='SPECIES_FORM_ROUTE';
  reason='The canonical catalog exposes the base species, not the required item-specific form. Native forcedForme metadata is not a substitute for a validated owned-state/form/projection route.';
 }
 const requiredForm=item.forcedForme??(row.id==='rusted_sword'?'Zacian-Crowned':row.id==='rusted_shield'?'Zamazenta-Crowned':null);
 if(requiredForm)assert(!Object.keys(catalog.species).some(x=>lookup('species',x).id===lookup('species',requiredForm).id));
 pending.push({id:row.id,name_es:row.name_es,family:row.family,group,reason,required_native_form:requiredForm,native_description:item.desc,passive_battle_hooks:Object.keys(item).filter(k=>k.startsWith('on'))});
}
assert.equal(pending.length,47);
const probes=[];
for(const [species,id,ability] of [['silvally','bug_memory','rks_system'],['genesect','burn_drive','download'],['ogerpon','wellspring_mask','water_absorb'],['zacian','rusted_sword','intrepid_sword'],['zamazenta','rusted_shield','dauntless_shield']]){
 const a=structuredClone(prototypes[species]),b=structuredClone(prototypes.mew);a.instance_id='actor';a.held_item_id=id;a.ability_id=ability;b.instance_id='foe';
 const engine=new NativeEngine();
 try{engine.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:{p1:[a],p2:[b]},seed:[1,2,3,4]});const cp=engine.execute({op:'checkpoint',id:'a'});probes.push({id,base_species:species,native_initial_species:cp.roster[0].pokemon[0].species_id,expected_form:lookup('items',id).forcedForme??lookup('species',species+'crowned').name});}
 finally{engine.close();}
}
const group_counts={};for(const x of pending)group_counts[x.group]=(group_counts[x.group]??0)+1;
fs.writeFileSync(path.join(ROOT,'.godot/item_verification_v3/dependencies.json'),JSON.stringify({target_ids:target.map(x=>x.id),tested_ids:[...covered].sort(),pending,group_counts,probes},null,2));
console.log('ITEM_DEPENDENCIES_V3',covered.size,'tested,',pending.length,'explicit pending',group_counts);
