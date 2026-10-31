'use strict';
// Static inspection of the pinned runtime, never a claim that an item was used.
const fs=require('node:fs'),path=require('node:path');
const {ROOT,lookup}=require('../../modules/battle/backends/showdown/native_engine.cjs');
const OUT=path.join(ROOT,'.godot/item_audit_v1');
const version=JSON.parse(fs.readFileSync(path.join(ROOT,'.godot/battle_reference/runtime/node_modules/@pkmn/sim/package.json'))).version;
if(version!=='0.10.11')throw Error('Pinned runtime required');
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
const rows=Object.keys(data.items).sort().map(id=>{
 const item=lookup('items',id);
 if(!item.exists)return {id,exists:false};
 const hooks=Object.keys(item).filter(k=>k.startsWith('on')&&typeof item[k]==='function').sort();
 const fields={};
 for(const k of ['isBerry','isGem','isPokeball','isMail','isChoice','boosts','naturalGift','fling','zMove','zMoveType','zMoveFrom','megaStone','megaEvolves','itemUser','forcedForme','onPlate','onDrive','onMemory','isNonstandard'])
  if(item[k]!==undefined&&typeof item[k]!=='function')fields[k]=item[k];
 return {id,exists:true,native_id:item.id,native_name:item.name,gen:item.gen,sprite_index:item.spritenum??null,hooks,fields};
});
fs.writeFileSync(path.join(OUT,'native_inventory.json'),JSON.stringify({version,rows},null,2));
console.log('ITEM_NATIVE_INVENTORY',rows.length,'canonical;',rows.filter(r=>r.exists).length,'native entries');
