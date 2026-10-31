'use strict';
// Tests of existing behavior. Diagnostic teams isolate effects, not randomlocke eligibility.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=path.join(ROOT,'.godot/item_verification_v3');
const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const own=cp=>cp.roster[0].pokemon.find(p=>p.instance_id==='actor');
const foe=cp=>cp.roster[1].pokemon.find(p=>p.instance_id==='foe');
const choices=(p1='move 1',p2='move 1')=>({p1,p2});
const cases=[];
function add(id,family,opt,verify,seeds=[1,19]){assert(data.items[id]);assert(lookup('items',id).exists);cases.push({id,family,opt,verify,seeds});}
function mon(id,key,moves,item=''){
 const p=clone(prototypes[key]);assert(p, key);p.instance_id=id;p.held_item_id=item;p.held_item_consumed=false;p.move_ids=moves;
 p.moveset=moves.map(move_id=>{assert(data.moves[move_id],move_id);return {move_id,current_pp:data.moves[move_id].pp,max_pp:data.moves[move_id].pp};});return p;
}
function simulate(origin,seed,commands,tracked){
 const e=new NativeEngine();
 try{
  e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:origin,seed:[seed,2,3,4]});
  const before=e.execute({op:'checkpoint',id:'a'}),steps=[],observed=[];
  for(const cmd of commands){
   const cp=e.execute({op:'checkpoint',id:'a'});
   const d=e.execute({op:'prepare',id:'a',expected_hash:cp.state_hash,choices:cmd});
   assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,cp.state_hash,'Prepare cannot publish');
   steps.push(e.execute({op:'commit',id:'a',draft_token:d.draft_token}));
   const battle=e.sessions.get('a').battle;
   observed.push(battle.sides.map(s=>s.active.map(p=>({stats:Object.fromEntries(['atk','def','spa','spd','spe'].map(x=>[x,p.getStat(x)])),weight:p.getWeight(),ignoringAbility:p.ignoringAbility()}))));
  }
  const after=steps.at(-1);
  if(tracked){const restored=new NativeEngine();try{restored.execute({op:'restore',id:'a',snapshot:after.snapshot});assert.equal(restored.execute({op:'checkpoint',id:'a'}).state_hash,after.state_hash);}finally{restored.close();}}
  return {before,after,steps,facts:observed,log:e.sessions.get('a').battle.log.slice(),commands};
 }finally{e.close();}
}
const consumed=a=>assert.equal(own(a.after).item,'');
const retained=a=>assert(own(a.after).item);
const moreDamage=(a,b)=>assert(foe(a.after).hp<foe(b.after).hp,'Matching holder/type must increase damage');
const sameDamage=(a,b)=>{assert.equal(foe(a.after).hp,foe(b.after).hp);retained(a);};
const statUp=(a,b,stat)=>assert(a.facts.at(-1)[0][0].stats[stat]>b.facts.at(-1)[0][0].stats[stat]);
const first=a=>a.log.find(l=>l.startsWith('|move|')).startsWith('|move|p1a:');
const seeds=Array.from({length:64},(_,i)=>i+1);

