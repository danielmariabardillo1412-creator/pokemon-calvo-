'use strict';
// Calvo compatibility profile over the pinned MIT Showdown simulator. No
// community mod files, moves, damage formulas or condition callbacks are copied.
const path=require('node:path');
const ROOT=path.resolve(__dirname,'../../../..');
const RUNTIME=path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim');
const {Dex}=require(RUNTIME);
const {Side}=require(path.join(RUNTIME,'build/cjs/sim/side.js'));
const SINGLE='gen9calvounifiedv1',DOUBLE='gen9calvounifieddoublesv1';
const IDS=new Set([SINGLE,DOUBLE]);
const original=Side.prototype.canDynamaxNow;

// Prototype installation is process-local. Restore uses the same registered
// format and serialized native dynamaxUsed; it never resets the allowance.
Side.prototype.canDynamaxNow=function(){
 if(!IDS.has(this.battle.format.id))return original.call(this);
 return this.battle.gen===9&&!this.dynamaxUsed;
};
Dex.formats.extend([[SINGLE,'gen9customgame','[Gen 9] Calvo Unified V1'],
 [DOUBLE,'gen9doublescustomgame','[Gen 9] Calvo Unified Doubles V1']].map(([id,base,name])=>{
 const parent=Dex.formats.get(base);
 return {...parent,id,name,ruleTable:null,onBegin(){
  for(const side of this.sides)side.dynamaxUsed=false;
 }};
}));
module.exports={SINGLE,DOUBLE,isUnified:id=>IDS.has(id)};
