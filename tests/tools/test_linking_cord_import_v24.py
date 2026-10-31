from pathlib import Path
import sys,json
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_import'))
import import_linking_cord_v24 as compiler


def main():
    data=compiler.build()
    assert data==json.loads(compiler.OUTPUT.read_text(encoding='utf-8'))
    print('PASS: stored profile is the pinned compilation')
    expected={'kadabra':'alakazam','machoke':'machamp','graveler':'golem','graveler_alola':'golem_alola',
              'haunter':'gengar','boldore':'gigalith','gurdurr':'conkeldurr','phantump':'trevenant'}
    assert data['evolution_routes']==expected
    assert len(data['deferred_routes'])==4 and data['deferred_runtime_species']==['pumpkaboo']
    print('PASS: eight explicit routes; four sized forms deferred')
    assert data['items']=={'linkingcord':{'name':'Linking Cord','gen':8,'fling':{'basePower':30}}}
    assert data['everstone_exception_species']==['kadabra']
    print('PASS: exact held metadata and modern Kadabra exception')
    bad='    [SPECIES_HAUNTER] =\n    {\n.evolutions = EVOLUTION({EVO_ITEM, ITEM_LINKING_CORD, SPECIES_GENGAR}),\n    },'
    try:compiler.source_pairs(bad)
    except ValueError:pass
    else:raise AssertionError('item-only route without trade proof accepted')
    print('PASS: source mismatch fails closed')
    fake={'haunter':{'evolutions':[{'trigger':'trade','species_id':'gengar','conditions':{'held_item':'metal_coat'}}]},'gengar':{}}
    try:compiler.runtime_routes({'haunter':'gengar'},fake)
    except ValueError:pass
    else:raise AssertionError('conditioned trade was silently weakened')
    print('PASS: additional canonical requirements are not discarded')
    print('All linking-cord import tests passed');return 0


if __name__=='__main__':raise SystemExit(main())
