'use strict';
const fs=require('node:fs');
const runtime=require('../../modules/battle/backends/showdown/native_engine.cjs');
const {NativeEngine,lookup,ROOT}=runtime;
const path=require('node:path');
class Probe extends NativeEngine {
  dispatch(c) {return c.op === 'catalog' ? auditCatalog() : super.dispatch(c);}
}
function auditCatalog() {
  const game = JSON.parse(fs.readFileSync(path.join(ROOT,'data/normalized/pokemon_api.json'),'utf8'));
  const variants = JSON.parse(fs.readFileSync(path.join(ROOT,'config/pokemon_variants_v1.json'),'utf8'));
  const report = {};
  for (const kind of ['moves','abilities','items','species']) {
    const rows = kind === 'species' ? {...game.species,...variants.regional_species} : game[kind];
    const missing=[],matched=[],collisions={},differences=[];
    for (const [id,row] of Object.entries(rows)) {
      let entry = lookup(kind,id);
      if (!entry.exists && kind === 'species' && row.source_metadata?.source_pokemon_id) entry = lookup(kind,row.source_metadata.source_pokemon_id);
      if (!entry.exists) {missing.push({id,category:row.category ?? '',classification:row.classification ?? ''});continue;}
      matched.push({id,native_id:entry.id,nonstandard:entry.isNonstandard ?? null,generation:entry.gen,
        ...(kind === 'species' ? {weight_kg:entry.weightkg,pokedex:entry.num} : {}),
        ...(kind === 'moves' ? {is_z:entry.isZ ?? false,is_max:!!entry.isMax,handler_keys:Object.keys(entry).filter(k=>/^on[A-Z]/.test(k)),flags:entry.flags} : {})});
      (collisions[entry.id] ??= []).push(id);
      if (kind === 'species') {
        const map={base_hp:'hp',base_attack:'atk',base_defense:'def',base_special_attack:'spa',base_special_defense:'spd',base_speed:'spe'};
        for (const [key,short] of Object.entries(map)) if (row[key] !== entry.baseStats[short]) differences.push({id,field:key,game:row[key],native:entry.baseStats[short]});
        const types = row.type_ids?.length ? row.type_ids : [row.primary_type_id,row.secondary_type_id].filter(Boolean);
        if (types.join(',') !== entry.types.map(x=>x.toLowerCase()).join(',')) differences.push({id,field:'types',game:types,native:entry.types});
      }
      if (kind === 'moves') {
        const fields={power:entry.basePower,pp:entry.pp,type_id:entry.type.toLowerCase(),damage_class:entry.category.toLowerCase(),accuracy:entry.accuracy === true ? -1:entry.accuracy,priority:entry.priority};
        for (const [field,value] of Object.entries(fields)) if (row[field] !== value) differences.push({id,field,game:row[field],native:value});
      }
    }
    report[kind]={total:Object.keys(rows).length,matched:matched.length,missing,entries:matched,
      aliases:Object.entries(collisions).filter(([,ids])=>ids.length>1).map(([native_id,ids])=>({native_id,ids})),data_differences:differences,
      compared_fields:kind === 'moves' ? ['power','pp','type_id','damage_class','accuracy','priority']:kind === 'species' ? ['baseStats','types']:[]};
  }
  report.caveat='ID/data coverage only; no claim that every effect or our combined generation profile is certified.';
  return report;
}


module.exports={...runtime,Probe,auditCatalog};
