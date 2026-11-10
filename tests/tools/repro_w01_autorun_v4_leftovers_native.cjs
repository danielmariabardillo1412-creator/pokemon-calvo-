'use strict';
// W01 TANDA04/row01: no mocked recovery; genuine native Showdown end-turn hook.
const assert=require('node:assert/strict');
const {NativeEngine}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const mon=(species_id,instance_id,moves,held_item_id='',hp=null)=>({
  species_id,instance_id,level:species_id==='caterpie'?1:100,moves,held_item_id,
  ...(hp===null?{}:{current_hp:hp})
});
const owned=(result,id)=>result.roster[0].pokemon.find(p=>p.instance_id===id);
function trial(mode){
  const e=new NativeEngine();
  try{
    const full=mode==='full';
    e.execute({op:'start',id:'leftovers-'+mode,format:'gen9calvounifiedv1',seed:[19,2,3,4],
      teams:{p1:[
        mon('mew','own',['reflect','tackle'],mode==='active'||full?'leftovers':'',full?null:150),
        mon('mew','reserve',['reflect'],mode==='reserve'?'leftovers':'')],
        p2:[mon('caterpie','foe',['growl'])]}
    });
    const id='leftovers-'+mode;
    const before=e.execute({op:'checkpoint',id});
    const b=owned(before,'own');
    assert(b&&b.hp>0&&b.max_hp>b.hp===!full, 'precondition HP state '+mode);
    const draft=e.execute({op:'prepare',id,expected_hash:before.state_hash,
      choices:{p1:'move 1',p2:'move 1'}});
    assert.equal(e.execute({op:'checkpoint',id}).state_hash,before.state_hash,
      'prepare cannot prematurely heal or mutate '+mode);
    const after=e.execute({op:'commit',id,draft_token:draft.draft_token});
    const a=owned(after,'own');
    assert(a&&a.hp>=b.hp,'native battle must retain owner');
    const expected=mode==='active'?Math.floor(a.max_hp/16):0;
    assert.equal(a.hp-b.hp,expected,'native exact residual HP delta '+mode);
    assert.equal(a.item,(mode==='active'||full)?'leftovers':'',
      'original active holder must retain non-consumable '+mode);
    if(mode==='reserve')assert.equal(owned(after,'reserve').item,'leftovers',
      'reserve item must not transfer or act');
    const restored=new NativeEngine();
    try{
      restored.execute({op:'restore',id:'copy',snapshot:after.snapshot});
      assert.equal(restored.execute({op:'checkpoint',id:'copy'}).state_hash,
        after.state_hash,'snapshot preserves residual item result '+mode);
    }finally{restored.close()}
    return {mode,delta:a.hp-b.hp};
  }finally{e.close()}
}
const out=['active','none','reserve','full'].map(trial);
assert(out[0].delta>0 && out.slice(1).every(x=>x.delta===0));
console.log('W01_V4_NATIVE PASS id=leftovers variants=4 exact_residual=1 snapshots=4');
