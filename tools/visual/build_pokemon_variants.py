"""Package existing regional/shiny sprites and a separate regional runtime overlay.

Reads the audited library; never changes source art or canonical datasets.
Reuses V3's pure learnset selection helpers, without running its adapter/importer.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import re
from statistics import median
import sys

from PIL import Image

GAME = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(GAME / 'tools'))
from pokeapi_adapter_v3 import choose_version_group, build_learnset


def read(p):
    return json.loads(Path(p).read_text(encoding='utf-8'))


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def write(p, value):
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def slug(s):
    return s.replace('-', '_')


def regional_rows(audit):
    return [r for r in audit['forms']
            if re.search(r'-(alola|galar|hisui|paldea)(-|$)', r['name'])
            and '-cap' not in r['name'] and '-totem-' not in r['name']
            and not r['name'].endswith('-zen')]


def regional_definition(row, api, data, regional_ids):
    source = api / 'pokemon' / str(row['pokemon_id']) / 'index.json'
    pokemon = read(source)
    base = data['species'][slug(row['species_name'])]
    region = re.search(r'-(alola|galar|hisui|paldea)(-|$)', row['name']).group(1)
    label = {'alola': 'Alola', 'galar': 'Galar', 'hisui': 'Hisui', 'paldea': 'Paldea'}[region]
    name = base['display_name'] + ' de ' + label
    if row['name'].startswith('tauros-paldea-'):
        name += ' (' + {'combat': 'Combatiente', 'blaze': 'Ardiente', 'aqua': 'Acuática'}[row['name'].split('-')[2]] + ')'
    key = slug(row['name'])
    group, reason = choose_version_group(pokemon, {})
    learnset = build_learnset(pokemon, group)
    assert group and learnset, key
    assert all(e['move_id'] in data['moves'] for e in learnset), key
    types = [slug(t['type']['name']) for t in sorted(pokemon['types'], key=lambda t: t['slot'])]
    abilities = [slug(a['ability']['name']) for a in sorted(pokemon['abilities'], key=lambda a: a['slot'])]
    assert all(t in data['types'] for t in types) and all(a in data['abilities'] for a in abilities), key
    stats = {slug(s['stat']['name']): s['base_stat'] for s in pokemon['stats']}
    evolutions = []
    for original in base['evolutions']:
        conditions = original.get('conditions', {}).copy()
        if conditions.get('base_form') != key:
            continue  # Never inherit the ordinary form's evolution by accident.
        record = original.copy()
        conditions.pop('base_form')
        target_form = conditions.pop('evolved_form', None)
        if target_form:
            if target_form not in regional_ids:
                continue
            record['species_id'] = target_form
        record['conditions'] = conditions
        evolutions.append(record)
    result = {k: base[k] for k in ['growth_rate', 'capture_rate']}
    result.update(id=key, display_name=name, primary_type_id=types[0],
                  secondary_type_id=types[1] if len(types) > 1 else '', type_ids=types,
                  ability_ids=abilities, ability_slots=[{'ability_id': slug(a['ability']['name']),
                  'slot': a['slot'], 'is_hidden': a['is_hidden']} for a in pokemon['abilities']],
                  base_experience=pokemon['base_experience'] or 0,
                  ev_yield={slug(s['stat']['name']): s['effort'] for s in pokemon['stats']},
                  learnset=learnset, evolutions=evolutions,
                  source_metadata={'base_species_id': slug(row['species_name']), 'regional_form': region,
                    'source_pokemon_id': pokemon['id'], 'source_sha256': sha(source),
                    'learnset_version_group': group, 'learnset_selection_reason': reason})
    for stat, value in stats.items():
        result['base_' + stat] = value
    return result


def package(job):
    key, row, shiny, pack, scale, files, display_name = job
    states, metrics, inputs = {}, {}, []
    views = {}
    for side in ('front', 'back'):
        source = Path(row['rendered'][('shiny_' if shiny else '') + side])
        expected = files[str(source)]['sha256']
        assert sha(source) == expected, f'Source changed: {source}'
        frames, durations, boxes = [], [], []
        with Image.open(source) as image:
            for i in range(image.n_frames):
                image.seek(i)
                frame = image.convert('RGBA')
                box = frame.getchannel('A').getbbox()
                assert box, f'Empty frame {source}/{i}'
                duration = int(image.info.get('duration', 0))
                if image.n_frames == 1 and duration <= 0:
                    duration = 1000
                assert duration > 0, source
                frames.append(frame); boxes.append(box); durations.append(duration / 1000)
        w, h = frames[0].size
        columns = min(len(frames), max(1, math.ceil(math.sqrt(len(frames) * h / w))))
        height = math.ceil(len(frames) / columns) * h
        assert max(columns * w, height) <= 4096, source
        atlas = Image.new('RGBA', (columns * w, height))
        regions = []
        for i, frame in enumerate(frames):
            x, y = i % columns * w, i // columns * h
            atlas.paste(frame, (x, y))
            regions.append([x, y, w, h])
        relative = f'atlases/{key}/reposo_{side}.png'
        destination = pack / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        atlas.save(destination, compress_level=3)
        pivot = [median([(b[0] + b[2]) / 2 for b in boxes]), median([b[3] for b in boxes])]
        gain = scale[side]
        bounds = [(min(b[0] for b in boxes) - pivot[0]) * gain,
                  (min(b[1] for b in boxes) - pivot[1]) * gain,
                  (max(b[2] for b in boxes) - pivot[0]) * gain,
                  (max(b[3] for b in boxes) - pivot[1]) * gain]
        views[side] = {'atlas': relative, 'sha256': sha(destination), 'dimensions': list(atlas.size),
                       'regions': regions, 'durations': durations, 'loop': True, 'pivot': pivot, 'unit_scale': gain}
        metrics[side] = {'bounds': bounds}
        inputs.append({'path': str(source), 'sha256': expected, 'frames': len(frames)})
    states['reposo'] = views
    return key, {'display_name': display_name, 'states': states, 'provisional': False,
                 'source_family': 'showdown_rendered', 'art_approved': False, 'metrics': metrics}, inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--audit', type=Path, required=True)
    parser.add_argument('--api', type=Path, required=True)
    args = parser.parse_args()
    audit = read(args.audit)
    canonical = GAME / 'data/normalized/pokemon_api.json'
    data = read(canonical)
    base_pack = GAME / 'assets/local_battle_catalog'
    base = read(base_pack / 'manifest.json')['species']
    references = read(base_pack / 'scale_reference.json')['species']
    forms = regional_rows(audit)
    assert len(forms) == 57
    ids = {slug(r['name']) for r in forms}
    definitions = {slug(r['name']): regional_definition(r, args.api, data, ids) for r in forms}
    pack = GAME / 'assets/local_battle_variants'
    pack.mkdir(parents=True, exist_ok=True)
    (pack / '.gdignore').write_text('', encoding='utf-8')
    (pack / '.gitignore').write_text('*\n!.gitignore\n!README.md\n!.gdignore\n', encoding='utf-8')
    def existing_scale(base_id):
        return {side: base[base_id]['states']['reposo'][side]['unit_scale'] *
                references.get(base_id, {}).get(side, {}).get('factor', 1) for side in ('front', 'back')}
    typical = {side: median(existing_scale(k)[side] for k in base if not base[k]['provisional']) for side in ('front', 'back')}
    jobs = []
    for row in forms:
        key = slug(row['name'])
        for shiny in (False, True):
            jobs.append((key + ('__shiny' if shiny else ''), row, shiny, pack, typical,
                         audit['files'], definitions[key]['display_name'] + (' · shiny' if shiny else '')))
    for row in audit['forms']:
        if row['default_for_species'] and row['shiny_pair']:
            key = slug(row['species_name'])
            jobs.append((key + '__shiny', row, True, pack, existing_scale(key), audit['files'], base[key]['display_name'] + ' · shiny'))
    entries, provenance = {}, {}
    with ThreadPoolExecutor(max_workers=4) as pool:
        for i, (key, entry, inputs) in enumerate(pool.map(package, jobs), 1):
            entries[key] = entry; provenance[key] = inputs
            if i % 100 == 0: print(f'VARIANTS {i}/{len(jobs)}', flush=True)
    shiny_ids = sorted(key.removesuffix('__shiny') for key in entries if key.endswith('__shiny'))
    manifest = {'version': 1, 'base_manifest_sha256': sha(base_pack / 'manifest.json'),
                'scope': '57 ordinary regional forms and existing shiny pairs only; no generated shiny',
                'entries': entries}
    write(pack / 'manifest.json', manifest)
    write(GAME / 'config/pokemon_variants_v1.json', {'version': 1, 'canonical_sha256': sha(canonical),
        'asset_manifest_sha256': sha(pack / 'manifest.json'), 'shiny_odds_denominator': 4096,
        'regional_species': definitions, 'shiny_species_ids': shiny_ids,
        'shiny_unavailable_base_species': sorted(set(base) - set(shiny_ids))})
    report = {'status': 'PASS', 'regional_forms': len(forms), 'base_shiny_pairs': len(shiny_ids) - len(forms),
              'regional_shiny_pairs': len(forms), 'visual_entries': len(entries), 'atlas_files': len(entries) * 2,
              'frames': sum(x['frames'] for rows in provenance.values() for x in rows),
              'source_audit_sha256': sha(args.audit), 'canonical_sha256': sha(canonical),
              'base_manifest_sha256': sha(base_pack / 'manifest.json'),
              'manifest_sha256': sha(pack / 'manifest.json'), 'provenance': provenance}
    write(GAME / '.godot/pokemon_variant_checks/build.json', report)
    print(json.dumps({k: v for k, v in report.items() if k != 'provenance'}), flush=True)


if __name__ == '__main__':
    main()