for(const [id,species,moves] of [['adamant_orb','dialga',['dragon_pulse','flash_cannon']],['lustrous_orb','palkia',['dragon_pulse','water_gun']],['griseous_orb','giratina',['dragon_pulse','shadow_ball']],['soul_dew','latias',['dragon_pulse','confusion']]]){
 for(const move of moves)add(id,'signature_boost_'+move,{species,moves:[move]},moreDamage);
 add(id,'wrong_holder',{moves:[moves[0]]},sameDamage);
 add(id,'wrong_type',{species,moves:['tackle']},sameDamage);
}
for(const [id,move] of [['odd_incense','confusion'],['rock_incense','smack_down'],['rose_incense','absorb'],['sea_incense','water_gun'],['wave_incense','water_gun']]){
 add(id,'type_boost',{moves:[move]},moreDamage);add(id,'wrong_type',{moves:['tackle']},sameDamage);
}
for(const [id,species,move] of [['light_ball','pikachu','thunder_shock'],['light_ball','pikachu','tackle'],['thick_club','cubone','tackle'],['thick_club','marowak','tackle'],['deep_sea_tooth','clamperl','water_gun']]){
 add(id,'species_boost_'+species+'_'+move,{species,moves:[move]},moreDamage);
 add(id,'wrong_holder_'+species+'_'+move,{moves:[move]},sameDamage);
}
for(const [id,species,move] of [['deep_sea_scale','clamperl','confusion'],['eviolite','chansey','confusion'],['eviolite','chansey','tackle'],['metal_powder','ditto','tackle']]){
 add(id,'species_defense_'+move,{species,foeMoves:[move]},(a,b)=>assert(own(a.after).hp>own(b.after).hp));
 add(id,'wrong_holder_'+move,{species:id==='eviolite'?'blissey':'mew',foeMoves:[move]},(a,b)=>assert.equal(own(a.after).hp,own(b.after).hp));
}
add('metal_powder','transformed_no_boost',{species:'ditto',moves:['transform','reflect'],foeSpecies:'snorlax',foeMoves:['reflect','tackle'],commands:[choices(),choices('move 1','move 2')]},(a,b)=>assert.equal(own(a.after).hp,own(b.after).hp));
add('quick_powder','untransformed_speed',{species:'ditto'},(a,b)=>statUp(a,b,'spe'));
add('quick_powder','transformed_no_boost',{species:'ditto',moves:['transform'],foeSpecies:'snorlax'},(a,b)=>assert.equal(a.facts[0][0][0].stats.spe,b.facts[0][0][0].stats.spe));
add('float_stone','weight_threshold',{species:'garchomp',foeMoves:['grass_knot']},(a,b)=>{assert.equal(a.facts[0][0][0].weight,b.facts[0][0][0].weight/2);assert(own(a.after).hp>own(b.after).hp);});
add('float_stone','fixed_power_control',{species:'garchomp',foeMoves:['tackle']},(a,b)=>assert.equal(own(a.after).hp,own(b.after).hp));
add('iron_ball','speed_halved',{species:'gengar',foeMoves:['reflect']},(a,b)=>assert.equal(a.facts[0][0][0].stats.spe,Math.floor(b.facts[0][0][0].stats.spe/2)));
add('iron_ball','grounded_flying_holder',{species:'charizard',foeMoves:['earthquake']},(a,b)=>{assert(own(a.after).hp<own(b.after).hp);assert.equal(own(b.after).hp,own(b.before).hp);});
for(const id of ['full_incense','lagging_tail']){
 add(id,'last_same_priority',{species:'gengar',foeSpecies:'snorlax'},(a,b)=>{assert(!first(a));assert(first(b));});
 add(id,'priority_preserved',{species:'gengar',moves:['quick_attack'],foeSpecies:'snorlax'},a=>assert(first(a)));
}
add('ability_shield','ability_suppression',{ability:'synchronize',foeMoves:['gastro_acid']},(a,b)=>{assert(!a.facts[0][0][0].ignoringAbility);assert(b.facts[0][0][0].ignoringAbility);});
add('adrenaline_orb','intimidate_trigger',{foeSpecies:'gyarados',foeAbility:'intimidate'},a=>{consumed(a);assert.equal(own(a.after).boosts.spe,1);});
add('adrenaline_orb','no_intimidate',{},retained);
for(const [species,ability] of [['great_tusk','protosynthesis'],['iron_hands','quark_drive']])add('booster_energy','paradox_'+species,{species,ability},(a,b)=>{consumed(a);assert(Object.keys(own(a.after).boosts).length);assert(a.facts[0][0][0].stats.atk>b.facts[0][0][0].stats.atk || a.facts[0][0][0].stats.def>b.facts[0][0][0].stats.def);});
add('booster_energy','wrong_ability',{},retained);
add('eject_pack','self_drop',{moves:['close_combat'],reserve:true},a=>{consumed(a);assert(a.after.views.p1.request.forceSwitch[0]);});
add('eject_pack','no_drop',{reserve:true},retained);
add('mirror_herb','positive_copy',{foeMoves:['swords_dance']},a=>{consumed(a);assert.equal(own(a.after).boosts.atk,2);});
add('mirror_herb','negative_not_copied',{foeMoves:['growl']},a=>{retained(a);assert.equal(own(a.after).boosts.atk,-1);});
add('room_service','trick_room',{foeMoves:['trick_room']},a=>{consumed(a);assert.equal(own(a.after).boosts.spe,-1);});
add('room_service','no_room',{},retained);
for(const [id,terrain,stat] of [['electric_seed','electric_terrain','def'],['grassy_seed','grassy_terrain','def'],['misty_seed','misty_terrain','spd'],['psychic_seed','psychic_terrain','spd']]){
 for(const species of ['mew','charizard'])add(id,'terrain_'+species,{species,foeMoves:[terrain]},a=>{consumed(a);assert.equal(own(a.after).boosts[stat],1);});
 add(id,'wrong_terrain',{foeMoves:[terrain==='electric_terrain'?'misty_terrain':'electric_terrain']},retained);
}
function field(cp){return cp.snapshot.native.field;}
for(const [id,move] of [['damp_rock','rain_dance'],['heat_rock','sunny_day'],['icy_rock','snowscape'],['smooth_rock','sandstorm']]){
 add(id,'weather_duration',{moves:[move]},(a,b)=>assert.equal(field(a.after).weatherState.duration-field(b.after).weatherState.duration,3));
 add(id,'no_weather',{},retained);
}
add('terrain_extender','terrain_duration',{moves:['electric_terrain']},(a,b)=>assert.equal(field(a.after).terrainState.duration-field(b.after).terrainState.duration,3));
add('utility_umbrella','incoming_sun_fire',{moves:['sunny_day'],foeSpecies:'snorlax',foeMoves:['ember']},(a,b)=>assert(own(a.after).hp>own(b.after).hp));
add('utility_umbrella','incoming_rain_water',{moves:['rain_dance'],foeSpecies:'snorlax',foeMoves:['water_gun']},(a,b)=>assert(own(a.after).hp>own(b.after).hp));
add('utility_umbrella','clear_weather',{foeMoves:['ember']},(a,b)=>assert.equal(own(a.after).hp,own(b.after).hp));
add('shed_shell','switch_despite_trap',{reserve:true,foeMoves:['mean_look'],commands:[choices(),choices('switch 2')],baselineCommands:[choices()]},(a,b)=>{assert(!a.steps[0].views.p1.request.active[0].trapped);assert(b.after.views.p1.request.active[0].trapped);assert.equal(a.after.roster[0].active_id,'reserve');});
add('binding_band','partial_trap_residual',{moves:['infestation']},(a,b)=>assert.equal(foe(b.after).hp-foe(a.after).hp,Math.floor(foe(a.after).max_hp/6)-Math.floor(foe(b.after).max_hp/8)));
add('grip_claw','partial_trap_duration',{moves:['infestation','reflect'],commands:[choices(),...Array.from({length:6},()=>choices('move 2'))]},(a,b)=>{assert(foe(a.after).hp<foe(b.after).hp);assert.equal(a.log.filter(l=>l.startsWith('|-damage|')&&l.includes('[from] move: Infestation')).length/2,7);assert(b.log.filter(l=>l.startsWith('|-damage|')&&l.includes('[from] move: Infestation')).length/2<=5);});
add('metronome','repeat_and_reset',{species:'mew_50',moves:['water_gun','reflect'],commands:[choices(),choices(),choices(),choices('move 2'),choices()]},(a,b)=>{
 const damages=x=>x.steps.map((s,i)=>foe(i?x.steps[i-1]:x.before).hp-foe(s).hp);
 const actual=damages(a),base=damages(b);assert.equal(actual[0],base[0]);assert(actual[1]>base[1]);assert(actual[2]>base[2]);assert.equal(actual[4],base[4]);
});
add('sticky_barb','residual',{},a=>assert.equal(own(a.before).hp-own(a.after).hp,Math.floor(own(a.before).max_hp/8)));
add('sticky_barb','contact_transfer',{foeMoves:['tackle']},a=>{consumed(a);assert.equal(foe(a.after).item,'stickybarb');});
for(const [species,move] of [['gengar','tackle'],['charizard','earthquake']])add('ring_target','type_immunity_'+species,{species,foeMoves:[move]},(a,b)=>{assert(own(a.after).hp<own(b.after).hp);assert.equal(own(b.after).hp,own(b.before).hp);});
add('ring_target','ability_immunity_preserved',{ability:'levitate',foeMoves:['earthquake']},(a,b)=>assert.equal(own(a.after).hp,own(b.after).hp));

