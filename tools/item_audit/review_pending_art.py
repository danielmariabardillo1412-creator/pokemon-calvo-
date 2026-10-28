"""Prepare a bounded source-art review batch; never install art or enable items."""
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import importlib.util
import json
from pathlib import Path
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = Path(r'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1')
OUT = RESEARCH / 'review_batch_v4'
DOC = ROOT / 'docs/current'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def main():
    OUT.mkdir(exist_ok=True)
    spec = importlib.util.spec_from_file_location('item_source_resolver', RESEARCH / 'prepare_expansion_v2.py')
    resolver = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(resolver)
    resolver.OUT = OUT

    def fetch(url, path):
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            payload = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Pokemon Calvo art review)'}), timeout=12).read()
            path.write_bytes(payload)
        return path.read_bytes()

    resolver.fetch = fetch
    coverage = read(DOC / 'ITEM_ART_COVERAGE_AUDIT_V1.json')
    deferred_families = {'MACHINE', 'RAID_EVENT_CRYSTAL'}
    targets = [row['id'] for row in coverage['rows'] if row['art_state'] == 'CONTENT_REVIEW_WITHOUT_PREPARED_ART' and row['family'] not in deferred_families]
    assert len(targets) == 768
    prior_path = OUT / 'candidates.json'
    results = {row['id']: row for row in read(prior_path)['rows']} if prior_path.exists() else {}
    pending = [item_id for item_id in targets if item_id not in results]

    def save():
        rows = [results[item_id] for item_id in sorted(results)]
        summary = {'status': 'SOURCE_SCAN_COMPLETE' if len(rows) == len(targets) else 'SOURCE_SCAN_RUNNING', 'phase': 'ITEM_ART_REVIEW_V4', 'date': '2026-10-28', 'target_count': len(targets), 'completed': len(rows), 'ready_candidate_count': sum(row['status'] == 'READY' for row in rows), 'unresolved_count': sum(row['status'] != 'READY' for row in rows), 'sources': dict(Counter(row.get('source', 'NONE') for row in rows)), 'scope': 'Source candidates only. Content eligibility and visual review are separate. No art installed, no items banned, no mechanics changed.'}
        (OUT / 'progress.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
        prior_path.write_text(json.dumps({**summary, 'target_ids': targets, 'rows': rows}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        return summary

    print(json.dumps(save()), flush=True)
    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = {pool.submit(resolver.asset, item_id): item_id for item_id in pending}
        for future in as_completed(futures):
            item_id = futures[future]
            try:
                results[item_id] = future.result()
            except Exception as error:
                results[item_id] = {'id': item_id, 'status': 'UNRESOLVED', 'errors': [{'error': str(error)}]}
            if len(results) % 25 == 0:
                print(json.dumps(save()), flush=True)
    print(json.dumps(save()), flush=True)


if __name__ == '__main__':
    main()
