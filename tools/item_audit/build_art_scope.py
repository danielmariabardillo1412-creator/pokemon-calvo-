"""Build the item-art worklist from explicit user content decisions, without changing gameplay."""
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/current'
RESEARCH = Path(r'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1')


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    protected = [ROOT / 'data/normalized/pokemon_api.json', ROOT / 'config/item_selection_v1.json']
    before = {str(p): sha(p) for p in protected}
    items = read(protected[0])['items']
    runtime = read(protected[1])
    plan = read(DOC / 'ITEM_CONTENT_SCOPE_DECISIONS.json')
    inventory = {r['id']: r for r in read(DOC / 'ITEM_INVENTORY.json')['rows']}
    assert len(items) == len(inventory) == 2222
    assert plan['status'] == 'CONTENT_AND_ART_PLAN_ONLY'
    assert set(plan['excluded_ids']) <= items.keys()
    assert set(plan['excluded_categories']) <= {x['category'] for x in items.values()}
    with (RESEARCH / 'coverage_candidates.csv').open(encoding='utf-8-sig', newline='') as f:
        art = {r['id']: r for r in csv.DictReader(f)}
    assert art.keys() == items.keys()
    rows, previous, additional = [], set(), set()
    for id, item in sorted(items.items()):
        old = runtime['excluded_ids'].get(id, runtime['excluded_categories'].get(item['category'], ''))
        new = plan['excluded_ids'].get(id, plan['excluded_categories'].get(item['category'], ''))
        if old:
            status, reason = 'EXCLUDED_EXISTING_POLICY', old
            previous.add(id)
        elif new:
            status, reason = 'EXCLUDED_FROM_ART_AND_FUTURE_CONTENT_PLAN', new
            additional.add(id)
        else:
            status, reason = 'RETAIN_FOR_FUNCTIONAL_REVIEW', ''
        rows.append({'id': id, 'name_es': item['display_name'], 'category': item['category'],
                     'family': inventory[id]['family'], 'scope': status, 'reason': reason,
                     'sv_candidate': bool(art[id]['sv_listed_file']),
                     'dw_candidate': art[id]['dream_world_exact_filename'] == 'True',
                     'other_illustration_candidate': False, 'small_sprite_style_pending': False,
                     'downloaded_image': '', 'native_entry': inventory[id]['native_entry']})
    excluded = previous | additional
    # Independent fixed expectations for this user-authorized curation, not just implementation-derived counts.
    assert len(previous) == 43 and len(additional) == 105 and len(excluded) == 148
    assert Counter(items[i]['category'] for i in additional) == {'picnic': 73, 'data_cards': 27, 'scarves': 5}
    assert all('contest' in items[i]['description'].lower() for i in additional if items[i]['category'] == 'scarves')
    assert all('pokéathlon' in items[i]['description'].lower() for i in additional if items[i]['category'] == 'data_cards')
    for id in plan['protected_examples'] + plan['deferred_examples']:
        assert id in items and id not in excluded, id
    # Explicit traps: category contains real evolution items; an item-name resemblance is not a safe ban.
    assert items['auspicious_armor']['category'] == items['leaders_crest']['category'] == 'picnic'
    assert 'choice_scarf' not in excluded and items['choice_scarf']['category'] != 'scarves'
    assert 'poke_doll' not in excluded and items['poke_doll']['description'] == 'Ends a wild battle.'
    assert 'bottle_cap' not in excluded and items['bottle_cap']['category'] == 'loot'
    assert set(read(DOC / 'ITEM_ART_PILOT.json')['ids']).isdisjoint(excluded)
    retained = [r for r in rows if r['id'] not in excluded]
    def coverage(rs):
        return {'total': len(rs), 'sv_candidates': sum(r['sv_candidate'] for r in rs),
                'sv_or_dw_candidates': sum(r['sv_candidate'] or r['dw_candidate'] for r in rs),
                'neither_source_matched_yet': sum(not r['sv_candidate'] and not r['dw_candidate'] for r in rs),
                'any_illustration_candidate': sum(r['sv_candidate'] or r['dw_candidate'] or r['other_illustration_candidate'] for r in rs),
                'without_any_illustration_candidate': sum(not (r['sv_candidate'] or r['dw_candidate'] or r['other_illustration_candidate']) for r in rs)}
    core_families = ['BERRY', 'HELD_COMBAT_CANDIDATE', 'CAPTURE_BALL', 'MEDICINE', 'EVOLUTION']
    core = [r for r in retained if r['family'] in core_families]
    assert len(core) == 359 and sum(not r['sv_candidate'] for r in core) == 69
    # Preserve the old metadata baseline, then apply independently downloaded, named-page gap evidence.
    gap_file = DOC / 'ITEM_ART_GAPS_V1.json'
    gap_evidence = None
    if gap_file.exists():
        gap_evidence = read(gap_file)
        gaps = {r['id']: r for r in gap_evidence['rows']}
        assert len(gaps) == 40 and set(gaps) == {r['id'] for r in core if not r['sv_candidate'] and not r['dw_candidate']}
        for r in core:
            if r['id'] not in gaps: continue
            g = gaps[r['id']]
            assert sha(Path(g['file'])) == g['sha256']
            r['downloaded_image'] = g['file']
            if g['status'] == 'EXISTING_ILLUSTRATION_FOUND':
                assert min(g['width'], g['height']) >= 79
                r['sv_candidate'] = g['source_style'] == 'SV'
                r['dw_candidate'] = g['source_style'] == 'GLOBAL_LINK'
                r['other_illustration_candidate'] = g['source_style'] == 'LEGENDS_ARCEUS'
                assert r['sv_candidate'] or r['dw_candidate'] or r['other_illustration_candidate']
            else:
                assert g['id'] == 'pewter_crunchies' and g['status'] == 'SMALL_SPRITE_ONLY_STYLE_PENDING'
                r['small_sprite_style_pending'] = True
        assert coverage(core)['without_any_illustration_candidate'] == 1
    expansion_path = DOC / 'ITEM_ART_EXPANSION_V2_PLAN.json'
    expansion_excluded = {}
    if expansion_path.exists():
        expansion = read(expansion_path)
        expansion_excluded = expansion['excluded_art_ids']
        assert len(expansion_excluded) == 6 and set(expansion_excluded) <= items.keys()
        assert not set(expansion_excluded) & excluded
        for r in rows:
            if r['id'] in expansion_excluded:
                assert r['family'] in ['Z_CRYSTAL', 'Z_BAG_TOKEN']
                r['scope'] = 'EXCLUDED_BY_EXISTING_MOVE_AND_FORM_RULES'
                r['reason'] = expansion_excluded[r['id']]
        excluded |= set(expansion_excluded)
        retained = [r for r in rows if r['id'] not in excluded]
    utility_path = DOC / 'ITEM_ART_UTILITY_V3_PLAN.json'
    utility_excluded = {}
    if utility_path.exists():
        utility = read(utility_path)
        utility_excluded = utility['excluded_art_ids']
        assert set(utility_excluded) == {'leaf_letter_eevee', 'leaf_letter_pikachu'}
        assert not set(utility_excluded) & excluded
        for r in rows:
            if r['id'] in utility_excluded:
                r['scope'] = 'EXCLUDED_DECORATIVE_PARTNER_LETTER'
                r['reason'] = utility_excluded[r['id']]
        excluded |= set(utility_excluded)
        retained = [r for r in rows if r['id'] not in excluded]
    report = {'status': 'PASS', 'date': plan['date'], 'phase': 'ITEM_ART_SCOPE_V1',
              'scope': plan['scope'], 'canonical_count': len(items),
              'previous_exclusions': len(previous), 'additional_exclusions': len(additional),
              'total_art_plan_exclusions': len(excluded), 'additional_category_counts': dict(Counter(items[i]['category'] for i in additional)),
              'retained_for_review': coverage(retained), 'excluded_additional_art': coverage([r for r in rows if r['id'] in additional]),
              'five_functional_families': {**coverage(core), 'without_sv_match': sum(not r['sv_candidate'] for r in core)},
              'runtime_selection_policy_unchanged': True,
              'runtime_note': '105 new exclusions are recorded in the art/content plan only. Existing runtime guard retains 43 bans; no new loot/shop pool is enabled.',
              'limitations': ['Retained means eligible for review, not approved final content or implemented mechanics.',
                             'Source filename matches are art candidates, not proof that all images were downloaded/visually approved.',
                             'The initial five-family baseline had 69 unmatched SV entries and 40 without SV/DW matches; subsequent gap evidence is applied separately when present.',
                             'Blank descriptions, missing art, absent callbacks and low competitive use are not grounds for exclusion.'],
              'sources_sha256': {str(p.relative_to(ROOT)): sha(p) for p in [*protected, DOC / 'ITEM_CONTENT_SCOPE_DECISIONS.json', DOC / 'ITEM_INVENTORY.json']},
              'art_metadata_sha256': sha(RESEARCH / 'coverage_candidates.csv'), 'rows': rows}
    if expansion_excluded:
        report['expansion_art_exclusions'] = {'count': 6, 'decisions': 'docs/current/ITEM_ART_EXPANSION_V2_PLAN.json', 'sha256': sha(expansion_path)}
    if utility_excluded:
        report['utility_art_exclusions'] = {'count': 2, 'decisions': 'docs/current/ITEM_ART_UTILITY_V3_PLAN.json', 'sha256': sha(utility_path)}
    installed_manifest = ROOT / 'assets/local_item_catalog/manifest.json'
    if installed_manifest.exists():
        installed = read(installed_manifest)['items']
        assert set(installed).isdisjoint(excluded)
        report['installed_beta_art'] = {'entries': len(installed), 'manifest': 'assets/local_item_catalog/manifest.json', 'sha256': sha(installed_manifest)}
    if gap_evidence:
        report['gap_resolution'] = {'report': 'docs/current/ITEM_ART_GAPS_V1.json', 'sha256': sha(gap_file),
                                    'original_group': 40, 'illustrations_downloaded': 39, 'style_pending_ids': ['pewter_crunchies']}
    with (DOC / 'ITEM_ART_SCOPE.csv').open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    (DOC / 'ITEM_ART_SCOPE.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    assert before == {str(p): sha(p) for p in protected}
    print(json.dumps({k: v for k, v in report.items() if k not in ['rows', 'sources_sha256', 'limitations']}, ensure_ascii=True))


if __name__ == '__main__':
    main()
