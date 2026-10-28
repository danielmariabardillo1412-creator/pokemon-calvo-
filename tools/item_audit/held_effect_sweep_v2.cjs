'use strict';
// Bounded causal/metamorphic scenarios; fixture expectations are explicit, not copied callbacks.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=path.join(ROOT,'.godot/item_verification_v2');
const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const attack={normal:'tackle',fire:'flamethrower',water:'surf',electric:'thunderbolt',grass:'energy_ball',ice:'ice_beam',fighting:'brick_break',poison:'sludge_bomb',ground:'earth_power',flying:'aerial_ace',psychic:'psychic',bug:'bug_buzz',rock:'smack_down',ghost:'shadow_ball',dragon:'dragon_pulse',dark:'dark_pulse',steel:'flash_cannon',fairy:'dazzling_gleam'};
const booster={normal:'silk_scarf',fire:'charcoal',water:'mystic_water',electric:'magnet',grass:'miracle_seed',ice:'never_melt_ice',fighting:'black_belt',poison:'poison_barb',ground:'soft_sand',flying:'sharp_beak',psychic:'twisted_spoon',bug:'silver_powder',rock:'hard_stone',ghost:'spell_tag',dragon:'dragon_fang',dark:'black_glasses',steel:'metal_coat',fairy:'fairy_feather'};
const plates={fire:'flame_plate',water:'splash_plate',electric:'zap_plate',grass:'meadow_plate',ice:'icicle_plate',fighting:'fist_plate',poison:'toxic_plate',ground:'earth_plate',flying:'sky_plate',psychic:'mind_plate',bug:'insect_plate',rock:'stone_plate',ghost:'spooky_plate',dragon:'draco_plate',dark:'dread_plate',steel:'iron_plate',fairy:'pixie_plate'};
const resist={normal:['chilan_berry','mew'],fire:['occa_berry','scizor'],water:['passho_berry','charizard'],electric:['wacan_berry','gyarados'],grass:['rindo_berry','blastoise'],ice:['yache_berry','dragonite'],fighting:['chople_berry','snorlax'],poison:['kebia_berry','clefable'],ground:['shuca_berry','pikachu'],flying:['coba_berry','venusaur'],psychic:['payapa_berry','gengar'],bug:['tanga_berry','mew'],rock:['charti_berry','charizard'],ghost:['kasib_berry','mew'],dragon:['haban_berry','dragonite'],dark:['colbur_berry','mew'],steel:['babiri_berry','clefable'],fairy:['roseli_berry','garchomp']};
function mon(id,species='mew',moves=['reflect'],item=''){
 const p=clone(prototypes[species]);p.instance_id=id;p.held_item_id=item;p.held_item_consumed=false;p.move_ids=moves;
 p.moveset=moves.map(move_id=>({move_id,current_pp:data.moves[move_id].pp,max_pp:data.moves[move_id].pp}));return p;
}
const own=cp=>cp.roster[0].pokemon.find(p=>p.instance_id==='actor');
const foe=cp=>cp.roster[1].pokemon.find(p=>p.instance_id==='foe');
const cases=[];
function add(id,family,options,verify){
 assert(data.items[id],`Canonical item ${id}`);assert(lookup('items',id).exists,`Native item ${id}`);
 cases.push({id,family,options,verify});
}
for(const [family,table] of [['type_boost',booster],['plate_boost',plates]])for(const [type,id] of Object.entries(table)){
 add(id,family,{moves:[attack[type]]},(a,b)=>assert(foe(a).hp<foe(b).hp,'Matching-type damage must increase'));
 add(id,family+'_nonmatching',{moves:[attack[type==='normal'?'water':'normal']]},(a,b)=>{assert.equal(foe(a).hp,foe(b).hp);assert(own(a).item);});
}
for(const type of Object.keys(attack)){
 add(type+'_gem','gem_consumption',{moves:[attack[type]]},(a,b)=>{assert(foe(a).hp<foe(b).hp);assert.equal(own(a).item,'');});
 add(type+'_gem','gem_nonmatching',{moves:[attack[type==='normal'?'water':'normal']]},(a,b)=>{assert.equal(foe(a).hp,foe(b).hp);assert(own(a).item);});
}
for(const [type,[id,species]] of Object.entries(resist)){
 add(id,'resist_berry',{species,moves:['swords_dance'],foeMoves:[attack[type]]},(a,b)=>{assert(own(a).hp>own(b).hp,'Resistance must reduce incoming matching damage');assert.equal(own(a).item,'');});
 add(id,'resist_nonmatching',{species,moves:['swords_dance'],foeMoves:[attack[type==='normal'?'water':'normal']]},(a,b)=>{assert.equal(own(a).hp,own(b).hp);assert(own(a).item);});
}
for(const [id,stat] of Object.entries({liechi_berry:'atk',ganlon_berry:'def',petaya_berry:'spa',apicot_berry:'spd',salac_berry:'spe'})){
 add(id,'pinch_stat_berry',{hp:.2,moves:['protect']},a=>{assert.equal(own(a).boosts[stat],1);assert.equal(own(a).item,'');});
 add(id,'pinch_not_triggered',{moves:['protect']},a=>{assert.equal(own(a).boosts[stat],0);assert(own(a).item);});
}
for(const [id,status] of Object.entries({cheri_berry:'paralysis',chesto_berry:'sleep',pecha_berry:'poison',rawst_berry:'burn',aspear_berry:'freeze'})){
 const opt=status==='sleep'?{foeSpecies:'gengar',foeMoves:['spore']}:{status,moves:['reflect']};
 add(id,'status_berry',opt,a=>{assert.equal(own(a).status_id,'');assert.equal(own(a).item,'');});
 add(id,'status_not_triggered',{moves:['reflect']},a=>assert(own(a).item));
}
add('persim_berry','confusion_berry',{foeSpecies:'gengar',foeMoves:['confuse_ray']},a=>{assert(!own(a).volatiles.includes('confusion'));assert.equal(own(a).item,'');});
add('kee_berry','reactive_stat_berry',{foeMoves:['tackle']},a=>{assert.equal(own(a).boosts.def,1);assert.equal(own(a).item,'');});
add('maranga_berry','reactive_stat_berry',{foeMoves:['confusion']},a=>{assert.equal(own(a).boosts.spd,1);assert.equal(own(a).item,'');});
for(const [id,move] of [['muscle_band','tackle'],['wise_glasses','confusion'],['choice_specs','confusion']])add(id,'category_boost',{moves:[move,'protect']},(a,b)=>{assert(foe(a).hp<foe(b).hp);if(id==='choice_specs')assert(a.views.p1.request.active[0].moves[1].disabled);});
add('choice_scarf','speed_order',{moves:['tackle'],foeSpecies:'gengar',foeMoves:['tackle']},(a,b,raw)=>{const first=x=>x.find(l=>l.startsWith('|move|'));assert(first(raw.actual).startsWith('|move|p1a:'));assert(first(raw.baseline).startsWith('|move|p2a:'));});
add('weakness_policy','super_effective_boost',{species:'gyarados',foeMoves:['thunder_shock']},a=>{assert.equal(own(a).boosts.atk,2);assert.equal(own(a).boosts.spa,2);assert.equal(own(a).item,'');});
for(const [id,move,stat] of [['cell_battery','thunder_shock','atk'],['absorb_bulb','water_gun','spa'],['snowball','powder_snow','atk'],['luminous_moss','water_gun','spd']])add(id,'hit_type_stat_boost',{foeMoves:[move]},a=>{assert.equal(own(a).boosts[stat],1);assert.equal(own(a).item,'');});
add('protective_pads','contact_protection',{moves:['tackle'],foeItem:'rocky_helmet'},(a,b)=>assert(own(a).hp>own(b).hp));
add('punching_glove','punch_boost_and_contact',{moves:['thunder_punch'],foeItem:'rocky_helmet'},(a,b)=>{assert(foe(a).hp<foe(b).hp);assert(own(a).hp>own(b).hp);});
add('safety_goggles','powder_protection',{foeSpecies:'gengar',foeMoves:['spore']},(a,b)=>{assert.equal(own(a).status_id,'');assert.equal(own(b).status_id,'sleep');});
add('covert_cloak','secondary_protection',{foeMoves:['nuzzle']},(a,b)=>{assert.equal(own(a).status_id,'');assert.equal(own(b).status_id,'paralysis');});
add('clear_amulet','opponent_drop_protection',{foeMoves:['charm']},(a,b)=>{assert.equal(own(a).boosts.atk,0);assert(own(b).boosts.atk<0);});
add('shell_bell','damage_recovery',{hp:.5,moves:['tackle']},(a,b,raw)=>{const damage=raw.beforeFoeHP-foe(a).hp;assert.equal(own(a).hp,raw.beforeHP+Math.max(1,Math.floor(damage/8)));});
add('big_root','drain_recovery',{hp:.5,moves:['absorb']},(a,b)=>assert(own(a).hp>own(b).hp));
add('flame_orb','end_turn_status',{},a=>assert.equal(own(a).status_id,'burn'));
add('toxic_orb','end_turn_status',{},a=>assert.equal(own(a).status_id,'badly_poisoned'));
add('loaded_dice','multi_hit_bound',{moves:['bullet_seed']},(a,b,raw)=>{const line=raw.actual.find(l=>l.startsWith('|-hitcount|'));assert(line);assert([4,5].includes(Number(line.split('|').at(-1))));});

