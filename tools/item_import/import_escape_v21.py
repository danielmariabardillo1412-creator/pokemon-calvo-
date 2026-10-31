"""Compile the pinned RHH escape family; no battle engine code is imported."""
import argparse
from import_recovery import ROOT,HASHES,SOURCE,indexes,field,load,digest,encode

OUTPUT=ROOT/'modules/inventory/battle_escape_profile.json'
EXPECTED={'poke_doll','fluffy_tail','poke_toy'}

def compile_row(id,block):
    if field(block,'battleUsage')!='EFFECT_ITEM_ESCAPE' or field(block,'fieldUseFunc')!='ItemUseOutOfBattle_CannotUse':raise ValueError('unsupported escape context: '+id)
    if field(block,'notConsumed','FALSE')!='FALSE' or field(block,'holdEffect') is not None:raise ValueError('unsupported consumption/held effect: '+id)
    return {'wild_only':True,'consume':1,'guaranteed':True,'rng_consumed':False}

def build(source_dir=ROOT/'.godot/item_mochi_v13/references'):
    sources={}
    for name,expected in HASHES.items():
        raw=(source_dir/name).read_bytes()
        if digest(raw)!=expected:raise ValueError('source hash mismatch: '+name)
        sources[name]=raw.decode('utf-8')
    source,_=indexes(sources['items.h'],sources['item_effects.h'])
    candidates={id:block for id,block in source.items() if field(block,'battleUsage')=='EFFECT_ITEM_ESCAPE'}
    if set(candidates)!=EXPECTED:raise ValueError('escape family differs from reviewed set')
    catalog=load(ROOT/'data/normalized/pokemon_api.json')['items'];policy=load(ROOT/'config/item_selection_v1.json')
    items={}
    for id,block in sorted(candidates.items()):
        if id not in catalog or id in policy['excluded_ids'] or catalog[id]['category'] in policy['excluded_categories']:raise ValueError('unknown/excluded item: '+id)
        items[id]=compile_row(id,block)
    return {'schema_version':1,'profile':'rhh_escape_consumables_v21','source':SOURCE,'source_sha256':HASHES,
      'policy_sha256':digest((ROOT/'config/item_selection_v1.json').read_bytes()),'items':items}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    mode=p.add_mutually_exclusive_group(required=True);mode.add_argument('--check',action='store_true');mode.add_argument('--write',action='store_true')
    args=p.parse_args();text=encode(build())
    if args.write:OUTPUT.write_text(text,encoding='utf-8',newline='\n')
    elif OUTPUT.read_text(encoding='utf-8')!=text:raise ValueError('generated escape manifest differs')
    print('ESCAPE_IMPORT_V21 PASS ids=3');return 0

if __name__=='__main__':raise SystemExit(main())
