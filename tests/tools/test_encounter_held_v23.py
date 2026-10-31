"""Positive and fail-closed checks for the V23 descriptor compiler."""
from pathlib import Path
import json, sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/item_import'))
import import_encounter_held_v23 as compiler


def main():
    actual=compiler.build()
    assert set(actual['items'])=={'cleansetag','pureincense'}
    assert actual['items']['cleansetag']=={'name':'Cleanse Tag','gen':2,'fling':{'basePower':30}}
    assert actual['items']['pureincense']=={'name':'Pure Incense','gen':4,'fling':{'basePower':10}}
    assert json.loads(compiler.OUTPUT.read_text(encoding='utf-8'))==actual
    print('PASS: two descriptors match pinned sources and stored output')
    assert set(actual['items']).isdisjoint({'amuletcoin','expshare','linkingcord','luckincense'})
    print('PASS: no unreviewed descriptor was admitted')
    block='.name = ITEM_NAME("Cleanse Tag"),\n.holdEffect = HOLD_EFFECT_REPEL,\n.flingPower = 30,'
    for wrong in [block.replace('30','10'),block.replace('REPEL','NONE'),block.replace('Cleanse Tag','Other'), '#if TEST\n'+block+'\n#endif']:
        try: compiler.metadata('cleanse_tag',wrong)
        except ValueError: pass
        else: raise AssertionError('unreviewed source change was accepted')
        print('PASS: unreviewed source change rejected')
    assert len(actual['generation_source_sha256'])==4
    print('PASS: generation proof pinned by content hash')
    print('All encounter-held import tests passed')
    return 0


if __name__=='__main__': raise SystemExit(main())