for(const id of ['scope_lens','razor_claw','lucky_punch','stick']){
 const species=id==='lucky_punch'?'chansey':id==='stick'?'farfetchd':'mew';
 add(id,'critical_stage',{species,moves:['focus_energy','tackle'],commands:[choices(),choices('move 2')]},a=>assert(a.log.some(l=>l.startsWith('|-crit|p2a:'))),seeds.slice(0,16));
 if(['lucky_punch','stick'].includes(id))add(id,'wrong_species',{moves:['focus_energy','tackle'],commands:[choices(),choices('move 2')]},(a,b)=>assert.equal(a.log.filter(l=>l.startsWith('|-crit|')).length,b.log.filter(l=>l.startsWith('|-crit|')).length),seeds.slice(0,16));
}
add('focus_band','survival_rng',{species:'pikachu_1',foeMoves:['seismic_toss']},(a,b)=>{assert.equal(own(b.after).hp,0);assert([0,1].includes(own(a.after).hp));retained(a);return own(a.after).hp===1?'activated':'not_activated';},seeds);
add('quick_claw','order_rng',{foeSpecies:'gengar'},(a,b)=>{assert(!first(b));retained(a);assert.equal(first(a),a.log.some(l=>l.includes('item: Quick Claw')));return first(a)?'activated':'not_activated';},seeds);
for(const id of ['kings_rock','razor_fang'])add(id,'flinch_rng',{moves:['tackle'],foeSpecies:'snorlax'},(a,b)=>{assert(!b.log.some(l=>l.includes('|flinch')));retained(a);return a.log.some(l=>l.includes('|flinch'))?'activated':'not_activated';},seeds);
add('lax_incense','accuracy_rng',{foeMoves:['tackle']},(a,b)=>{assert(!b.log.some(l=>l.startsWith('|-miss|')));retained(a);return a.log.some(l=>l.startsWith('|-miss|'))?'activated':'not_activated';},seeds);
for(const fast of [false,true])add('zoom_lens',fast?'faster_no_boost':'slower_accuracy',{species:fast?'gengar':'mew',moves:['hydro_pump'],foeSpecies:fast?'snorlax':'gengar'},(a,b)=>{
 const miss=x=>x.log.some(l=>l.startsWith('|-miss|'));if(fast)assert.equal(miss(a),miss(b));else assert(!miss(a)||miss(b));return !miss(a)&&miss(b)?'activated':'not_activated';
},seeds);
add('blunder_policy','accuracy_miss_trigger',{moves:['zap_cannon']},a=>{const miss=a.log.some(l=>l.startsWith('|-miss|'));assert.equal(own(a.after).boosts.spe,miss?2:0);if(miss)consumed(a);else retained(a);return miss?'activated':'not_activated';},seeds.slice(0,32));

