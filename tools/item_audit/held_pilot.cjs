'use strict';
// Positive, bounded experiments over actual native callbacks, not copied rules.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=path.join(ROOT,'.godot/item_audit_v1');
const proto=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const results=[],rows=[];
let trackedEngine=null,commands=[];
function mon(id,item='',moves=['tackle','protect'],species='mew'){
 const p=clone(proto[species]);p.instance_id=id;p.held_item_id=item;p.move_ids=moves;
 p.moveset=moves.map(move_id=>({move_id,current_pp:data.moves[move_id].pp,max_pp:data.moves[move_id].pp}));return p;
}
const own=cp=>cp.roster[0].pokemon.find(p=>p.instance_id==='actor');
const foe=cp=>cp.roster[1].pokemon.find(p=>p.instance_id==='foe');
function start(e,origin,seed){e.execute({op:'start',id:'a',format:'gen9calvounifiedv1',teams:origin,seed:[seed,2,3,4]});return e.execute({op:'checkpoint',id:'a'});}
function turn(e,a='move 1',b='move 1'){
	if(e===trackedEngine)commands.push({p1:a,p2:b});
 const before=e.execute({op:'checkpoint',id:'a'}),d=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{p1:a,p2:b}});
 assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,before.state_hash);
 return e.execute({op:'commit',id:'a',draft_token:d.draft_token});
}
function baseline(origin,seed,a='move 1',b='move 1'){
 const clear=clone(origin);clear.p1[0].held_item_id='';const e=new NativeEngine();
 try{start(e,clear,seed);return turn(e,a,b);}finally{e.close();}
}
const cases={
 leftovers:{moves:['protect'],hp:.5,run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,o.p1[0].current_hp+Math.floor(own(b).max_hp/16));return[a];}},
 black_sludge:{moves:['protect'],run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,own(b).hp-Math.floor(own(b).max_hp/8));return[a];}},
 sitrus_berry:{moves:['protect'],hp:.25,run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,o.p1[0].current_hp+Math.floor(own(b).max_hp/4));assert.equal(own(a).item,'');return[a];}},
 oran_berry:{moves:['protect'],hp:.25,run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,o.p1[0].current_hp+10);assert.equal(own(a).item,'');return[a];}},
 lum_berry:{moves:['protect'],status:'poison',run:(e)=>{const a=turn(e);assert.equal(own(a).status_id,'');assert.equal(own(a).item,'');return[a];}},
 life_orb:{run:(e,o,s,b)=>{const ref=baseline(o,s),a=turn(e);assert(foe(a).hp<foe(ref).hp);assert.equal(own(a).hp,own(b).hp-Math.floor(own(b).max_hp/10));return[a];}},
 choice_band:{run:(e,o,s)=>{const ref=baseline(o,s),a=turn(e);assert(foe(a).hp<foe(ref).hp);assert(a.views.p1.request.active[0].moves[1].disabled);return[a];}},
 assault_vest:{run:(e,o,s,b)=>{assert(b.views.p1.request.active[0].moves[1].disabled);assert.throws(()=>turn(e,'move 2'));assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,b.state_hash);return[turn(e)];}},
 focus_sash:{foe:['double_edge'],foeSpecies:'mew_100',run:(e)=>{const a=turn(e);assert.equal(own(a).hp,1);assert.equal(own(a).item,'');return[a];}},
 rocky_helmet:{foe:['tackle'],run:(e,o,s)=>{const ref=baseline(o,s),a=turn(e);assert.equal(foe(a).hp,foe(ref).hp-Math.floor(foe(ref).max_hp/6));return[a];}},
 air_balloon:{foe:['earthquake','tackle'],run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,own(b).hp);const c=turn(e,'move 1','move 2');assert(own(c).hp<own(b).hp);assert.equal(own(c).item,'');return[a,c];}},
 heavy_duty_boots:{foe:['stealth_rock'],run:(e,o,s,b)=>{const a=turn(e);assert(a.snapshot.native.sides[0].sideConditions.stealthrock);const c=turn(e,'switch 2');assert(c.roster[0].pokemon.find(p=>p.instance_id==='reserve').hp<o.p1[1].stats.max_hp);const session=e.sessions.get('a');const slot=session.battle.p1.pokemon.findIndex(p=>session.identities[p.name]==='actor')+1;const d=turn(e,'switch '+slot);assert.equal(own(d).hp,own(b).hp);return[a,c,d];}},
 white_herb:{moves:['shell_smash'],run:(e)=>{const a=turn(e);assert.equal(own(a).boosts.def,0);assert.equal(own(a).boosts.spd,0);assert.equal(own(a).boosts.atk,2);assert.equal(own(a).item,'');return[a];}},
 power_herb:{moves:['solar_beam'],run:(e,o,s,b)=>{const a=turn(e);assert(foe(a).hp<foe(b).hp);assert.equal(own(a).item,'');return[a];}},
 light_clay:{moves:['reflect'],run:(e,o,s)=>{const ref=baseline(o,s),a=turn(e);assert.equal(a.snapshot.native.sides[0].sideConditions.reflect.duration,ref.snapshot.native.sides[0].sideConditions.reflect.duration+3);return[a];}},
 expert_belt:{moves:['thunder_shock'],foeSpecies:'gyarados',run:(e,o,s)=>{const ref=baseline(o,s),a=turn(e);assert(foe(a).hp<foe(ref).hp);return[a];}},
 throat_spray:{moves:['round'],run:(e)=>{const a=turn(e);assert.equal(own(a).boosts.spa,1);assert.equal(own(a).item,'');return[a];}},
 eject_button:{foe:['tackle'],run:(e)=>{const a=turn(e);assert.equal(own(a).item,'');assert(a.views.p1.request.forceSwitch[0]);return[a];}},
 red_card:{foe:['tackle'],run:(e)=>{const a=turn(e);assert.equal(own(a).item,'');assert.equal(a.roster[1].active_id,'foe_reserve');return[a];}},
 mental_herb:{foe:['taunt'],foeSpecies:'mew_100',run:(e)=>{const a=turn(e);assert.equal(own(a).item,'');assert(!own(a).volatiles.includes('taunt'));return[a];}},
 figy_berry:{moves:['protect'],species:'mew_modest',hp:.2,run:(e,o,s,b)=>{const a=turn(e);assert.equal(own(a).hp,o.p1[0].current_hp+Math.floor(own(b).max_hp/3));assert.equal(own(a).item,'');assert(own(a).volatiles.includes('confusion'));return[a];}},
};
for(const [id,c] of Object.entries(cases))for(const seed of [1,19]){
 const origin={p1:[mon('actor',id,c.moves??['tackle','protect'],c.species??'mew'),mon('reserve')],p2:[mon('foe','',c.foe??['reflect'],c.foeSpecies??'mew'),mon('foe_reserve','',['reflect'])]};
 if(c.hp)origin.p1[0].current_hp=Math.floor(origin.p1[0].stats.max_hp*c.hp);
 if(c.status){origin.p1[0].status_state.persistent_id=c.status;origin.p1[0].status_ids=[c.status];}
 const e=new NativeEngine(),case_id=`${id}/${seed}`,result={id,seed,case_id,status:'FAIL'};
 try{
  trackedEngine=e;commands=[];
  const before=start(e,origin,seed),steps=c.run(e,origin,seed,before);
  const restore=new NativeEngine();try{restore.execute({op:'restore',id:'a',snapshot:steps.at(-1).snapshot});assert.equal(restore.execute({op:'checkpoint',id:'a'}).state_hash,steps.at(-1).state_hash);}finally{restore.close();}
  rows.push({id,seed,case_id,origin,before,steps,commands:commands.slice(-steps.length)});result.status='PASS';
 }catch(error){result.error=error.stack;result.log=e.sessions.get('a')?.battle.log.slice(-18);}finally{e.close();}results.push(result);
}
fs.writeFileSync(path.join(OUT,'held_native.json'),JSON.stringify({results},null,2));
fs.writeFileSync(path.join(OUT,'held_cases.json'),JSON.stringify(rows));
for(const r of results.filter(r=>r.status==='FAIL').slice(0,3))console.log(r.case_id,r.error,r.log);
console.log('HELD_PILOT_NATIVE',results.filter(r=>r.status==='PASS').length,'PASS /',results.filter(r=>r.status==='FAIL').length,'FAIL');
process.exitCode=results.some(r=>r.status==='FAIL')?1:0;
