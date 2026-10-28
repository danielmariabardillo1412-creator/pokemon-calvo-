"""Install reviewed artwork only; preserve existing art, gameplay data and selection policy."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/current'
ASSETS = ROOT / 'assets/local_item_catalog'
EVIDENCE = ROOT / '.godot/item_art_reviewed_v5'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write(p, d):
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    review = read(DOC / 'ITEM_ART_REVIEW_V4.json')
    generated = read(ROOT / 'art_review/item_icons_generated_completion_v1/review.json')['items']
    scope = {r['id']: r for r in read(DOC / 'ITEM_ART_SCOPE.json')['rows']}
    candidates = review['reviewed_source_candidates']
    assert len(candidates) == 350 and len(generated) == 7
    targets = set(candidates) | set(generated)
    assert len(targets) == 357 and all(scope[k]['scope'] == 'RETAIN_FOR_FUNCTIONAL_REVIEW' for k in targets)
    manifest = read(ASSETS / 'manifest.json')
    EVIDENCE.mkdir(exist_ok=True)
    if not (EVIDENCE / 'before_manifest.json').exists():
        assert len(manifest['items']) == 654 and not targets.intersection(manifest['items'])
        write(EVIDENCE / 'before_manifest.json', manifest)
        protected = ['data/raw/pokemon_api.json', 'data/normalized/pokemon_api.json', 'config/item_selection_v1.json', 'config/randomlock_content_v1.json', 'scenes/visual/showdown_adventure_lab.gd', 'scenes/visual/pokemon_gallery.gd']
        write(EVIDENCE / 'before.json', {p: sha(ROOT / p) for p in protected})
    before = read(EVIDENCE / 'before_manifest.json')
    assert len(before['items']) == 654
    for k, row in before['items'].items():
        assert manifest['items'][k] == row and sha(ROOT / row['texture'].removeprefix('res://')) == row['sha256']
    plan = {'schema_version': 1, 'phase': 'ITEM_ART_REVIEWED_V5', 'date': '2026-10-28', 'prior_items': 654, 'target_ids': sorted(targets), 'source_ids': sorted(candidates), 'generated_ids': sorted(generated), 'expected_new_entries': 357, 'expected_total_entries': 1011, 'excluded_art_ids': [k for k, v in scope.items() if v['scope'] != 'RETAIN_FOR_FUNCTIONAL_REVIEW'], 'conditional_small_reference_ids': sorted(review['conditional_style_queue']), 'scope': 'Visual catalog registration only; content eligibility and supported item effects are unchanged.'}
    assert len(plan['excluded_art_ids']) == 156 and not targets.intersection(plan['conditional_small_reference_ids'])
    write(DOC / 'ITEM_ART_REVIEWED_V5_PLAN.json', plan)
    rows = {}
    for item_id, row in candidates.items():
        assert row['review_status'] == 'SOURCE_IMAGE_VISUALLY_REVIEWED_CONTENT_PENDING'
        rows[item_id] = {k: row[k] for k in ['display_name', 'family', 'source', 'url', 'page', 'width', 'height', 'sha256', 'bytes', 'small_fallback', 'historical_review']}
        rows[item_id]['_source_file'] = row['file']
        rows[item_id]['mechanic_note'] = 'Ilustración del catálogo beta; su inclusión no habilita efectos ni aparición en la partida.'
        if item_id in {'rotom_phone', 'roto_stick', 'rotom_catalog', 'dna_splicers', 'teal_style_card'}:
            rows[item_id]['historical_review'] = True
    for item_id, row in generated.items():
        selected = ROOT / row['selected_file']
        assert sha(selected) == row['sha256']
        reference = ROOT / row['original_file']
        rows[item_id] = {'display_name': scope[item_id]['name_es'], 'family': scope[item_id]['family'], 'source': 'GENERATED', 'url': '', 'page': '', 'width': 160, 'height': 160, 'sha256': row['sha256'], 'bytes': selected.stat().st_size, 'small_fallback': False, 'historical_review': False, 'generated_reference_sha256': sha(reference), 'generated_reference': 'res://' + row['original_file'], 'generation_prompts': 'res://art_review/item_icons_generated_pilot_v1/prompts_v2.json' if item_id in {'armorite_ore', 'lure'} else 'res://art_review/item_icons_generated_completion_v1/prompts.json', 'mechanic_note': 'Arte generado para la beta a partir del icono original; no habilita efectos del objeto.', '_source_file': str(selected)}
    for item_id, row in rows.items():
        src = Path(row.pop('_source_file'))
        assert sha(src) == row['sha256']
        with Image.open(src) as image:
            image.load()
            assert image.size == (row['width'], row['height']) and image.convert('RGBA').getchannel('A').getbbox()
        dest = ASSETS / 'icons' / (item_id + '.png')
        if dest.exists():
            assert sha(dest) == row['sha256']
        else:
            shutil.copyfile(src, dest)
        row['texture'] = 'res://assets/local_item_catalog/icons/' + item_id + '.png'
        if item_id in manifest['items']:
            assert manifest['items'][item_id] == row
        manifest['items'][item_id] = row
    assert len(manifest['items']) == 1011
    manifest['scope'] = '1011 beta item-art entries. Visual registration never enables item mechanics or approves final content.'
    manifest['art_batches'] = [b for b in manifest.get('art_batches', []) if b['phase'] != plan['phase']] + [{'phase': plan['phase'], 'entries': 357, 'existing_source_entries': 350, 'generated_entries': 7}]
    credit = 'Seven beta item illustrations generated with image_gen using original small item icons as identity references; original Pokemon designs: Nintendo / Creatures / GAME FREAK.'
    if credit not in manifest['credits']:
        manifest['credits'].append(credit)
    write(ASSETS / 'manifest.json', manifest)
    cp = ASSETS / 'CREDITS.md'
    text = cp.read_text(encoding='utf-8').replace('Se conserva el arte sin redibujar.', 'Las ilustraciones de fuentes existentes conservan sus bytes originales. Siete entradas se identifican explícitamente como arte generado para la beta.')
    if 'Siete ilustraciones generadas' not in text:
        text += '\nSiete ilustraciones generadas con image_gen: Duralium, Hoja de Oro, Hoja de Plata, Colonia, Supercolonia, Colonia Máxima y Trozo Deseo. Referencias originales y prompts conservados en art_review/. Son reinterpretaciones para la beta, no ilustraciones oficiales recuperadas.\n'
    cp.write_text(text, encoding='utf-8')
    assert all(sha(ROOT / p) == value for p, value in read(EVIDENCE / 'before.json').items())
    result = {'status': 'INSTALLED_PENDING_GODOT_CHECKS', 'phase': plan['phase'], 'previous_entries_preserved': 654, 'new_entries': 357, 'total_entries': 1011, 'sources_added': dict(Counter(row['source'] for row in rows.values())), 'new_bytes': sum(row['bytes'] for row in rows.values()), 'manifest_sha256': sha(ASSETS / 'manifest.json')}
    write(EVIDENCE / 'install.json', result)
    print(json.dumps(result))


if __name__ == '__main__':
    main()
