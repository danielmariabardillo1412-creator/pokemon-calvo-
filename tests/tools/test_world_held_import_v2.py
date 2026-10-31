"""Tests for the O120 world-held import.

Validates the compiled Smoke Ball metadata against the pinned sources and the
authorized scope: one row, no neutral cleansing descriptors, pinned generation.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/item_import'))
import import_world_held_v2 as importer

PROFILE = ROOT / 'modules/battle/backends/showdown/field_world_items_v2.json'


def test_profile_matches_compiled_rows():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    compiled = importer.build()
    assert stored == compiled, 'field_world_items_v2.json is not the pinned compilation'


def test_exact_scope():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    assert set(stored['items']) == {'smokeball'}, 'unexpected rows'
    row = stored['items']['smokeball']
    assert row['name'] == 'Smoke Ball' and row['gen'] == 2 and row['fling']['basePower'] == 30
    # Cleanse Tag / Pure Incense must not be registered as neutral battle metadata.
    assert 'cleansetag' not in stored['items'] and 'pureincense' not in stored['items']
    assert 'cleanse_tag' not in stored['items'] and 'pure_incense' not in stored['items']


def test_sources_are_pinned():
    stored = json.loads(PROFILE.read_text(encoding='utf-8'))
    assert stored['source_sha256']['items.h'] == importer.RHH_ITEMS_SHA256
    assert stored['generation_source_sha256'] == importer.GEN_SOURCES


if __name__ == '__main__':
    test_profile_matches_compiled_rows()
    print('PASS: test_profile_matches_compiled_rows')
    test_exact_scope()
    print('PASS: test_exact_scope')
    test_sources_are_pinned()
    print('PASS: test_sources_are_pinned')
    print('All world-held import tests passed.')
