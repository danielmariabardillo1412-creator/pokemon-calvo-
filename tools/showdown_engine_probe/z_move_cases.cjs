'use strict';
// Fixtures use the pinned simulator's crystal/species requirements. Canonical
// data and existing artwork are read only; missing forms remain explicit.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {Dex}=require(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim'));
const OUT=process.env.CALVO_AUDIT_OUT??path.join(ROOT,'.godot/showdown_z_checks');
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const policy=JSON.parse(fs.readFileSync(path.join(ROOT,'config/randomlock_content_v1.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const bases={Normal:['tackle','swift'],Fighting:['brick_break','aura_sphere'],Flying:['wing_attack','air_slash'],Poison:['poison_jab','sludge_bomb'],Ground:['earthquake','earth_power'],Rock:['rock_slide','ancient_power'],Bug:['x_scissor','bug_buzz'],Ghost:['shadow_claw','shadow_ball'],Steel:['iron_head','flash_cannon'],Fire:['fire_punch','flamethrower'],Water:['waterfall','surf'],Grass:['seed_bomb','energy_ball'],Electric:['thunder_punch','thunderbolt'],Psychic:['zen_headbutt','psychic'],Ice:['ice_punch','ice_beam'],Dragon:['dragon_claw','dragon_pulse'],Dark:['crunch','dark_pulse'],Fairy:['play_rough','moonblast']};
const maps={};for(const kind of ['moves','items','species'])maps[kind]=new Map(Object.keys(data[kind]).map(id=>[lookup(kind,id).id,id]));
maps.species.set('raichualola','raichu_alola');
function cases(){return policy.z_moves.ids.map(id=>{
 const m=lookup('moves',id),generic=/_(physical|special)$/.test(id);
 const item=Dex.items.all().find(i=>generic?i.zMove===true&&i.zMoveType===m.type:i.zMove===m.name);
 assert(item,`No crystal for ${id}`);
 const nativeSpecies=generic?'mew':(item.itemUser.find(n=>maps.species.has(Dex.species.get(n).id))??item.itemUser[0]);
 const species=maps.species.get(Dex.species.get(nativeSpecies).id)??Dex.species.get(nativeSpecies).id;
 const base=generic?bases[m.type][id.endsWith('_physical')?0:1]:maps.moves.get(Dex.moves.get(item.zMoveFrom).id);
 assert(data.moves[base]&&maps.items.has(item.id),id);
 return {id,base,item:maps.items.get(item.id),species,native_species:Dex.species.get(nativeSpecies).id,
  status:m.category==='Status'?'STATUS_Z_EXCLUDED':['10_000_000_volt_thunderbolt','light_that_burns_the_sky'].includes(id)?'USER_EXCLUDED':'PLAYABLE',category:m.category};
});}
const descriptors=cases();
fs.mkdirSync(OUT,{recursive:true});
fs.writeFileSync(path.join(OUT,'cases.json'),JSON.stringify(descriptors,null,2));
if(process.argv.includes('--catalog')){console.log('Z_CASES',descriptors.length);process.exit(0);}
const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
const results=[],rows=[];
function mon(id,d){
 const p=prototypes[d.id]?clone(prototypes[d.id]):{species_id:d.native_species,level:50,moves:[d.base,'protect','tackle'],held_item_id:d.item};
 p.instance_id=id;return p;
}
function compact(cp){return {snapshot:cp.snapshot,roster:cp.roster,views:cp.views};}
for(const d of descriptors.filter(d=>d.status==='PLAYABLE'))for(const format of (process.env.CALVO_AUDIT_FORMAT?[process.env.CALVO_AUDIT_FORMAT]:['gen9customgame','gen8customgame']))for(const seed of [1,19])for(const side of ['p1','p2']){
 const e=new NativeEngine(),other=side==='p1'?'p2':'p1',case_id=`${d.id}/${format}/${seed}/${side}`;
 const target=clone(prototypes.target);target.instance_id='target';
 const origin={[side]:[mon('actor',d)],[other]:[target]};
 const result={...d,case_id,format,seed,side,status:'FAIL'};
 try{
  e.execute({op:'start',id:'a',format,seed:[seed,2,3,4],teams:origin});
  const before=e.execute({op:'checkpoint',id:'a'});
  assert.equal(before.views[side].request.active[0].canZMove[0].move,lookup('moves',d.id).name);
  const draft=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:{[side]:'move 1 zmove',[other]:'move 1'}});
  const after=e.execute({op:'commit',id:'a',draft_token:draft.draft_token});
  const actor=after.roster.find(s=>s.id===side).pokemon[0],enemy=after.roster.find(s=>s.id===other).pokemon[0];
  const old=before.roster.find(s=>s.id===side).pokemon[0],oldEnemy=before.roster.find(s=>s.id===other).pokemon[0];
  assert(enemy.hp<oldEnemy.hp,'Z action caused no damage');assert.equal(actor.moves[0].pp,old.moves[0].pp-1);
  assert.equal(actor.item,lookup('items',d.item).id,'Crystal was consumed');
  assert(after.snapshot.native.log.some(l=>l===`|-zpower|${side}a: calvo_${side}_0`));
  assert.equal(after.views[side].request.active[0].canZMove,undefined,'Z can be offered twice');
  if(d.id==='guardian_of_alola')assert.equal(oldEnemy.hp-enemy.hp,Math.floor(oldEnemy.hp*3/4));
  if(d.id==='genesis_supernova')assert.equal(after.snapshot.native.field.terrain,'psychicterrain');
  if(d.id==='clangorous_soulblaze')for(const s of ['atk','def','spa','spd','spe'])assert.equal(actor.boosts[s],1);
  const restored=new NativeEngine();
  try{restored.execute({op:'restore',id:'b',snapshot:after.snapshot});assert.equal(restored.execute({op:'checkpoint',id:'b'}).state_hash,after.state_hash);}finally{restored.close();}
  assert.throws(()=>e.execute({op:'prepare',id:'a',expected_hash:after.state_hash,choices:{[side]:'move 1 zmove',[other]:'move 1'}}));
  assert.equal(e.execute({op:'checkpoint',id:'a'}).state_hash,after.state_hash,'Rejected reuse changed state');
  const continuation=e.execute({op:'prepare',id:'a',expected_hash:after.state_hash,choices:{[side]:'move 3',[other]:'move 1'}});
  e.execute({op:'commit',id:'a',draft_token:continuation.draft_token});
  rows.push({...d,case_id,format,side,origin,before:compact(before),after:compact(after)});
  result.status='NATIVE_Z_VERIFIED';result.damage=oldEnemy.hp-enemy.hp;
 }catch(error){result.error=error.stack;result.log=e.sessions.get('a')?.battle.log.slice(-12);}
 finally{e.close();}results.push(result);
}
const manifest={batches:[]};for(let i=0;i<rows.length;i+=32){const name=`batch_${i/32}.json`;manifest.batches.push(name);fs.writeFileSync(path.join(OUT,name),JSON.stringify(rows.slice(i,i+32)));}
fs.writeFileSync(path.join(OUT,'manifest.json'),JSON.stringify(manifest));
fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({results,descriptors},null,2));
const failures=results.filter(r=>r.status==='FAIL');console.log('Z_NATIVE',results.length,'cases',failures.length,'failures');
for(const r of failures.slice(0,3))console.log(r.case_id,r.error,r.log);process.exitCode=failures.length?1:0;
