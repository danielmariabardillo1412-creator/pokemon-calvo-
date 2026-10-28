'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {SINGLE,DOUBLE}=require('../../modules/battle/backends/showdown/unified_profile.cjs');
const OUT=path.join(ROOT,'.godot/unified_profile_checks');
const proto=JSON.parse(fs.readFileSync(path.join(ROOT,'.godot/move_functional_audit/prototypes.json'),'utf8'));
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const clone=x=>JSON.parse(JSON.stringify(x));
const results=[];
function mon(id,moves=['tackle','protect'],item=''){
 const p=clone(proto.mew);p.instance_id=id;p.move_ids=moves;p.moveset=moves.map(id=>({move_id:id,current_pp:data.moves[id].pp,max_pp:data.moves[id].pp}));
 p.ability_id='';p.held_item_id=item;return p;
}
const teams=()=>({p1:[mon('actor'),mon('z_actor',['tackle'],'normalium_z_held')],p2:[mon('target',['reflect']),mon('reserve',['reflect'])]});
function check(id,fn){try{fn();results.push({id,status:'PASS'});}catch(e){results.push({id,status:'FAIL',error:e.stack});console.log(id,e.stack);}}
function withEngine(fn){const e=new NativeEngine();try{fn(e);}finally{e.close();}}
const checkpoint=e=>e.execute({op:'checkpoint',id:'a'});
const start=(e,format=SINGLE,origin=teams())=>{e.execute({op:'start',id:'a',format,teams:origin,seed:[1,2,3,4]});return checkpoint(e);};
const turn=(e,p1,p2='move 1')=>{const old=checkpoint(e);const draft=e.execute({op:'prepare',id:'a',expected_hash:old.state_hash,choices:{p1,p2}});assert.equal(checkpoint(e).state_hash,old.state_hash);return e.execute({op:'commit',id:'a',draft_token:draft.draft_token});};
check('Gen9 baseline stays without Dynamax',()=>withEngine(e=>{
 const before=start(e,'gen9customgame');assert(!before.views.p1.request.active[0].canDynamax);
 assert.throws(()=>turn(e,'move 1 dynamax'));assert.equal(checkpoint(e).state_hash,before.state_hash);
}));
check('Gen8 baseline still offers Dynamax',()=>withEngine(e=>{assert(start(e,'gen8customgame').views.p1.request.active[0].canDynamax);}));
check('Gen9 combined profile exposes native Max and remains generation 9',()=>withEngine(e=>{
 const c=start(e);assert(c.views.p1.request.active[0].canDynamax);assert.equal(e.sessions.get('a').battle.gen,9);
 assert.equal(c.snapshot.native.formatid,SINGLE);assert.equal(c.roster[0].pokemon[0].max_hp,teams().p1[0].stats.max_hp);
}));
check('ordinary action equals unchanged Gen9 HP, PP, stages and conditions',()=>{
 const a=new NativeEngine(),b=new NativeEngine();try{
  start(a);start(b,'gen9customgame');const x=turn(a,'move 1'),y=turn(b,'move 1');
  assert.deepEqual(x.roster,y.roster);assert.deepEqual(x.snapshot.native.field,y.snapshot.native.field);
 }finally{a.close();b.close();}
});
check('Max uses real base PP and lasts three turns; checkpoint replay is exact',()=>withEngine(e=>{
 const before=start(e);const after=turn(e,'move 1 dynamax');
 assert.equal(after.roster[0].pokemon[0].max_hp,before.roster[0].pokemon[0].max_hp*2);
 assert.equal(after.roster[0].pokemon[0].moves[0].pp,before.roster[0].pokemon[0].moves[0].pp-1);
 assert(after.snapshot.native.log.some(x=>x.startsWith('|move|p1a:')&&x.includes('|Max Strike|')));
 const r=new NativeEngine();try{
  r.execute({op:'restore',id:'a',snapshot:after.snapshot});assert.equal(checkpoint(r).state_hash,after.state_hash);
  const next=turn(e,'move 2');assert.equal(turn(r,'move 2').state_hash,next.state_hash);
 }finally{r.close();}
 const ended=turn(e,'move 2');assert(!ended.roster[0].pokemon[0].volatiles.includes('dynamax'));
 assert.equal(ended.roster[0].pokemon[0].max_hp,before.roster[0].pokemon[0].max_hp);
 assert(!ended.views.p1.request.active[0].canDynamax);
 turn(e,'switch 2');const z=turn(e,'move 1 zmove');
 assert(z.snapshot.native.log.includes('|-zpower|p1a: calvo_p1_1'));
 assert.equal(z.roster[0].pokemon.find(p=>p.instance_id==='z_actor').item,lookup('items','normalium_z_held').id);
}));
check('invalid command cannot spend Max allowance',()=>withEngine(e=>{
 const saved=start(e);assert.throws(()=>turn(e,'move 99 dynamax'));assert.equal(checkpoint(e).state_hash,saved.state_hash);
 assert(turn(e,'move 1 dynamax').roster[0].pokemon[0].volatiles.includes('dynamax'));
}));
check('new generation move can generate Max without losing its original slot',()=>withEngine(e=>{
 const origin=teams();origin.p1[0]=mon('actor',['make_it_rain','protect']);
 const c=start(e,SINGLE,origin);const after=turn(e,'move 1 dynamax');
 assert(after.snapshot.native.log.some(x=>x.startsWith('|move|p1a:')&&x.includes('|Max Steelspike|')));
 assert.equal(after.roster[0].pokemon[0].base_moves[0].id,'makeitrain');
 assert.equal(after.roster[0].pokemon[0].base_moves[0].pp,c.roster[0].pokemon[0].base_moves[0].pp-1);
 assert.equal(after.roster[0].pokemon[0].boosts.def,1);
}));
check('both teams have independent native allowance',()=>withEngine(e=>{
 const origin=teams();origin.p2[0]=mon('target');start(e,SINGLE,origin);
 const c=turn(e,'move 1 dynamax','move 1 dynamax');
 for(const s of c.roster)assert(s.pokemon[0].volatiles.includes('dynamax'));
}));
check('combined doubles can start and restore two slots with Max availability',()=>withEngine(e=>{
 const c=start(e,DOUBLE);assert.equal(c.roster[0].active_ids.length,2);assert(c.views.p1.request.active[0].canDynamax);
 const r=new NativeEngine();try{r.execute({op:'restore',id:'a',snapshot:c.snapshot});assert.equal(checkpoint(r).state_hash,c.state_hash);}finally{r.close();}
}));
fs.writeFileSync(path.join(OUT,'contracts.json'),JSON.stringify({status:results.every(r=>r.status==='PASS')?'PASS':'FAIL',results},null,2));
console.log('UNIFIED_CONTRACTS',results.every(r=>r.status==='PASS')?'PASS':'FAIL',results.length);process.exitCode=results.some(r=>r.status==='FAIL')?1:0;
