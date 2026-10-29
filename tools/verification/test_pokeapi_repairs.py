"""Regression for the source adapter and the narrowly repaired dataset records."""
import hashlib
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from pokeapi_adapter_v3 import evolution_record

def read(path): return json.loads(Path(path).read_text(encoding='utf-8'))

class SourceRepairs(unittest.TestCase):
    def test_equal_attack_defense_survives_adapter(self):
        row=evolution_record('hitmontop',{'trigger':{'name':'level-up'},'min_level':20,
            'relative_physical_stats':0,'needs_overworld_rain':False,'item':None})
        self.assertEqual(row.get('conditions'),{'relative_physical_stats':0})

    def test_numeric_zero_and_booleans_are_distinct(self):
        for value in (-1,0,1):
            row=evolution_record('target',{'relative_physical_stats':value,'min_affection':0,
                'needs_multiplayer':False,'held_item':None,'time_of_day':''})
            self.assertEqual(row['conditions'],{'relative_physical_stats':value,'min_affection':0})

    def test_raw_and_normalized_agree_with_source_condition(self):
        for filename in ['data/raw/pokemon_api.json','data/normalized/pokemon_api.json']:
            data=read(ROOT/filename)['species']
            sp=next(s for s in data if s['id']=='tyrogue') if isinstance(data,list) else data['tyrogue']
            rows={e['species_id']:e for e in sp['evolutions']}
            for target,relation in [('hitmonlee',1),('hitmonchan',-1),('hitmontop',0)]:
                self.assertEqual(rows[target]['min_level'],20)
                self.assertEqual(rows[target].get('conditions'),{'relative_physical_stats':relation})

    def test_variant_binding_and_hisui_provenance(self):
        variants=read(ROOT/'config/pokemon_variants_v1.json')
        self.assertEqual(variants['canonical_sha256'],hashlib.sha256((ROOT/'data/normalized/pokemon_api.json').read_bytes()).hexdigest())
        meta=variants['regional_species']['lilligant_hisui']['source_metadata']
        source=Path(r'F:\pokemon roma el calvo\pokeapi-api-data\data\api\v2\pokemon\10237\index.json')
        self.assertEqual(meta['source_sha256'],hashlib.sha256(source.read_bytes()).hexdigest())

if __name__=='__main__': unittest.main()
