"""Bounded RHH Linking Cord routes, cross-checked against existing runtime data.

Only parse inert source records. Never rewrite canonical evolutions or run C/C#.
Missing form representations are reported, never collapsed into another form.
"""
from pathlib import Path
import argparse, hashlib, json, re
from import_recovery import indexes, field, HASHES

ROOT=Path(__file__).resolve().parents[2]
REF=ROOT/'.godot/linking_cord_v24/references'
OUTPUT=ROOT/'modules/inventory/linking_cord_profile_v24.json'
PINNED={
    'gen_1_families.h':'17a6eaa188036905ecb88b2aeb69d27a46dd035bb33ed4de8b81a02bcc411f1e',
    'gen_5_families.h':'d4d8412de615d6cc957256c6d3074bef590eee636d99ccee3259d131a89232ad',
    'gen_6_families.h':'c3fa6a32b8b56f4aee9c597d5e580fc2fa7c5d01136be39743dd6b85db380d3c',
    'pokemon.c':'f48b7e7891bb105b5518ebd14ff843a69e32eee246bf05d33d3084a3d6a5ddf0',
    'pokemon_config.h':'e476277d082276ac078452c44482cf9b3b6fb076159fe4745f0774bc276b85ba',
    'ItemStorage8LA.cs':'43a91ef80fffb6a76cbf53d8febe5c9320e48bea560bff3a26a6011e811058ed',
    'text_Items_en.txt':'d2dc1342a4ec6280d7122366e23b945e8649d48234c6d5e9b8e1a41d9d53269d',
}
DATA_SHA='14cd97f59e0f68ff89acdd62e607f8dbff36c7562d001ce682869e0915181b2e'
VARIANT_SHA='4650c8d6c2d8bd0dd90db95cb78b5596a9a6ffd7693b006a6eb9a6fe929aa54c'
RHH='https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c'


def pinned(path, expected):
    raw=path.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=expected: raise ValueError('source hash mismatch: '+str(path))
    return raw.decode('utf-8')


def source_pairs(text):
    pairs={}
    for match in re.finditer(r'^    \[SPECIES_([A-Z0-9_]+)\] =\s*\{(.*?)^    \},',text,re.M|re.S):
        hits=re.findall(r'\{EVO_ITEM,\s*ITEM_LINKING_CORD,\s*SPECIES_([A-Z0-9_]+)\}',match[2])
        for target in hits:
            if not re.search(r'\{EVO_TRADE,\s*0,\s*SPECIES_'+re.escape(target)+r'\}',match[2]):
                raise ValueError('item route not backed by unconditional trade: '+match[1])
            source=match[1].lower()
            if source in pairs: raise ValueError('ambiguous source route: '+source)
            pairs[source]=target.lower()
    return pairs


def runtime_routes(pairs, species):
    routes={};deferred=[];deferred_runtime=set()
    for source,target in sorted(pairs.items()):
        if source not in species or target not in species:
            deferred.append({'source':source,'target':target,'reason':'runtime_form_not_represented'})
            # Preserve the API's form selectors as a dependency; do not turn a
            # missing sized form into the default creature.
            for base,data in species.items():
                if any(rec.get('conditions',{}).get('base_form')==source for rec in data.get('evolutions',[])):
                    deferred_runtime.add(base)
            continue
        matches=[rec for rec in species[source].get('evolutions',[]) if rec['trigger']=='trade'
                 and rec['species_id']==target and rec.get('item_id','')==''
                 and not rec.get('conditions') and rec.get('min_level',0)==0]
        if not matches: raise ValueError('canonical trade mismatch: '+source+' -> '+target)
        routes[source]=target
    return routes,deferred,sorted(deferred_runtime)


def build():
    texts={name:pinned(REF/name,digest)for name,digest in PINNED.items()}
    pairs={}
    for name in ['gen_1_families.h','gen_5_families.h','gen_6_families.h']:
        for source,target in source_pairs(texts[name]).items():
            if source in pairs:raise ValueError('duplicate source across headers')
            pairs[source]=target
    if len(pairs)!=12:raise ValueError('unexpected source route count')
    data=json.loads(pinned(ROOT/'data/normalized/pokemon_api.json',DATA_SHA))
    variants=json.loads(pinned(ROOT/'config/pokemon_variants_v1.json',VARIANT_SHA))
    runtime={**data['species'],**variants['regional_species']}
    routes,deferred,deferred_runtime=runtime_routes(pairs,runtime)
    if len(routes)!=8 or len(deferred)!=4 or deferred_runtime!=['pumpkaboo']:
        raise ValueError('runtime route coverage changed; review required')
    sources=ROOT/'.godot/item_mochi_v13/references'
    items,_=indexes(pinned(sources/'items.h',HASHES['items.h']),pinned(sources/'item_effects.h',HASHES['item_effects.h']))
    block=items['linking_cord']
    if (field(block,'name')!='ITEM_NAME("Linking Cord")' or field(block,'flingPower')!='30'
            or field(block,'fieldUseFunc')!='ItemUseOutOfBattle_EvolutionStone'
            or field(block,'holdEffect') is not None):
        raise ValueError('Linking Cord item metadata changed')
    # Generation/identity proof uses the cached primary PKHeX LA inventory table.
    if texts['text_Items_en.txt'].splitlines()[1611]!='Linking Cord':raise ValueError('LA item identity mismatch')
    general=re.search(r'General =>\s*\[(.*?)\];',texts['ItemStorage8LA.cs'],re.S)
    if not general or '1611' not in re.findall(r'\d+',general[1]):raise ValueError('Gen8 LA inventory proof absent')
    if not re.search(r'#define P_KADABRA_EVERSTONE\s+GEN_LATEST',texts['pokemon_config.h']):raise ValueError('Everstone profile changed')
    if '(P_KADABRA_EVERSTONE < GEN_4 || species != SPECIES_KADABRA)' not in texts['pokemon.c']:
        raise ValueError('Everstone exception proof absent')
    return {
        'schema_version':1,'profile':'calvo_linking_cord_v24','source':RHH,
        'source_sha256':{**PINNED,'items.h':HASHES['items.h'],'item_effects.h':HASHES['item_effects.h']},
        'canonical_sha256':DATA_SHA,'variants_sha256':VARIANT_SHA,
        'items':{'linkingcord':{'name':'Linking Cord','gen':8,'fling':{'basePower':30}}},
        'evolution_routes':routes,'deferred_routes':deferred,'deferred_runtime_species':deferred_runtime,
        'everstone_exception_species':['kadabra'],
        'generation_reference':'https://github.com/kwsch/PKHeX/blob/master/PKHeX.Core/Items/ItemStorage8LA.cs',
        'generation_item_id':1611,
        'limits':['Community RHH item adapter, not a new trade/network system.',
                  'The four Pumpkaboo sized-form routes remain blocked until represented.',
                  'Fainted/temporary battle creatures cannot use this field adapter; no revival.'],
    }


def encoded(value):return json.dumps(value,ensure_ascii=False,indent=2)+'\n'


def main():
    p=argparse.ArgumentParser(description=__doc__);g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--write',action='store_true');g.add_argument('--check',action='store_true')
    args=p.parse_args();text=encoded(build())
    if args.write:OUTPUT.write_text(text,encoding='utf-8',newline='\n')
    elif OUTPUT.read_text(encoding='utf-8')!=text:raise ValueError('compiled profile mismatch')
    print('LINKING_CORD_IMPORT PASS routes=8 deferred=4');return 0


if __name__=='__main__':raise SystemExit(main())
