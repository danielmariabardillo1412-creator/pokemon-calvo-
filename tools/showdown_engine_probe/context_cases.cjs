'use strict';
// Explicit synthetic prerequisites, never fake a success or replace a move's
// callbacks. All effects/choices after the checkpoint run in the native engine.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {Battle,Dex}=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim'));
const OUT=process.env.CALVO_AUDIT_OUT??path.join(ROOT,'.godot/showdown_context_checks');
const FORMAT=process.env.CALVO_AUDIT_FORMAT??'gen9customgame';
const excluded=new Set(JSON.parse(fs.readFileSync(path.join(ROOT,'config/randomlock_content_v1.json'),'utf8')).move_exclusions.flatMap(g=>g.ids));
const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const doubles=['after_you','ally_switch','aromatic_mist','coaching','dragon_cheer','follow_me','helping_hand','hold_hands','quash','rage_powder','spotlight'];
const compact=c=>({roster:c.roster,views:{p1:{ended:c.views.p1.ended,winner:c.views.p1.winner,request:c.views.p1.request},p2:{ended:c.views.p2.ended,winner:c.views.p2.winner,request:c.views.p2.request}},snapshot:{identities:c.snapshot.identities,native:{turn:c.snapshot.native.turn,log:c.snapshot.native.log,field:c.snapshot.native.field}}});
function mon(id,moves,species='mew'){
 const p=clone(prototypes[species]);p.instance_id=id;p.move_ids=moves;
 p.moveset=moves.map(id=>({move_id:id,current_pp:data.moves[id].pp,max_pp:data.moves[id].pp}));return p;
}
const cases={
 attract:{species:'pikachu',targetSpecies:'pikachu',setup:(b,a,t)=>{a.gender='M';t.gender='F';}},
 captivate:{species:'pikachu',targetSpecies:'pikachu',setup:(b,a,t)=>{a.gender='M';t.gender='F';}},
 aura_wheel:{species:'morpeko'},
 aurora_veil:{setup:(b,a)=>b.field.setWeather('snowscape',a)},
 belch:{setup:(b,a)=>{a.ateBerry=true;}},
 bestow:{item:'hard_stone'},
 burn_up:{species:'charizard'},
 dark_void:{species:'darkrai',setup:(b,a)=>{a.boosts.accuracy=6;}}, // Legitimate accuracy stage makes effect tests deterministic.
 doodle:{targetAbility:'static'},
 double_shock:{species:'pikachu'},
 dream_eater:{setup:(b,a,t)=>t.setStatus('slp')},
 entrainment:{ability:'static'},
 flower_shield:{setup:(b,a,t)=>{a.setType('Grass');t.setType('Grass');}},
 gear_up:{ability:'plus'},
 hyperspace_fury:{species:'hoopa',setup:(b,a)=>a.formeChange('Hoopa-Unbound')},
 last_resort:{moves:['last_resort','tackle'],setup:(b,a)=>{a.moveSlots[1].used=true;}},
 magic_powder:{setup:(b,a,t)=>t.setType('Water')},
 magnetic_flux:{ability:'minus'},
 mirror_coat:{opponent:'psychic'},
 natural_gift:{item:'oran_berry'},
 nightmare:{setup:(b,a,t)=>t.setStatus('slp')},
 purify:{setup:(b,a,t)=>t.setStatus('psn')},
 recycle:{setup:(b,a)=>{a.lastItem='oranberry';}},
 revival_blessing:{setup:b=>{b.p1.pokemon[1].hp=0;b.p1.pokemon[1].fainted=true;b.p1.pokemonLeft=1;}},
 role_play:{targetAbility:'static'},
 rototiller:{setup:(b,a,t)=>{a.setType('Grass');t.setType('Grass');}},
 sketch:{moves:['sketch','protect'],opponent:'tackle',setup:b=>b.makeChoices('move 2','move 1')},
 sleep_talk:{moves:['sleep_talk','tackle'],setup:(b,a)=>a.setStatus('slp')},
 snore:{setup:(b,a)=>a.setStatus('slp')},
 spit_up:{setup:(b,a)=>{a.addVolatile('stockpile');a.volatiles.stockpile.layers=2;}},
 steel_roller:{setup:(b,a)=>b.field.setTerrain('electricterrain',a)},
 stuff_cheeks:{item:'oran_berry'},
 swallow:{hp:20,setup:(b,a)=>{a.addVolatile('stockpile');a.volatiles.stockpile.layers=2;}},
 teatime:{item:'oran_berry'},
 topsy_turvy:{setup:(b,a,t)=>{t.boosts.atk=2;t.boosts.def=-1;}},
 upper_hand:{opponent:'quick_attack'},
 venom_drench:{setup:(b,a,t)=>t.setStatus('psn')},
};
function pick(b,id){const s=b[id],r=s.activeRequest;if(!r||r.wait||s.isChoiceDone())return null;if(r.forceSwitch?.[0]){const reviving=s.pokemon.some(p=>p.getSwitchRequestData().reviving);const index=s.pokemon.findIndex(p=>reviving?p.fainted:!p.fainted&&!p.isActive);return `switch ${index+1}`;}return 'move 1';}
const rows=[],results=[],positiveDoubles=[];
for(const [id,c] of Object.entries(cases))for(const seed of [1,19]){
 if(excluded.has(id))continue;
 const e=new NativeEngine(),case_id=`${id}/targeted/${seed}`;
 const own=mon('actor',c.moves??[id],c.species??'mew'),target=mon('target',[c.opponent??'reflect'],c.targetSpecies??'mew');
 if(c.item)own.held_item_id=c.item;if(c.ability)own.ability_id=c.ability;if(c.targetAbility)target.ability_id=c.targetAbility;if(c.hp)own.current_hp=c.hp;
 const origin={p1:[own,mon('own_reserve',['tackle'])],p2:[target,mon('enemy_reserve',['tackle'])]};
 const result={id,case_id,seed,status:'NATIVE_CONTEXT_VERIFIED',expectation:'Declared move executes with prerequisites; no fail/immune marker during its action.',prerequisites:Object.keys(c)};
 try{
  e.execute({op:'start',id:'a',format:FORMAT,seed:[seed,2,3,4],teams:origin});
  let b=e.sessions.get('a').battle;c.setup?.(b,b.p1.active[0],b.p2.active[0]);
  const before=e.execute({op:'checkpoint',id:'a'}),row={id,case_id,seed,scenario:'targeted',format:FORMAT,origin,before:compact(before),steps:[]};
  let cp=before;
  for(let step=0;step<2&&!b.ended;step++){
   const choices=Object.fromEntries(['p1','p2'].map(s=>[s,pick(b,s)]).filter(([,c])=>c));
   const draft=e.execute({op:'prepare',id:'a',expected_hash:cp.state_hash,choices});
   cp=e.execute({op:'commit',id:'a',draft_token:draft.draft_token});row.steps.push(compact(cp));b=e.sessions.get('a').battle;
  }
  const log=cp.snapshot.native.log.slice(before.snapshot.native.log.length);
  let ownAction=false,success=false,failed=false;
  for(const line of log){
   if(line.startsWith('|move|')){if(ownAction&&!failed)success=true;const f=line.split('|');ownAction=f[2].endsWith(': calvo_p1_0')&&f[3].replace(/[^a-z0-9]/gi,'').toLowerCase()===lookup('moves',id).id;failed=false;}
   else if(ownAction&&/^\|-(fail|immune|miss)\|/.test(line))failed=true;
  }
  if(ownAction&&!failed)success=true;
  assert(success,'Specific context did not produce a successful declared action');
  if(id==='revival_blessing')assert(cp.roster[0].pokemon.find(p=>p.instance_id==='own_reserve').hp>0,'Reserve was not revived');
  if(id==='topsy_turvy'){assert.equal(row.steps[0].roster[1].pokemon[0].boosts.atk,-2);assert.equal(row.steps[0].roster[1].pokemon[0].boosts.def,1);}
  rows.push(row);
 }catch(error){result.status='CONTEXT_FAILURE';result.error=error.message;result.stack=error.stack;const b=e.sessions.get('a')?.battle;result.log=b?.log.slice(-18);}
 finally{e.close();}results.push(result);
}
for(const id of doubles){
 const p=(name,move)=>({name,species:'Mew',ability:'No Ability',moves:[lookup('moves',move).name],level:50});
 let b;
 const result={id,status:'NATIVE_DOUBLES_CONTEXT_VERIFIED',game_profile:'RAW_REFERENCE_ONLY',note:'Production native/Godot doubles coverage is recorded separately by doubles_cases.cjs.'};
 try{
  b=new Battle({format:Dex.formats.get('gen9doublescustomgame'),seed:[1,2,3,4],p1:{name:'p1',team:[p('actor',id),p('ally','reflect')]},p2:{name:'p2',team:[p('foe','reflect'),p('foe2','reflect')]}});
  if(b.requestState==='teampreview')b.makeChoices('team 1,2','team 1,2');
  b.p1.active[0].storedStats.spe=200;b.p1.active[1].storedStats.spe=50;
  const first=b.log.length;
  const allyTarget=['after_you','aromatic_mist','coaching','dragon_cheer','helping_hand','hold_hands'].includes(id);
  const target=allyTarget?' -2':id==='quash'||id==='spotlight'?' 1':'';
  b.makeChoices(`move 1${target}, move 1`,'move 1, move 1');
  const delta=b.log.slice(first);assert(!delta.some(l=>l.startsWith('|error|')),'Invalid doubles fixture');
  assert(delta.some(l=>l.startsWith('|move|p1a: actor|')),'Doubles move not executed');
  assert(!delta.some(l=>l.startsWith('|-fail|p1a: actor')),'Doubles prerequisite still missing');
 }catch(error){result.status='DOUBLES_CONTEXT_FAILURE';result.error=error.message;}finally{b?.destroy();}
 positiveDoubles.push(result);
}
const file='batch_contexts.json';fs.writeFileSync(path.join(OUT,file),JSON.stringify(rows));
fs.writeFileSync(path.join(OUT,'manifest.json'),JSON.stringify({batches:[file],cases:rows.length}));
fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({results,doubles:positiveDoubles},null,2));
console.log('MOVE_CONTEXTS',JSON.stringify({cases:results.length,failures:results.filter(r=>r.status==='CONTEXT_FAILURE'),doubles:positiveDoubles}));
