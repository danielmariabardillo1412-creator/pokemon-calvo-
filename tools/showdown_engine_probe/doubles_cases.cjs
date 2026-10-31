'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {NativeEngine,ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=process.env.CALVO_AUDIT_OUT??path.join(ROOT,'.godot/native_doubles_checks');
const FORMAT=process.env.CALVO_DOUBLES_FORMAT??'gen9doublescustomgame';
const IDS=['after_you','ally_switch','aromatic_mist','coaching','dragon_cheer','follow_me','helping_hand','hold_hands','quash','rage_powder','spotlight'];
const clone=x=>JSON.parse(JSON.stringify(x));
function choices(id,side){
 const other=side==='p1'?'p2':'p1';
 const ally=['after_you','aromatic_mist','coaching','dragon_cheer','helping_hand','hold_hands'].includes(id);
 const aimed=id==='quash'?' 1':id==='spotlight'?' 2':ally?' -2':'';
 const attack=['follow_me','rage_powder'].includes(id);
 return {[side]:`move 1${aimed}, move 1 1`,[other]:attack?'move 2 2, move 2 2':'move 1, move 1'};
}
function verify(id,before,after,side){
 const idx=side==='p1'?0:1,own=after.roster[idx],foes=after.roster[1-idx];
 const a=own.pokemon.find(p=>p.instance_id==='actor'),ally=own.pokemon.find(p=>p.instance_id==='ally');
 const old=before.roster[idx].pokemon.find(p=>p.instance_id==='actor');
 const log=after.snapshot.native.log.slice(before.snapshot.native.log.length);
 assert.equal(a.moves[0].pp,old.moves[0].pp-1);
 assert(log.some(l=>l.startsWith('|move|')&&l.split('|')[2].endsWith(`: calvo_${side}_0`)&&l.split('|')[3]===lookup('moves',id).name));
 assert(!log.some(l=>l.startsWith(`|-fail|${side}`)),'Native action failed');
 if(id==='ally_switch')assert.deepEqual(own.active_ids,['ally','actor']);
 if(id==='aromatic_mist'){assert.equal(ally.boosts.spd,1);assert.equal(a.boosts.spd,0);}
 if(id==='coaching'){assert.equal(ally.boosts.atk,1);assert.equal(ally.boosts.def,1);assert.equal(a.boosts.atk,0);}
 if(id==='dragon_cheer'){
  const p=after.snapshot.native.sides[idx].pokemon.find(p=>p.set.name===`calvo_${side}_1`);
  assert.equal(p.volatiles.dragoncheer.hasDragonType,true);
 }
 const order=log.filter(l=>l.startsWith('|move|')).map(l=>l.split('|')[2].split(': ')[1]);
 if(id==='after_you')assert.equal(order[1],`calvo_${side}_1`);
 if(id==='quash')assert.equal(order.at(-1),`calvo_${side==='p1'?'p2':'p1'}_0`);
 if(['follow_me','rage_powder'].includes(id)){assert(a.hp<old.hp);assert.equal(ally.hp,ally.max_hp);}
 if(id==='spotlight'){
  assert.equal(foes.pokemon[0].hp,foes.pokemon[0].max_hp);assert(foes.pokemon[1].hp<foes.pokemon[1].max_hp);
 }
 if(id==='hold_hands'){assert.equal(a.hp,a.max_hp);assert.deepEqual(ally.boosts,{atk:0,def:0,spa:0,spd:0,spe:0,accuracy:0,evasion:0});}
 return log;
}
if(require.main===module){
 const prototypes=JSON.parse(fs.readFileSync(path.join(OUT,'prototypes.json'),'utf8'));
 const results=[],rows=[];
 for(const id of IDS)for(const side of ['p1','p2'])for(const seed of [1,19]){
  const other=side==='p1'?'p2':'p1',origin={[side]:[clone(prototypes[id]),clone(prototypes.ally)],[other]:[clone(prototypes.foe0),clone(prototypes.foe1)]};
  const e=new NativeEngine(),case_id=`${id}/${side}/${seed}`;const result={id,side,seed,case_id,status:'FAIL'};
  try{
   e.execute({op:'start',id:'a',format:FORMAT,teams:origin,seed:[seed,2,3,4]});
   const before=e.execute({op:'checkpoint',id:'a'}),cmd=choices(id,side);
   const draft=e.execute({op:'prepare',id:'a',expected_hash:before.state_hash,choices:cmd});
   const after=e.execute({op:'commit',id:'a',draft_token:draft.draft_token});
   result.log=verify(id,before,after,side);
   if(id==='helping_hand'){
    const control=new NativeEngine();try{
     control.execute({op:'restore',id:'c',snapshot:before.snapshot});
     const commands=choices(id,side);commands[side]='move 2, move 1 1';
     control.execute({op:'choose',id:'c',choices:commands});
     const baseline=control.execute({op:'checkpoint',id:'c'});
     const victim=x=>x.roster.find(r=>r.id===other).pokemon.find(p=>p.instance_id==='foe0');
     assert(victim(after).max_hp-victim(after).hp>victim(baseline).max_hp-victim(baseline).hp,'Helping Hand must increase companion damage');
    }finally{control.close();}
   }
   if(id==='ally_switch'){
    const commands={[side]:'move 1 1, move 3 1',[other]:'move 2 1, move 2 1'};
    e.execute({op:'choose',id:'a',choices:commands});
    const next=e.execute({op:'checkpoint',id:'a'});
    const own=next.roster.find(r=>r.id===side);
    assert.equal(own.pokemon.find(p=>p.instance_id==='actor').hp,190);
    assert(own.pokemon.find(p=>p.instance_id==='ally').hp<137,'Opponent target slot 1 must follow the swapped identity');
    // Restore check below applies to the checkpoint captured before this extra turn.
   }
   const r=new NativeEngine();try{r.execute({op:'restore',id:'b',snapshot:after.snapshot});assert.equal(r.execute({op:'checkpoint',id:'b'}).state_hash,after.state_hash);}finally{r.close();}
   rows.push({id,side,seed,case_id,origin,before,after,choices:cmd});result.status='PASS';
  }catch(error){result.error=error.stack;result.log=e.sessions.get('a')?.battle.log.slice(-18);}finally{e.close();}results.push(result);
 }
 fs.writeFileSync(path.join(OUT,'native.json'),JSON.stringify({results},null,2));
 fs.writeFileSync(path.join(OUT,'cases.json'),JSON.stringify(rows));
 for(const r of results.filter(r=>r.status==='FAIL').slice(0,4))console.log(r.case_id,r.error,r.log);
 console.log('DOUBLES_NATIVE',results.every(r=>r.status==='PASS')?'PASS':'FAIL',results.length);process.exitCode=results.some(r=>r.status==='FAIL')?1:0;
}
module.exports={IDS,choices,verify};
