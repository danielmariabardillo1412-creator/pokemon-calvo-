"""Pin existing weather casts/common loops for the explicit battle pilot."""
import hashlib
import json
import shutil
import sys
from pathlib import Path
from build_move_batch import Converter, dependencies
from move_layer_timing import bake_layers

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path('D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1')
IDS = ['rain_dance', 'hail', 'sandstorm', 'snowscape', 'chilly_reception']


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write(p, data):
    p.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')


def build():
    output = ROOT / '.godot/battle_weather'
    output.mkdir(parents=True, exist_ok=True)
    index_path = ROOT / '.godot/move_batch_catalog/index.json'
    assert sha(index_path) == 'bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1'
    index = json.loads(index_path.read_text(encoding='utf-8'))
    clips, sheets = [], {}
    for shard in index['shards']:
        if not any(e['move_id'] in IDS for e in shard['entries']): continue
        path = index_path.parent / shard['path']
        assert sha(path) == shard['sha256']
        pack = json.loads(path.read_text(encoding='utf-8'))
        for c in pack['clips']:
            if c['move_id'] not in IDS: continue
            clips.append(c)
            for key in {c['sheet'], *c['layer_sheets'].values()} - {''}:
                assert sha(path.parent / key) + '.png' == key
                sheets[key] = pack['sheets'][key]
                shutil.copyfile(path.parent / key, output / key)
    assert len(clips) == 10
    casts = output / 'casts.json'
    write(casts, {'version': 1, 'selection': 'weather_cast_pilot_v1', 'scope': 'EXPLICIT_WEATHER_CASTS', 'clips': clips, 'sheets': sheets})
    previous = ROOT / '.godot/move_external_context/e1221ddaae3b2375'
    context = json.loads((previous / 'context.json').read_text(encoding='utf-8'))
    assert sha(previous / 'weather.json') == context['weather_sha256']
    common = json.loads((previous / 'weather.json').read_text(encoding='utf-8'))
    for key in common['sheets']:
        assert sha(previous / key) + '.png' == key
        shutil.copyfile(previous / key, output / key)
    sys.path.insert(0, str(SOURCE))
    from audit_pack_inventory import load_gen9
    found = [a for a in load_gen9() if hasattr(a, 'attrs') and a.attrs.get('@name') == 'Common:Sandstorm']
    assert len(found) == 1
    source_sha = hashlib.sha256(json.dumps(found[0].attrs, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    assert source_sha == '25db6fbf3ab3b290bc57cd05d7b022ad9a6b7e20aa9d952d7ee5a5ceae162b03'
    converter = Converter(SOURCE / 'Gen9_Move_Animations/Graphics/Animations', bake_layers)
    sand = converter.convert('pilot_sand', {'display_name': 'Common:Sandstorm', 'target': 'entire-field', 'classification': 'DATA_ONLY'}, 'back', found[0])
    assert len(sand['frames']) == 20
    for key in dependencies([sand]):
        common['sheets'][key] = converter.sheets[key]
        shutil.copyfile(converter.sheets[key]['source'], output / key)
    common['clips'].append(sand)
    write(output / 'common.json', common)
    write(output / 'manifest.json', {'version': 1, 'selection': 'battle_weather_v1', 'casts_sha256': sha(casts),
          'common_sha256': sha(output / 'common.json'), 'index_sha256': sha(index_path),
          'sand_source_sha256': source_sha, 'builder_sha256': sha(Path(__file__)),
          'common_cadences': [30, 30, 30, 20], 'license_review_required_before_distribution': True})
    print('WEATHER PACK PASS: 10 casts +4 common loops; PNG bytes', sum(p.stat().st_size for p in output.glob('*.png')))
    print('CAST_SHA', sha(casts), 'COMMON_SHA', sha(output / 'common.json'))


if __name__ == '__main__': build()
