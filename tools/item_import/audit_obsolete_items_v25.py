"""Read-only item-role review; only the explicit Cord ban is applied elsewhere."""
from pathlib import Path
from collections import defaultdict
import argparse, hashlib, json, subprocess

ROOT=Path(__file__).resolve().parents[2]
OUTPUT=ROOT/'docs/current/ITEM_SCOPE_V25.json'
KEEP={'metal_coat','kings_rock','deep_sea_tooth','deep_sea_scale'}


def build():
    api=json.loads((ROOT/'data/normalized/pokemon_api.json').read_text(encoding='utf-8'))
    policy=json.loads((ROOT/'config/item_selection_v1.json').read_text(encoding='utf-8'))
    connections=json.loads((ROOT/'modules/inventory/item_connections_v1.json').read_text(encoding='utf-8'))
    items=api['items'];uses=defaultdict(list)
    trade_records=[]
    for source,species in api['species'].items():
        for evo in species['evolutions']:
            if evo['trigger']!='trade':continue
            trade_records.append({'source':source,**evo})
            held=evo.get('conditions',{}).get('held_item')
            if held:uses[held].append({'source':source,'target':evo['species_id']})
    script=r'''
const fs=require('node:fs'),{Dex}=require('./.godot/battle_reference/runtime/node_modules/@pkmn/sim');
require('./modules/battle/backends/showdown/field_held_items.cjs').install(Dex);
const ids=['metal_coat','kings_rock','deep_sea_tooth','deep_sea_scale'];
const data=JSON.parse(fs.readFileSync('data/normalized/pokemon_api.json'));
const policy=JSON.parse(fs.readFileSync('config/item_selection_v1.json'));
const connections=JSON.parse(fs.readFileSync('modules/inventory/item_connections_v1.json'));
const allowed=connections.holdable_ids.filter(id=>!Object.hasOwn(policy.excluded_ids,id)&&!Object.hasOwn(policy.excluded_categories,data.items[id].category));
const missing=allowed.filter(id=>{let key=id;if(id.endsWith('_z_held')&&Dex.items.get(id.slice(0,-5)).zMove)key=id.slice(0,-5);return !Dex.items.get(key).exists;});
console.log(JSON.stringify({roles:Object.fromEntries(ids.map(id=>[id,Dex.items.get(id).shortDesc])),permitted:allowed.length,native_present:allowed.length-missing.length,missing:missing.sort(),cord_registered:Dex.items.get('linkingcord').exists}));
'''
    p=subprocess.run(['D:/Herramientas/NodeJS/node.exe','-e',script],cwd=ROOT,capture_output=True,text=True,check=True)
    native=json.loads(p.stdout)
    assert native['permitted']==624 and native['native_present']==621
    assert native['missing']==['amulet_coin','exp_share','luck_incense'] and not native['cord_registered']
    assert 'linking_cord' in policy['excluded_ids'] and len(uses)==14 and KEEP<=set(uses)
    candidates=[];retain=[]
    for item_id,edges in sorted(uses.items()):
        row={'id':item_id,'name_es':items[item_id]['display_name'],'trade_routes':edges,
             'currently_excluded':item_id in policy['excluded_ids']}
        if item_id in KEEP:
            row.update(status='KEEP_OTHER_BATTLE_ROLE',battle_role=native['roles'][item_id]);retain.append(row)
        else:
            row.update(status='REVIEW_AFTER_TRADE_LEVEL_RULES',reason='Evolution requirement may become obsolete; no exclusion or level change applied now. Fling metadata alone is not counted as another meaningful item role.');candidates.append(row)
    assert len(candidates)==10 and len(retain)==4
    excluded=[key for key,row in items.items() if key in policy['excluded_ids'] or row['category']in policy['excluded_categories']]
    assert len(excluded)==44
    return {
        'status':'SCOPE_REVIEW_NO_EVOLUTION_RULE_CHANGE','date':'2026-10-31',
        'confirmed_exclusion':['linking_cord'],'excluded_count':len(excluded),
        'trade_level_conversion':{'status':'DEFERRED_BY_USER','levels_selected':None,
            'strategy':'Later compare other games/randomizers and any table supplied by the friend. No universal level or replacement code activated.'},
        'canonical_trade_record_count':len(trade_records),'canonical_trade_species_count':len({r['source']for r in trade_records}),
        'trade_item_candidates':candidates,'retain_for_battle':retain,
        'contest_only_candidates':[{'id':key,'name_es':row['display_name'],'status':'REVIEW_SIDE_MODE_SCOPE_NOT_EXCLUDED'}for key,row in items.items() if row['category']=='scarves'],
        'native':native,
        'rules':['Only Linking Cord is newly excluded. Other candidates remain unchanged.',
                 'Mails/revival items retain the prior exclusions; Poke Doll remains because it provides escape.',
                 'No trading-to-level conversion, level-37 default, canonical evolution edit or additional item ban is implemented.',
                 'An absent world system does not by itself mean its items should be banned.'],
        'verification_report':'.godot/item_scope_v25/results.json',
        'source_sha256':{rel:hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()for rel in [
            'data/normalized/pokemon_api.json','config/item_selection_v1.json','modules/inventory/item_connections_v1.json']},
    }


def main():
    p=argparse.ArgumentParser(description=__doc__);g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--write',action='store_true');g.add_argument('--check',action='store_true');args=p.parse_args()
    value=build();text=json.dumps(value,ensure_ascii=False,indent=2)+'\n'
    if args.write:OUTPUT.write_text(text,encoding='utf-8',newline='\n')
    elif OUTPUT.read_text(encoding='utf-8')!=text:raise ValueError('item scope audit is stale')
    print('ITEM_SCOPE_AUDIT PASS candidates=10 keep_battle=4 excluded=44');return 0


if __name__=='__main__':raise SystemExit(main())