for(const [id,nature] of [['aguav_berry','naughty'],['iapapa_berry','lonely'],['mago_berry','brave'],['wiki_berry','adamant']]){
 for(const badNature of [false,true])add(id,badNature?'heal_and_disliked_flavor':'heal_without_confusion',{species:badNature?'mew_'+nature:'mew',foeSpecies:'snorlax',foeMoves:['endeavor'],foeHP:1},a=>{consumed(a);assert.equal(own(a.after).hp,1+Math.floor(own(a.after).max_hp/3));assert.equal(own(a.after).volatiles.includes('confusion'),badNature);});
 add(id,'high_hp_no_trigger',{},retained);
}
add('custap_berry','low_hp_order',{species:'snorlax',hp:.2,foeSpecies:'gengar'},(a,b)=>{consumed(a);assert(first(a));assert(!first(b));});
add('custap_berry','full_hp',{},retained);
add('enigma_berry','super_effective_heal',{species:'gyarados',foeMoves:['thunder_shock']},(a,b)=>{consumed(a);assert.equal(own(a.after).hp-own(b.after).hp,Math.floor(own(a.after).max_hp/4));});
add('enigma_berry','neutral_no_trigger',{foeMoves:['tackle']},retained);
for(const [id,move,wrong] of [['jaboca_berry','tackle','confusion'],['rowap_berry','confusion','tackle']]){
 add(id,'category_retaliation',{foeMoves:[move]},a=>{consumed(a);assert.equal(foe(a.before).hp-foe(a.after).hp,Math.floor(foe(a.before).max_hp/8));});
 add(id,'wrong_category',{foeMoves:[wrong]},retained);
}
add('lansat_berry','critical_focus',{hp:.2},a=>{consumed(a);assert(own(a.after).volatiles.includes('focusenergy'));});
add('lansat_berry','full_hp',{},retained);
add('leppa_berry','empty_pp',{moves:['tackle','reflect'],pp:0,commands:[choices('move 2')]},a=>{consumed(a);assert.equal(own(a.after).moves[0].pp,10);});
add('leppa_berry','nonempty_pp',{moves:['tackle','reflect'],pp:1,commands:[choices('move 2')]},retained);
add('micle_berry','next_move_accuracy',{hp:.2,moves:['reflect','hydro_pump'],commands:[choices(),choices('move 2')]},(a,b)=>{assert(own(a.steps[0]).volatiles.includes('micleberry'));consumed(a);assert(!own(a.after).volatiles.includes('micleberry'));const miss=x=>x.log.some(l=>l.startsWith('|-miss|'));assert(!miss(a)||miss(b));return !miss(a)&&miss(b)?'activated':'not_activated';},seeds);
add('micle_berry','full_hp',{},retained);
add('starf_berry','one_random_stat',{hp:.2},a=>{consumed(a);const v=['atk','def','spa','spd','spe'].map(k=>own(a.after).boosts[k]);assert.equal(v.filter(x=>x===2).length,1);assert.equal(v.reduce((x,y)=>x+y,0),2);},seeds.slice(0,16));
add('starf_berry','full_hp',{},retained);