function simulate(origin,seed,tracked){
 const engine=new NativeEngine();
 try{
  engine.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:origin,seed:[seed,2,3,4]});
  const before=engine.execute({op:'checkpoint',id:'a'});
  const choices={p1:'move 1',p2:'move 1'};
  const draft=engine.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices});
  assert.equal(engine.execute({op:'checkpoint',id:'a'}).state_hash,before.state_hash,'Prepare cannot publish');
  const after=engine.execute({op:'commit',id:'a',draft_token:draft.draft_token});
  if(tracked){
   const restored=new NativeEngine();try{restored.execute({op:'restore',id:'a',snapshot:after.snapshot});assert.equal(restored.execute({op:'checkpoint',id:'a'}).state_hash,after.state_hash);}finally{restored.close();}
  }
  return {before,after,log:engine.sessions.get('a').battle.log.slice(),commands:[choices]};
 }finally{engine.close();}
}
const results=[],rows=[];
for(const c of cases)for(const seed of [1,19]){
 const opt=c.options;
 const origin={p1:[mon('actor',opt.species??'mew',opt.moves??['reflect'],c.id)],p2:[mon('foe',opt.foeSpecies??'mew',opt.foeMoves??['reflect'],opt.foeItem??'')]};
 if(opt.hp)origin.p1[0].current_hp=Math.floor(origin.p1[0].stats.max_hp*opt.hp);
 if(opt.status){origin.p1[0].status_state.persistent_id=opt.status;origin.p1[0].status_ids=[opt.status];}
 const result={id:c.id,family:c.family,seed,case_id:c.id+'/'+c.family+'/'+seed,status:'FAIL_NATIVE_OR_FIXTURE'};
 try{
  const clear=clone(origin);clear.p1[0].held_item_id='';
  const baseline=simulate(clear,seed,false),actual=simulate(origin,seed,true);
  c.verify(actual.after,baseline.after,{actual:actual.log,baseline:baseline.log,beforeHP:origin.p1[0].current_hp,beforeFoeHP:origin.p2[0].current_hp});
  result.status='NATIVE_SCENARIO_PASS';
  rows.push({id:c.id,family:c.family,case_id:result.case_id,seed,origin,before:actual.before,steps:[actual.after],commands:actual.commands});
 }catch(error){result.error=error.stack;}
 results.push(result);
 if(results.length%40===0)console.log('ITEM_EFFECT_SWEEP_V2',results.length,'/',cases.length*2);
}
fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({scope:'Bounded item scenarios, not all interactions or content eligibility',results},null,2));
fs.writeFileSync(path.join(OUT,'cases.json'),JSON.stringify(rows));
for(const failed of results.filter(r=>r.status!=='NATIVE_SCENARIO_PASS').slice(0,8))console.log(failed.case_id,failed.error);
console.log('ITEM_EFFECT_NATIVE_V2',results.filter(r=>r.status==='NATIVE_SCENARIO_PASS').length,'PASS /',results.filter(r=>r.status!=='NATIVE_SCENARIO_PASS').length,'FAIL; IDs',new Set(cases.map(c=>c.id)).size);
process.exitCode=results.some(r=>r.status!=='NATIVE_SCENARIO_PASS')?1:0;
