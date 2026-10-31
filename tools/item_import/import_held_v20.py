"""Compile twelve reviewed non-passive held definitions, not their bag/world uses."""
from pathlib import Path
import argparse,re,unicodedata
from import_recovery import ROOT,HASHES,SOURCE,indexes,field,load,digest,encode

IDS=('black_flute','blue_flute','blue_scarf','fluffy_tail','green_scarf','pink_scarf',
     'poke_doll','red_flute','red_scarf','white_flute','yellow_flute','yellow_scarf')
GEN_FILES={
 'pokered_item_constants.asm':'b5a1db015fbf0de637381eb39350f21f35a436a8088e2f6657f65c79f118f97f',
 'pokeemerald_items.h':'6e3a9728b4d90cc23fee0aae9b9ffa9fbd71541e6b3cb2b966f334930b6ad6f8',
 'pokecrystal_item_constants.asm':'bb870ffb3448845aa886ede0030a114a7773d7cb6924d2c59acdca0c53a02e58',
}
OUTPUT=ROOT/'modules/battle/backends/showdown/field_misc_items_v20.json'

def metadata(id,block,gen):
    # All these IDs were individually reviewed: none has a passive held effect.
    # A newly added conditional held effect is not safe to discard.
    if re.search(r'\.holdEffect\s*=',block):raise ValueError('passive held effect requires its own system: '+id)
    depth=0
    for line in block.splitlines():
        if re.match(r'\s*#if',line):depth+=1
        elif re.match(r'\s*#endif',line):
            depth-=1
            if depth<0:raise ValueError('unbalanced source conditional')
        elif re.match(r'\s*#(?:else|elif)',line):
            if not depth:raise ValueError('unbalanced source branch')
        elif depth and re.match(r'\s*\.(?:name|flingPower)\s*=',line):raise ValueError('conditional metadata needs review: '+id)
    if depth:raise ValueError('unterminated source conditional')
    name=re.fullmatch(r'ITEM_NAME\("([^"\\]+)"\)',field(block,'name',''))
    power=field(block,'flingPower','')
    if not name or not re.fullmatch(r'\d+',power) or int(power) not in (10,30):raise ValueError('unsupported metadata: '+id)
    # The pinned simulator derives IDs from display names using ASCII filtering;
    # Poké Doll would otherwise become "pokdoll" and lose its definition on reload.
    native_name=unicodedata.normalize('NFKD',name[1]).encode('ascii','ignore').decode('ascii')
    if re.sub('[^a-z0-9]','',native_name.lower())!=id.replace('_',''):raise ValueError('native name/ID mismatch: '+id)
    return {'name':native_name,'gen':gen,'fling':{'basePower':int(power)}}

def build(source_dir=ROOT/'.godot/item_mochi_v13/references',gen_dir=ROOT/'.godot/field_held_v16/references'):
    sources={}
    for name,expected in HASHES.items():
        raw=(source_dir/name).read_bytes()
        if digest(raw)!=expected:raise ValueError('source hash mismatch: '+name)
        sources[name]=raw.decode('utf-8')
    generations={}
    for name,expected in GEN_FILES.items():
        raw=(gen_dir/name).read_bytes()
        if digest(raw)!=expected:raise ValueError('generation source hash mismatch: '+name)
        generations[name]=raw.decode('utf-8')
    items,_=indexes(sources['items.h'],sources['item_effects.h'])
    catalog=load(ROOT/'data/normalized/pokemon_api.json')['items']
    policy=load(ROOT/'config/item_selection_v1.json')
    holdable=load(ROOT/'modules/inventory/item_connections_v1.json')['holdable_ids']
    result={};contexts={}
    for id in IDS:
        if id not in catalog or id not in holdable or id in policy['excluded_ids'] or catalog[id]['category'] in policy['excluded_categories']:
            raise ValueError('ID not permitted/holdable: '+id)
        symbol=id.upper()
        if id=='poke_doll':
            if not re.search(r'\bconst\s+'+symbol+r'\b',generations['pokered_item_constants.asm']):raise ValueError('missing Gen 1 proof')
            gen=1
        else:
            if not re.search(r'\bITEM_'+symbol+r'\b',generations['pokeemerald_items.h']):raise ValueError('missing Gen 3 proof: '+id)
            if any(re.search(r'\bconst\s+'+symbol+r'\b',generations[name]) for name in ['pokered_item_constants.asm','pokecrystal_item_constants.asm']):raise ValueError('generation classification conflict: '+id)
            gen=3
        key=id.replace('_','')
        if key in result:raise ValueError('native ID collision')
        block=items[id];result[key]=metadata(id,block,gen)
        contexts[id]={'held_passive_effect':False,'field_handler':field(block,'fieldUseFunc'),
          'source_name':field(block,'name'),
          'battle_bag_handler':field(block,'battleUsage'),'field_effect':field(block,'effect'),
          'bag_not_consumed':field(block,'notConsumed')=='TRUE',
          'special_use_certified_by_this_import':False}
    return {'schema_version':1,'source':SOURCE,'source_sha256':HASHES,
      'generation_source_sha256':GEN_FILES,'items':result,'separate_contexts':contexts}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    group=p.add_mutually_exclusive_group(required=True);group.add_argument('--write',action='store_true');group.add_argument('--check',action='store_true')
    args=p.parse_args();value=encode(build())
    if args.write:OUTPUT.write_text(value,encoding='utf-8',newline='\n')
    elif OUTPUT.read_text(encoding='utf-8')!=value:raise ValueError('generated metadata differs')
    print('HELD_IMPORT_V20 PASS ids='+str(len(IDS)));return 0

if __name__=='__main__':raise SystemExit(main())