const results=[],rows=[];
for(const c of cases)for(const seed of c.seeds){
 const o=c.opt,origin={p1:[mon('actor',o.species??'mew',o.moves??['reflect'],c.id)],p2:[mon('foe',o.foeSpecies??'mew',o.foeMoves??['reflect'],o.foeItem??'')]};
 if(o.hp)origin.p1[0].current_hp=Math.floor(origin.p1[0].stats.max_hp*o.hp);
 if(o.foeHP)origin.p2[0].current_hp=o.foeHP;
 if(o.ability)origin.p1[0].ability_id=o.ability;if(o.foeAbility)origin.p2[0].ability_id=o.foeAbility;
 if(o.pp!==undefined)origin.p1[0].moveset[0].current_pp=o.pp;
 if(o.reserve)origin.p1.push(mon('reserve','mew',['reflect']));
 const result={id:c.id,family:c.family,seed,case_id:c.id+'/'+c.family+'/'+seed,status:'FAIL_NATIVE_OR_FIXTURE'};
 try{
  const baselineOrigin=clone(origin);baselineOrigin.p1[0].held_item_id='';const serialized=JSON.stringify(origin);
  const baseline=simulate(baselineOrigin,seed,o.baselineCommands??o.commands??[choices()],false);
  const actual=simulate(origin,seed,o.commands??[choices()],true);
  result.branch=c.verify(actual,baseline)??'deterministic';assert.equal(JSON.stringify(origin),serialized,'Input DTO unchanged');
  result.status='NATIVE_SCENARIO_PASS';
  rows.push({id:c.id,family:c.family,case_id:result.case_id,seed,origin,before:actual.before,steps:actual.steps,commands:actual.commands});
 }catch(error){result.error=error.stack;}
 results.push(result);
 if(results.length%100===0)console.log('ITEM_EFFECT_V3_PROGRESS',results.length);
}
const branchChecks=[];
for(const id of ['focus_band','quick_claw','kings_rock','razor_fang','lax_incense','zoom_lens','blunder_policy','micle_berry']){
 const r=results.filter(x=>x.id===id&&x.family!=='faster_no_boost');
 branchChecks.push({id,status:r.some(x=>x.branch==='activated')&&r.some(x=>x.branch==='not_activated')?'PASS':'FAIL',activated:r.filter(x=>x.branch==='activated').length,not_activated:r.filter(x=>x.branch==='not_activated').length});
}
fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({scope:'Bounded scenarios; RNG checks cover branches, not exact probabilities or all interactions',results,branchChecks},null,2));
fs.writeFileSync(path.join(OUT,'cases.json'),JSON.stringify(rows));
for(const r of results.filter(r=>r.status!=='NATIVE_SCENARIO_PASS').slice(0,28))console.log(r.case_id,r.error);
console.log('ITEM_EFFECT_NATIVE_V3',results.filter(r=>r.status==='NATIVE_SCENARIO_PASS').length,'PASS',results.filter(r=>r.status!=='NATIVE_SCENARIO_PASS').length,'FAIL; IDs',new Set(cases.map(c=>c.id)).size,'branches',branchChecks);
process.exitCode=results.some(r=>r.status!=='NATIVE_SCENARIO_PASS')||branchChecks.some(r=>r.status!=='PASS')?1:0;
