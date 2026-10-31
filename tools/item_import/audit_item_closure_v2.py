#!/usr/bin/env python3
"""
O100/O190 Item Closure V2 audit - deterministic per-context coverage of the
2,222 canonical item IDs.

The audit never writes one judgment per ID by hand. It reads the canonical
catalog, the selection policy, the current connection matrix, the reviewed art
coverage, the native field definitions and the fixed evidence reports, then
derives one state per context plus the concrete dependency/evidence for that
ID. Presence is deliberately not treated as effect certification.

Contexts: permission, art, equip, native metadata, field use, battle use,
evolution, machine and executed scenario. Every context has an explicit state
from the contract vocabulary and a source. The overall state is derived from
the applicable effect contexts; UNKNOWN_REQUIRES_REVIEW is only a data-error
fallback (the current audit must resolve it to zero rows).

Usage:
    python tools/item_import/audit_item_closure_v2.py            # write files
    python tools/item_import/audit_item_closure_v2.py --check    # compare
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_JSON = ROOT / 'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.json'
OUT_CSV = ROOT / 'docs/opencode/ITEM_CLOSURE_V2/COVERAGE.csv'

CANON = ROOT / 'data/normalized/pokemon_api.json'
POLICY = ROOT / 'config/item_selection_v1.json'
CONNECTIONS = ROOT / 'modules/inventory/item_connections_v1.json'
V8_CSV = ROOT / 'docs/current/ITEM_FIELD_V8.csv.txt'
ART = ROOT / 'docs/current/ITEM_ART_COVERAGE_V5.json'
V18 = ROOT / 'docs/current/ITEM_PROGRESSION_V18.json'
V19_AUDIT = ROOT / 'docs/current/ITEM_IMPORT_V19_AUDIT.json'
V20 = ROOT / 'docs/current/ITEM_FIELD_HELD_V20.json'
V21 = ROOT / 'docs/current/ITEM_ESCAPE_V21.json'
CAPTURE_V11 = ROOT / 'docs/current/ITEM_CAPTURE_V11.json'
CAPTURE_V12 = ROOT / 'docs/current/ITEM_CAPTURE_V12.json'
CAPTURE_V15 = ROOT / 'docs/current/ITEM_CAPTURE_V15.json'
SYSTEM = ROOT / 'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json'
SUPPORT_PROFILE = ROOT / 'modules/inventory/battle_support_profile.json'
MEDICINE_PROFILE = ROOT / 'modules/inventory/battle_medicine_profile.json'
FIELD_HELD = ROOT / 'modules/battle/backends/showdown/field_held_items.cjs'
FIELD_MISC = ROOT / 'modules/battle/backends/showdown/field_misc_items_v20.json'
FIELD_WORLD = ROOT / 'modules/battle/backends/showdown/field_world_items_v2.json'

STATES = (
    'IMPLEMENTED_VERIFIED', 'IMPLEMENTED_UNVERIFIED', 'PARTIAL_VERIFIED',
    'DEPENDENCY_MISSING', 'EXCLUDED', 'NOT_APPLICABLE',
    'UNKNOWN_REQUIRES_REVIEW',
)

# Explicit reviewed evidence sets. These are IDs, never a whole family: the
# matrix may contain an item without certifying its effect.
FIELD_RECOVERY_V19 = set()
FIELD_TRAINING_PARTIAL = {
    # V8/V13 field training routes: base route verified, origin/Luxury
    # friendship bonus, SV mochi parity or ability form route still pending.
    'calcium', 'carbos', 'clever_wing', 'genius_wing', 'health_wing', 'hp_up',
    'iron', 'muscle_wing', 'protein', 'resist_wing', 'swift_wing', 'zinc',
    'grepa_berry', 'hondew_berry', 'kelpsy_berry', 'pomeg_berry', 'qualot_berry',
    'tamato_berry', 'pp_max', 'pp_up',
    'health_mochi', 'muscle_mochi', 'resist_mochi', 'genius_mochi',
    'clever_mochi', 'swift_mochi', 'fresh_start_mochi',
    'ability_capsule', 'ability_patch',
    'rare_candy', 'exp_candy_xs', 'exp_candy_s', 'exp_candy_m',
    'exp_candy_l', 'exp_candy_xl',
}
FIELD_HELD_FRIENDSHIP_PARTIAL = {
    # Soothe Bell is a held modifier on the verified base friendship gain:
    # field_friendship_effects.gd applies x3/2 while the held item is active.
    # It is not one of the 35 field-training consumable rows.
    'soothe_bell',
}
HELD_EV_PENDING = {
    # Native metadata only: the held EV-gain multiplier is not implemented in
    # calvo_progression_v1, so this is a concrete missing effect, not a test gap.
    'macho_brace', 'power_anklet', 'power_band', 'power_belt',
    'power_bracer', 'power_lens', 'power_weight',
}
FIELD_HELD_TRAINING = {
    # Held training items: no direct bag/field use; the battle/progression
    # context owns their effect.
    'amulet_coin', 'cleanse_tag', 'exp_share', 'everstone', 'luck_incense',
    'lucky_egg', 'pure_incense', 'soothe_bell', 'macho_brace', 'power_anklet',
    'power_band', 'power_belt', 'power_bracer', 'power_lens', 'power_weight',
}
SUPPORT_IDS_V2 = set()
HELD_VERIFIED_V8 = set()
MEDICINE_BATTLE_V8 = set()
CAPTURE_VERIFIED = set()
ESCAPE_V21 = set()
PROGRESSION_V18 = set()
SCENARIO_V8 = set()
SCENARIO_PARTIAL = set()
MACHINE_VERIFIED = set()
EVOLUTION_VERIFIED = set()
EVOLUTION_PARTIAL = set()
EVOLUTION_DEPENDENCY = set()

NATIVE_DEFINITION_IDS = set()
ART_ROWS = {}
V8_ROWS = {}
FIELD_OVERRIDES = {}
MACHINE_ROWS = {}
SYSTEM_COUNTERS = {}

FIELD_FULL_STATUSES = {
    'TEACH_AND_CONSUMPTION_VERIFIED',
    'BAG_EVOLUTION_VERIFIED_WITH_SUPPORTED_TARGETS',
    'MODERN_FIELD_RECOVERY_OWNERSHIP_CONSUMPTION_SAVE_AND_NATIVE_HANDOFF_VERIFIED',
    'MEDICINE_FIELD_USE_OWNERSHIP_CONSUMPTION_AND_SAVE_VERIFIED',
    'BITTER_MEDICINE_HP_STATUS_FRIENDSHIP_CONSUMPTION_SAVE_NATIVE_VERIFIED',
}
FIELD_PARTIAL_STATUSES = {
    'EV_TRAINING_STAT_CAP_TOTAL_CAP_BASE_FRIENDSHIP_SAVE_NATIVE_VERIFIED_ORIGIN_BONUS_PENDING',
    'EV_BERRY_FIELD_USE_AND_BASE_FRIENDSHIP_VERIFIED_ORIGIN_BONUS_PENDING',
    'PP_BOOST_SELECTED_MOVE_CAP_BASE_FRIENDSHIP_SAVE_NATIVE_VERIFIED_ORIGIN_BONUS_PENDING',
}
FIELD_NA_STATUSES = {
    'HELD_OR_BATTLE_ACTION_ITEM_NOT_DIRECT_FIELD_USE',
    'BATTLE_CAPTURE_ITEM_NOT_DIRECT_FIELD_USE',
    'CONTENT_EXCLUDED',
}
FIELD_DEPENDENCY_REASONS = {
    'STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED': 'Story/form/side-mode system absent for this ID.',
    'RAID_SYSTEM_NOT_ACTIVE': 'Raid/Dynamax crystal system is inactive.',
    'CRAFTING_SYSTEM_CONTEXT_NEEDED': 'Crafting/TM-material system absent.',
    'FOOD_GROWING_OR_CRAFTING_CONTEXT_NEEDED': 'Food/picnic/growing/crafting system absent.',
    'SELL_TRADE_OR_TRAINING_CONTEXT_NEEDED': 'Sell/trade/training context absent.',
    'BAG_TO_HELD_ROUTE_NEEDS_CONTEXT': 'Z-Move bag-to-held route absent.',
    'TRADE_OR_OTHER_EVOLUTION_CONTEXT_NEEDED': 'Trade/other evolution context absent.',
    'TERA_TYPE_CHANGE_SYSTEM_NEEDED': 'Tera type-change system absent.',
    'DEPENDENCY_OR_EVOLUTION_CONTEXT_MISSING': 'Evolution dependency/context missing.',
    'NEEDS_DUNGEON_EXIT_AND_ROPE_RULES': 'Dungeon exit/Escape Rope rules absent.',
    'NEEDS_MACHINE_VERSION_PROFILE': 'Legacy machine version/profile needed.',
    'FIELD_USE_NOT_CONNECTED': 'No verified field-use route.',
}
BATTLE_DEPENDENCY_REASONS = {
    'EXPLICIT_DEPENDENCY_OR_NONBATTLE_CONTEXT_PENDING': 'Scoped battle/special-action context missing (memory, form, baking or breeding route).',
    'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING': 'Native presence only; effect scenario not executed for this ID.',
}
GAP_DEPENDENCIES = {
    'amulet_coin': 'Native descriptor absent; Amulet Coin money-reward multiplier has no battle/economy implementation.',
    'cleanse_tag': 'Native descriptor absent; encounter-rate copy is implemented and tested as PARTIAL_VERIFIED_RATE_ONLY; step-period semantics are not representable in the current profile.',
    'exp_share': 'Native descriptor absent; Exp. Share distribution profile coherent with calvo_progression_v1 is not implemented.',
    'linking_cord': 'Native descriptor absent; explicit trade-evolution route is not implemented and canonical evolution data is unchanged.',
    'luck_incense': 'Native descriptor absent; money/breeding Luck Incense route is not implemented.',
    'pure_incense': 'Native descriptor absent; encounter-rate copy is implemented and tested as PARTIAL_VERIFIED_RATE_ONLY; step-period semantics are not representable in the current profile.',
    'smoke_ball': 'Native descriptor is present; the guaranteed Run rule is implemented at the AdventureSession boundary.',
}
# Families whose only use is a system that does not exist in this profile.
SYSTEM_DEPENDENCY_FAMILIES = {
    'MEGA_STONE': 'Mega Evolution system absent.',
    'Z_CRYSTAL': 'Z-Move system absent.',
    'Z_BAG_TOKEN': 'Z-Move bag route absent.',
    'RAID_EVENT_CRYSTAL': 'Raid/Dynamax system inactive.',
    'TERA_MATERIAL': 'Tera type-change system absent.',
    'FOOD_OR_PICNIC_ACTIVITY': 'Food/picnic/cooking system absent.',
    'GROWING_OR_CRAFTING': 'Growing/crafting system absent.',
    'MACHINE_CRAFTING_MATERIAL': 'Crafting/TM-material system absent.',
    'TREASURE_OR_COLLECTIBLE': 'Sell/trade context absent.',
    'STORY_KEY_OR_FORM_REVIEW': 'Story/form system absent.',
    'SIDE_MODE_ITEM': 'Side-mode system absent.',
    'SIDE_ACTIVITY_ACCESSORY': 'Contest/side-activity system absent.',
    'SPECIES_SPECIFIC_TRAINING': 'Species-specific candy system absent.',
}
NOT_APPLICABLE_FAMILIES = {
    'LEGACY_OR_CATEGORY_REVIEW', 'SIDE_ACTIVITY_RECORD', 'MAIL',
}


def load(path: Path):
    with path.open(encoding='utf-8') as stream:
        return json.load(stream)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def normalise_id(value: str) -> str:
    return re.sub(r'[^a-z0-9]', '', value.lower())


def parse_definition_ids() -> set[str]:
    """Return the IDs registered by field_held_items.cjs from its real sources."""
    text = FIELD_HELD.read_text(encoding='utf-8')
    keys = set(re.findall(r'^\s*([a-z0-9]+):medicine\(', text, re.M))
    keys |= set(re.findall(r'^\s*([a-z0-9]+):Object\.freeze', text, re.M))
    for path in (FIELD_MISC, FIELD_WORLD):
        keys |= set(load(path)['items'].keys())
    return keys


def load_sources() -> None:
    global NATIVE_DEFINITION_IDS, ART_ROWS, V8_ROWS, FIELD_OVERRIDES, MACHINE_ROWS, SYSTEM_COUNTERS
    api = load(CANON)
    canonical: dict = api['items']
    policy = load(POLICY)
    connections = load(CONNECTIONS)
    holdable = set(connections['holdable_ids'])
    MACHINE_ROWS.update(connections['machine_rows'])
    assert len(MACHINE_ROWS) == 338, len(MACHINE_ROWS)
    excluded = set(policy.get('excluded_ids', []))
    excluded_categories = set(policy.get('excluded_categories', []))
    excluded |= {item_id for item_id, row in canonical.items()
                 if row.get('category', '') in excluded_categories}
    # The source of truth for "permitted" is holdable minus content exclusion.
    permitted = holdable - excluded
    assert len(canonical) == 2222, len(canonical)
    assert len(holdable) == 631, len(holdable)
    assert len(excluded) == 43, len(excluded)
    assert len(permitted) == 625, len(permitted)

    with V8_CSV.open(encoding='utf-8', newline='') as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == 2222, len(rows)
    V8_ROWS = {row['id']: row for row in rows}

    art = load(ART)
    assert art['canonical_entries'] == 2222, art['canonical_entries']
    ART_ROWS = {row['id']: row for row in art['rows']}
    assert len(ART_ROWS) == 2222, len(ART_ROWS)

    canonical_by_normal = {normalise_id(item_id): item_id for item_id in canonical}
    base_native = {item_id for item_id, row in V8_ROWS.items()
                   if row['native_definition_present'] == 'True'}
    custom_native = {canonical_by_normal[key] for key in parse_definition_ids()
                     if key in canonical_by_normal}
    NATIVE_DEFINITION_IDS = base_native | custom_native
    assert len(NATIVE_DEFINITION_IDS & permitted) == 619, len(NATIVE_DEFINITION_IDS & permitted)
    assert sorted(permitted - NATIVE_DEFINITION_IDS) == [
        'amulet_coin', 'cleanse_tag', 'exp_share', 'linking_cord',
        'luck_incense', 'pure_incense',
    ]

    system = load(SYSTEM)
    SYSTEM_COUNTERS = {
        'permitted': 625,
        'native_present': 619,
        'native_missing': 6,
        'field_effect_total': 77,
        'field_recovery_verified': 42,
        'field_training_verified': 35,
        'medicine_battle_ids': 15,
        'capture_ball_ids': 16,
        'machine_ids': 338,
        'machine_verified': 229,
        'machine_pending': 109,
        'evolution_supported': 57,
        'evolution_other': 15,
        'evolution_item_ids': 26,
        'held_effect_scenarios': 189,
        'art_installed': 1011,
        'art_without_prepared': 1055,
        'art_excluded': 156,
    }
    assert system['canonical_entries_audited'] == 2222
    assert system['equipment_transfers_verified'] == 625
    assert system['evolution_item_routes_verified'] == 57
    assert system['evolution_conditioned_or_form_routes_deferred'] == 15
    assert system['machine_ids_mapped'] == 338
    assert system['machine_teaching_ids_verified'] == 229
    assert system['field_recovery_ids_verified'] == 42
    assert system['field_training_ids_verified'] == 35
    assert system['total_connected_field_effect_ids'] == 77
    assert system['capture_ball_ids_connected'] == 16
    assert system['held_item_ids_with_verified_effect_scenarios'] == 189

    FIELD_OVERRIDES = dict(system.get('field_use_overrides', {}))
    assert len(FIELD_OVERRIDES) == 16, len(FIELD_OVERRIDES)

    v18 = load(V18)
    PROGRESSION_V18.update(v18['progression_held_effect_ids_verified'])
    assert PROGRESSION_V18 == {'lucky_egg', 'everstone'}

    v19 = load(V19_AUDIT)
    FIELD_RECOVERY_V19.update(v19['compiled_ids'])
    assert len(FIELD_RECOVERY_V19) == 42, len(FIELD_RECOVERY_V19)

    v21 = load(V21)
    ESCAPE_V21.update(v21['new_battle_item_use_ids'])
    assert ESCAPE_V21 == {'poke_doll', 'fluffy_tail', 'poke_toy'}, ESCAPE_V21

    support = load(SUPPORT_PROFILE)
    SUPPORT_IDS_V2.update(support['items'].keys())
    assert len(SUPPORT_IDS_V2) == 11, len(SUPPORT_IDS_V2)

    medicine = load(MEDICINE_PROFILE)
    MEDICINE_BATTLE_V8.update(medicine['items'].keys())
    assert len(MEDICINE_BATTLE_V8) == 15, len(MEDICINE_BATTLE_V8)

    capture = {'great_ball', 'master_ball', 'poke_ball', 'ultra_ball'}
    for path in (CAPTURE_V11, CAPTURE_V12, CAPTURE_V15):
        capture |= set(load(path)['new_ids'])
    CAPTURE_VERIFIED.update(capture)
    assert len(CAPTURE_VERIFIED) == 16, len(CAPTURE_VERIFIED)

    for item_id, row in V8_ROWS.items():
        status = row['battle_effect_status']
        if status == 'HELD_EFFECT_SCENARIOS_VERIFIED_NOT_EXHAUSTIVE':
            HELD_VERIFIED_V8.add(item_id)
        elif status == 'MEDICINE_BATTLE_GROUP_REVERIFIED':
            MEDICINE_BATTLE_V8.add(item_id)
        elif status == 'BASIC_CAPTURE_GROUP_REVERIFIED':
            CAPTURE_VERIFIED.add(item_id)
        if (int(row['new_effect_scenarios'] or 0) > 0
                or row['live_ipc_case'] == 'True'
                or int(row['v3_scenarios'] or 0) > 0):
            SCENARIO_V8.add(item_id)
        if row['field_use_status'] == 'TEACH_AND_CONSUMPTION_VERIFIED':
            MACHINE_VERIFIED.add(item_id)
        supported = int(row['supported_evolution_routes_tested'] or 0)
        other = int(row['other_evolution_routes'] or 0)
        if supported > 0 and other == 0:
            EVOLUTION_VERIFIED.add(item_id)
        elif supported > 0 and other > 0:
            EVOLUTION_PARTIAL.add(item_id)
        elif other > 0:
            EVOLUTION_DEPENDENCY.add(item_id)
    assert len(HELD_VERIFIED_V8) == 189, len(HELD_VERIFIED_V8)
    assert len(MACHINE_VERIFIED) == 229, len(MACHINE_VERIFIED)
    assert len(EVOLUTION_VERIFIED) + len(EVOLUTION_PARTIAL) + len(EVOLUTION_DEPENDENCY) == 26
    assert sum(int(row['supported_evolution_routes_tested'] or 0) for row in rows) == 57
    assert sum(int(row['other_evolution_routes'] or 0) for row in rows) == 15

    # Whole-matrix counts that the O190 closure must reconcile.
    assert sum(1 for row in V8_ROWS.values() if row['equipment_transfer'] == 'VERIFIED') == 625
    assert sum(1 for row in V8_ROWS.values() if row['field_use_status'] == 'CONTENT_EXCLUDED') == 43
    assert sum(1 for row in V8_ROWS.values()
               if row['field_use_status'] == 'TEACH_AND_CONSUMPTION_VERIFIED') == 229
    assert sum(1 for row in V8_ROWS.values()
               if row['field_use_status'] == 'NEEDS_MACHINE_VERSION_PROFILE') == 109

    SCENARIO_PARTIAL.update(FIELD_TRAINING_PARTIAL)
    SCENARIO_PARTIAL.update(FIELD_HELD_FRIENDSHIP_PARTIAL)
    SCENARIO_PARTIAL.update(PROGRESSION_V18)
    SCENARIO_PARTIAL.update({'cleanse_tag', 'pure_incense'})
    assert SCENARIO_PARTIAL <= set(canonical)


def permission_state(item_id: str, canonical: dict, holdable: set[str], excluded: set[str]) -> tuple[str, str]:
    if item_id in excluded:
        return 'EXCLUDED', 'config/item_selection_v1.json:excluded_ids/excluded_categories'
    if item_id in holdable:
        return 'PERMITTED', 'modules/inventory/item_connections_v1.json:holdable_ids'
    return 'NOT_APPLICABLE', 'not holdable and not content-excluded'


def art_state(item_id: str) -> tuple[str, str, str]:
    row = ART_ROWS.get(item_id)
    if row is None:
        return 'UNKNOWN_REQUIRES_REVIEW', 'docs/current/ITEM_ART_COVERAGE_V5.json:missing row', 'Art coverage row absent.'
    state = row['art_state']
    image = row.get('image', '')
    if state in ('INSTALLED', 'INSTALLED_PROVISIONAL_STYLE'):
        return 'IMPLEMENTED_VERIFIED', 'docs/current/ITEM_ART_COVERAGE_V5.json:art_state=' + state, image
    if state == 'CONTENT_REVIEW_WITHOUT_PREPARED_ART':
        return 'DEPENDENCY_MISSING', 'docs/current/ITEM_ART_COVERAGE_V5.json:art_state=' + state, 'Art content-scope decision undecided; no prepared art.'
    if state == 'EXCLUDED_FROM_ART_PLAN':
        reason = row.get('exclusion_reason', '') or 'Excluded from the art plan.'
        return 'NOT_APPLICABLE', 'docs/current/ITEM_ART_COVERAGE_V5.json:art_state=' + state, reason
    return 'UNKNOWN_REQUIRES_REVIEW', 'docs/current/ITEM_ART_COVERAGE_V5.json:art_state=' + state, 'Unknown art_state.'


def equip_state(item_id: str, permission: str, row: dict) -> tuple[str, str, str]:
    if permission == 'EXCLUDED':
        return 'NOT_APPLICABLE', 'content excluded', 'Excluded by selection policy.'
    if permission != 'PERMITTED':
        return 'NOT_APPLICABLE', 'not holdable', 'Not part of the equipment-transfer set.'
    if row['equipment_transfer'] == 'VERIFIED':
        return 'IMPLEMENTED_VERIFIED', 'docs/current/ITEM_CONNECTIONS_V1.json:equipment_transfer=VERIFIED', ''
    return 'DEPENDENCY_MISSING', 'docs/current/ITEM_CONNECTIONS_V1.json:equipment_transfer=' + row['equipment_transfer'], 'Equipment transfer not certified.'


def native_state(item_id: str, permission: str) -> tuple[str, str, str]:
    if permission == 'EXCLUDED':
        return 'NOT_APPLICABLE', 'content excluded', 'Excluded by selection policy.'
    if permission != 'PERMITTED':
        return 'NOT_APPLICABLE', 'not holdable', 'No held native metadata is required outside the permitted set.'
    if item_id in NATIVE_DEFINITION_IDS:
        return 'IMPLEMENTED_VERIFIED', 'ITEM_FIELD_V8.csv:native_definition_present + field_held_items.cjs:DEFINITIONS', ''
    return 'DEPENDENCY_MISSING', 'native definition absent from the pinned simulator and reviewed field definitions', GAP_DEPENDENCIES.get(item_id, 'No native descriptor; effect not implemented.')


def field_state(item_id: str, permission: str, row: dict) -> tuple[str, str, str]:
    if permission == 'EXCLUDED':
        return 'NOT_APPLICABLE', 'content excluded', 'Excluded by selection policy.'
    status = row['field_use_status']
    if item_id in FIELD_OVERRIDES:
        override = FIELD_OVERRIDES[item_id]
        if item_id == 'blue_flute':
            return 'IMPLEMENTED_VERIFIED', 'ITEM_SYSTEM_CURRENT_STATUS.json:field_use_overrides.blue_flute', ''
        return 'PARTIAL_VERIFIED', 'ITEM_SYSTEM_CURRENT_STATUS.json:field_use_overrides.' + item_id, override
    if item_id in FIELD_RECOVERY_V19:
        return 'IMPLEMENTED_VERIFIED', 'ITEM_IMPORT_V19_AUDIT.json:compiled_ids', ''
    if item_id in FIELD_TRAINING_PARTIAL:
        return 'PARTIAL_VERIFIED', 'ITEM_FIELD_V8.csv:field_use_status + reviewed V13/V19 training rows', 'Base field route verified; origin/Luxury friendship, SV mochi parity or ability form route still pending.'
    if item_id in FIELD_HELD_FRIENDSHIP_PARTIAL:
        return 'PARTIAL_VERIFIED', 'field_friendship_effects.gd + V4/V13 held friendship rows', 'Base friendship gain with the active Soothe Bell modifier is verified; capture-origin/Luxury bonuses remain pending.'
    if status in FIELD_FULL_STATUSES:
        return 'IMPLEMENTED_VERIFIED', 'ITEM_FIELD_V8.csv:field_use_status=' + status, ''
    if status in FIELD_PARTIAL_STATUSES:
        return 'PARTIAL_VERIFIED', 'ITEM_FIELD_V8.csv:field_use_status=' + status, 'Base route verified; origin/Luxury friendship bonus still pending.'
    if status in FIELD_NA_STATUSES:
        return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=' + status, 'No direct field use for this ID.'
    if status == 'FIELD_USE_NOT_CONNECTED':
        family = row['family']
        if item_id in ESCAPE_V21:
            return 'NOT_APPLICABLE', 'ITEM_ESCAPE_V21.json:new_battle_item_use_ids', 'The verified use is the battle Run boundary, not a field item action.'
        if family == 'BERY':
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Held berry; battle context owns its effect.'
        if family == 'BATTLE_STAT_USE':
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Battle-only bag action.'
        if family == 'SIDE_ACTIVITY_RECORD':
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Record only; no item action.'
        if family == 'SIDE_ACTIVITY_ACCESSORY':
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Contest accessory; no field item action.'
        if family == 'LEGACY_OR_CATEGORY_REVIEW':
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Unused legacy content; no in-scope field action.'
        if family == 'FIELD_USE' and item_id in {'red_flute', 'yellow_flute'}:
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Battle-only flute action.'
        if family == 'TRAINING' and item_id in FIELD_HELD_TRAINING:
            return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', 'Held training item; battle/progression context owns its effect.'
        if family == 'EVOLUTION':
            return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', FIELD_DEPENDENCY_REASONS[status]
        return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:field_use_status=FIELD_USE_NOT_CONNECTED', FIELD_DEPENDENCY_REASONS[status]
    reason = FIELD_DEPENDENCY_REASONS.get(status, 'Field context missing for this ID.')
    return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:field_use_status=' + status, reason


def battle_state(item_id: str, permission: str, row: dict) -> tuple[str, str, str]:
    if permission == 'EXCLUDED':
        return 'NOT_APPLICABLE', 'content excluded', 'Excluded by selection policy.'
    status = row['battle_effect_status']
    family = row['family']
    scope = 'ITEM_FIELD_V8.csv:battle_effect_status=' + status
    if item_id in SUPPORT_IDS_V2:
        return 'IMPLEMENTED_VERIFIED', 'battle_support_profile.json + O110 runner/probe', ''
    if item_id == 'smoke_ball':
        return 'IMPLEMENTED_VERIFIED', 'field_world_items_v2.json + O120 runner/probe', ''
    if item_id in {'cleanse_tag', 'pure_incense'}:
        return 'NOT_APPLICABLE', 'encounter_item_modifiers.gd + O120 runner', 'The verified effect is the wild encounter rate, not a battle action.'
    if item_id in {'amulet_coin', 'exp_share', 'linking_cord', 'luck_incense'}:
        return 'DEPENDENCY_MISSING', 'O120 reviewed dependency', GAP_DEPENDENCIES[item_id]
    if item_id in ESCAPE_V21:
        return 'IMPLEMENTED_VERIFIED', 'ITEM_ESCAPE_V21.json:new_battle_item_use_ids', ''
    if item_id in PROGRESSION_V18:
        return 'PARTIAL_VERIFIED', 'ITEM_PROGRESSION_V18.json:progression_held_effect_ids_verified', 'Base XP/level-evolution route verified; other progression exceptions remain pending.'
    if item_id in HELD_EV_PENDING:
        return 'DEPENDENCY_MISSING', 'native held metadata only; calvo_progression_v1', 'Held EV-gain multiplier is not implemented; native Fling/Knock Off/item suppression remain the only native behavior.'
    if item_id == 'max_mushrooms':
        return 'DEPENDENCY_MISSING', scope, 'Dynamax/G-Max system is absent, so Max Mushrooms has no battle route.'
    if item_id in HELD_VERIFIED_V8:
        return 'PARTIAL_VERIFIED', scope, 'Scenarios verified for this ID, not exhaustive for every possible battle state.'
    if item_id in MEDICINE_BATTLE_V8:
        return 'IMPLEMENTED_VERIFIED', 'battle_medicine_profile.json + V8/V13 medicine row', ''
    if item_id in CAPTURE_VERIFIED:
        return 'PARTIAL_VERIFIED', 'V11/V12/V15 capture reports', 'Ball route verified within calvo_capture_v1; full generation fidelity, critical captures and Ultra Beast rules remain pending.'
    if family == 'MEGA_STONE':
        return 'DEPENDENCY_MISSING', scope, 'Mega Evolution system absent.'
    if family == 'Z_CRYSTAL':
        return 'DEPENDENCY_MISSING', scope, 'Z-Move system absent.'
    if family == 'Z_BAG_TOKEN':
        return 'DEPENDENCY_MISSING', scope, 'Z-Move bag route absent.'
    if family == 'CAPTURE_BALL':
        return 'DEPENDENCY_MISSING', scope, 'Capture context metadata missing (map/history/current type/gender/origin).'
    if family == 'EVOLUTION':
        return 'NOT_APPLICABLE', scope, 'Evolution context is tracked separately.'
    if family == 'RAID_EVENT_CRYSTAL':
        return 'DEPENDENCY_MISSING', scope, 'Raid/Dynamax system inactive.'
    if family == 'TERA_MATERIAL':
        return 'DEPENDENCY_MISSING', scope, 'Tera type-change system absent.'
    if family in SYSTEM_DEPENDENCY_FAMILIES:
        return 'DEPENDENCY_MISSING', scope, SYSTEM_DEPENDENCY_FAMILIES[family]
    if family in NOT_APPLICABLE_FAMILIES:
        return 'NOT_APPLICABLE', scope, 'No battle effect is defined for this content family.'
    if status == 'SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING':
        return 'IMPLEMENTED_UNVERIFIED', scope, BATTLE_DEPENDENCY_REASONS[status]
    if status == 'EXPLICIT_DEPENDENCY_OR_NONBATTLE_CONTEXT_PENDING':
        return 'DEPENDENCY_MISSING', scope, BATTLE_DEPENDENCY_REASONS[status]
    if status == 'NONBATTLE_TRAINING_FIELD_ROUTE_VERIFIED':
        return 'NOT_APPLICABLE', scope, 'Field training route only; no battle effect.'
    if status == 'NO_HELD_EFFECT_CERTIFICATION_OR_NOT_APPLICABLE':
        if family in {'HELD_COMBAT_CANDIDATE', 'BATTLE_STAT_USE'}:
            if permission != 'PERMITTED':
                return 'NOT_APPLICABLE', 'not in holdable set + ' + scope, 'No applicable battle context outside the permitted holdable set.'
            return 'IMPLEMENTED_UNVERIFIED', scope, 'Held/battle item present but no effect scenario is certified for this ID.'
        return 'NOT_APPLICABLE', scope, 'No battle effect is defined for this ID.'
    return 'UNKNOWN_REQUIRES_REVIEW', scope, 'Unhandled battle_effect_status.'


def evolution_state(item_id: str, row: dict) -> tuple[str, str, str]:
    if item_id in EVOLUTION_VERIFIED:
        return 'IMPLEMENTED_VERIFIED', 'ITEM_FIELD_V8.csv:supported_evolution_routes_tested', ''
    if item_id in EVOLUTION_PARTIAL:
        return 'PARTIAL_VERIFIED', 'ITEM_FIELD_V8.csv:supported/other evolution routes', 'Some routes verified; other evolution conditions or forms remain deferred.'
    if item_id in EVOLUTION_DEPENDENCY:
        return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:other_evolution_routes', 'Evolution route has no supported runtime context.'
    return 'NOT_APPLICABLE', 'ITEM_FIELD_V8.csv:0 evolution routes', 'No evolution route involves this ID.'


def machine_state(item_id: str, row: dict) -> tuple[str, str, str]:
    if item_id not in MACHINE_ROWS:
        return 'NOT_APPLICABLE', 'modules/inventory/item_connections_v1.json:machine_rows', 'Not a machine ID.'
    status = row['field_use_status']
    if status == 'TEACH_AND_CONSUMPTION_VERIFIED':
        return 'IMPLEMENTED_VERIFIED', 'ITEM_FIELD_V8.csv:TEACH_AND_CONSUMPTION_VERIFIED', ''
    if status == 'NEEDS_MACHINE_VERSION_PROFILE':
        return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:NEEDS_MACHINE_VERSION_PROFILE', 'Legacy machine version/profile needed; no active mapping.'
    return 'DEPENDENCY_MISSING', 'ITEM_FIELD_V8.csv:machine status=' + status, 'Machine teaching/consumption not verified.'


def scenario_state(item_id: str, contexts: dict) -> tuple[str, str, str]:
    evidence = []
    if item_id in FIELD_RECOVERY_V19:
        evidence.append('V19 field recovery')
    if item_id in FIELD_TRAINING_PARTIAL:
        evidence.append('V8/V13 field training')
    if item_id in FIELD_HELD_FRIENDSHIP_PARTIAL:
        evidence.append('V4/V13 held friendship')
    if item_id in HELD_VERIFIED_V8:
        evidence.append('V8 held scenarios')
    if item_id in MEDICINE_BATTLE_V8:
        evidence.append('V8 medicine battle')
    if item_id in CAPTURE_VERIFIED:
        evidence.append('V11/V12/V15 capture')
    if item_id in ESCAPE_V21:
        evidence.append('V21 escape')
    if item_id in PROGRESSION_V18:
        evidence.append('V18 progression')
    if item_id in SUPPORT_IDS_V2:
        evidence.append('O110 support')
    if item_id == 'smoke_ball':
        evidence.append('O120 smoke ball')
    if item_id in {'cleanse_tag', 'pure_incense'}:
        evidence.append('O120 encounter rate partial')
    if item_id in MACHINE_VERIFIED:
        evidence.append('V1 machine teach')
    if item_id in EVOLUTION_VERIFIED or item_id in EVOLUTION_PARTIAL:
        evidence.append('V1 evolution routes')
    if item_id in SCENARIO_V8:
        evidence.append('V8 matrix scenario counters')
    if item_id in SCENARIO_PARTIAL:
        return 'PARTIAL_VERIFIED', ' + '.join(dict.fromkeys(evidence)), 'Executed route has a documented pending subeffect.'
    if evidence:
        return 'IMPLEMENTED_VERIFIED', ' + '.join(dict.fromkeys(evidence)), ''
    applicable = any(contexts[key] in ('IMPLEMENTED_VERIFIED', 'PARTIAL_VERIFIED', 'IMPLEMENTED_UNVERIFIED')
                     for key in ('field', 'battle', 'evolution', 'machine'))
    if applicable:
        return 'IMPLEMENTED_UNVERIFIED', 'no executed scenario recorded for this ID', 'Effect context exists but no executed scenario is recorded.'
    return 'NOT_APPLICABLE', 'no applicable effect context', 'No executed effect scenario is required for this ID.'


def overall_state(permission: str, contexts: dict, family: str) -> tuple[str, str]:
    if permission == 'EXCLUDED':
        return 'EXCLUDED', 'Excluded by config/item_selection_v1.json.'
    effect_states = [contexts[key] for key in ('field', 'battle', 'evolution', 'machine', 'scenario')]
    if 'DEPENDENCY_MISSING' in effect_states and not any(
            state in ('IMPLEMENTED_VERIFIED', 'PARTIAL_VERIFIED') for state in effect_states):
        return 'DEPENDENCY_MISSING', 'An applicable effect context has a concrete missing dependency.'
    if 'PARTIAL_VERIFIED' in effect_states:
        return 'PARTIAL_VERIFIED', 'An effect was executed with a documented pending part.'
    if 'IMPLEMENTED_VERIFIED' in effect_states:
        return 'IMPLEMENTED_VERIFIED', 'An applicable effect scenario was executed.'
    if 'IMPLEMENTED_UNVERIFIED' in effect_states:
        return 'IMPLEMENTED_UNVERIFIED', 'The item is present but no effect scenario is certified.'
    if family in SYSTEM_DEPENDENCY_FAMILIES:
        return 'DEPENDENCY_MISSING', SYSTEM_DEPENDENCY_FAMILIES[family]
    return 'NOT_APPLICABLE', 'No in-scope effect context applies to this ID.'


def build(canonical: dict, policy: dict) -> tuple[dict, list[dict]]:
    excluded = set(policy.get('excluded_ids', []))
    excluded_categories = set(policy.get('excluded_categories', []))
    excluded |= {item_id for item_id, row in canonical.items()
                 if row.get('category', '') in excluded_categories}
    connections = load(CONNECTIONS)
    holdable = set(connections['holdable_ids'])
    items: list[dict] = []
    for item_id in sorted(canonical):
        info = canonical[item_id]
        row = V8_ROWS[item_id]
        permission, permission_source = permission_state(item_id, canonical, holdable, excluded)
        art, art_source, art_note = art_state(item_id)
        equip, equip_source, equip_note = equip_state(item_id, permission, row)
        native, native_source, native_note = native_state(item_id, permission)
        field, field_source, field_note = field_state(item_id, permission, row)
        battle, battle_source, battle_note = battle_state(item_id, permission, row)
        evolution, evolution_source, evolution_note = evolution_state(item_id, row)
        machine, machine_source, machine_note = machine_state(item_id, row)
        contexts = {'field': field, 'battle': battle, 'evolution': evolution, 'machine': machine}
        scenario, scenario_source, scenario_note = scenario_state(item_id, contexts)
        contexts['scenario'] = scenario
        overall, overall_note = overall_state(permission, contexts, row['family'])
        dependency = ''
        for candidate, state in ((native_note, native),
                                 (field_note, field), (battle_note, battle),
                                 (evolution_note, evolution), (machine_note, machine)):
            if candidate and state == 'DEPENDENCY_MISSING' and candidate not in dependency:
                dependency = (dependency + ' | ' + candidate).strip(' |')
        notes = []
        if art_note and art in ('DEPENDENCY_MISSING', 'UNKNOWN_REQUIRES_REVIEW'):
            notes.append('art: ' + art_note)
        if equip_note and equip in ('DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('equip: ' + equip_note)
        if native_note and native in ('DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('native: ' + native_note)
        if field_note and field in ('PARTIAL_VERIFIED', 'DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('field: ' + field_note)
        if battle_note and battle in ('PARTIAL_VERIFIED', 'DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('battle: ' + battle_note)
        if evolution_note and evolution in ('PARTIAL_VERIFIED', 'DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('evolution: ' + evolution_note)
        if machine_note and machine in ('PARTIAL_VERIFIED', 'DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('machine: ' + machine_note)
        if scenario_note and scenario in ('PARTIAL_VERIFIED', 'DEPENDENCY_MISSING', 'IMPLEMENTED_UNVERIFIED'):
            notes.append('scenario: ' + scenario_note)
        items.append({
            'id': item_id,
            'name_en': '',
            'name_es': info.get('display_name', '') or item_id,
            'name_source': 'data/normalized/pokemon_api.json:display_name (Spanish; the normalized source has no English name field)',
            'category': info.get('category', ''),
            'family': row['family'],
            'permission': permission,
            'permission_source': permission_source,
            'art': art,
            'art_source': art_source,
            'equip': equip,
            'equip_source': equip_source,
            'native_metadata': native,
            'native_source': native_source,
            'field_use': field,
            'field_source': field_source,
            'battle_use': battle,
            'battle_source': battle_source,
            'evolution': evolution,
            'evolution_source': evolution_source,
            'machine': machine,
            'machine_source': machine_source,
            'scenario': scenario,
            'scenario_source': scenario_source,
            'overall': overall,
            'dependency': dependency,
            'notes': ' | '.join(notes),
            'holdable': item_id in holdable,
            'permitted': permission == 'PERMITTED',
            'excluded': permission == 'EXCLUDED',
            'native_present': item_id in NATIVE_DEFINITION_IDS and permission == 'PERMITTED',
            'art_installed': art == 'IMPLEMENTED_VERIFIED',
            'machine_verified': machine == 'IMPLEMENTED_VERIFIED',
            'evolution_supported': int(row['supported_evolution_routes_tested'] or 0),
            'evolution_other': int(row['other_evolution_routes'] or 0),
            'o110_support': item_id in SUPPORT_IDS_V2,
            'o120_effect': item_id in {'smoke_ball', 'cleanse_tag', 'pure_incense'},
        })
    return {}, items


def summarise(items: list[dict]) -> dict:
    def count(field: str, value: str) -> int:
        return sum(1 for item in items if item[field] == value)

    state_distribution = dict(sorted(Counter(item['overall'] for item in items).items()))
    context_distributions = {
        key: dict(sorted(Counter(item[key] for item in items).items()))
        for key in ('permission', 'art', 'equip', 'native_metadata', 'field_use',
                    'battle_use', 'evolution', 'machine', 'scenario')
    }
    missing_native = sorted(item['id'] for item in items
                            if item['permitted'] and not item['native_present'])
    art_installed = sum(1 for item in items if item['art'] == 'IMPLEMENTED_VERIFIED')
    art_missing = sum(1 for item in items if item['art'] == 'DEPENDENCY_MISSING')
    art_excluded = sum(1 for item in items if item['art'] == 'NOT_APPLICABLE')
    machine_ids = sum(1 for item in items if item['machine'] != 'NOT_APPLICABLE')
    machine_verified = sum(1 for item in items if item['machine'] == 'IMPLEMENTED_VERIFIED')
    evolution_supported = sum(item['evolution_supported'] for item in items)
    evolution_other = sum(item['evolution_other'] for item in items)
    evolution_items = sum(1 for item in items if item['evolution_supported'] or item['evolution_other'])
    unknown = [item['id'] for item in items if 'UNKNOWN_REQUIRES_REVIEW' in (
        item['permission'], item['art'], item['equip'], item['native_metadata'],
        item['field_use'], item['battle_use'], item['evolution'], item['machine'],
        item['scenario'], item['overall'])]
    counts = {
        'excluded_count': count('overall', 'EXCLUDED'),
        'permitted_holdable': sum(1 for item in items if item['holdable']),
        'permitted_after_exclusion': sum(1 for item in items if item['permitted']),
        'native_present': sum(1 for item in items if item['native_present']),
        'native_missing': len(missing_native),
        'art_entries_with_art': art_installed,
        'art_non_excluded_without_prepared': art_missing,
        'art_excluded_from_plan': art_excluded,
        'machine_ids_mapped': machine_ids,
        'machine_verified': machine_verified,
        'machine_pending': machine_ids - machine_verified,
        'evolution_routes_supported': evolution_supported,
        'evolution_routes_other': evolution_other,
        'evolution_item_ids': evolution_items,
        'unknown_rows': len(unknown),
        'o110_support_ids': sum(1 for item in items if item['o110_support']),
        'o120_effect_ids': sum(1 for item in items if item['o120_effect']),
    }
    assert counts['permitted_after_exclusion'] == 625, counts
    assert counts['native_present'] == 619, counts
    assert counts['native_missing'] == 6, counts
    assert counts['art_entries_with_art'] == 1011, counts
    assert counts['art_non_excluded_without_prepared'] == 1055, counts
    assert counts['art_excluded_from_plan'] == 156, counts
    assert counts['art_entries_with_art'] + counts['art_non_excluded_without_prepared'] + counts['art_excluded_from_plan'] == 2222
    assert counts['machine_ids_mapped'] == 338, counts
    assert counts['machine_verified'] == 229, counts
    assert counts['machine_pending'] == 109, counts
    assert counts['evolution_routes_supported'] == 57, counts
    assert counts['evolution_routes_other'] == 15, counts
    assert counts['evolution_item_ids'] == 26, counts
    assert counts['unknown_rows'] == 0, unknown[:20]
    assert counts['o110_support_ids'] == 11, counts
    assert counts['o120_effect_ids'] == 3, counts
    assert sum(state_distribution.values()) == 2222, state_distribution
    assert sum(item['permitted'] for item in items) == 625
    return {
        'counts': counts,
        'state_distribution': state_distribution,
        'context_distributions': context_distributions,
        'missing_native_ids': missing_native,
        'unknown_ids': unknown,
    }


def build_coverage(items: list[dict], summary: dict) -> dict:
    return {
        'schema_version': 2,
        'phase': 'OPENCODE_ITEM_CLOSURE_V2_O100_O190_AUDIT',
        'total_canonical': 2222,
        'total_processed': len(items),
        'scope': 'Per-ID, per-context inventory. Presence is not effect certification; art and native presence are separate from executed effects.',
        **summary['counts'],
        'state_distribution': summary['state_distribution'],
        'context_distributions': summary['context_distributions'],
        'missing_native_ids': summary['missing_native_ids'],
        'unknown_ids': summary['unknown_ids'],
        'art_denominator': {
            'installed_or_provisional': 1011,
            'non_excluded_without_prepared': 1055,
            'excluded_from_art_plan': 156,
            'final_game_art_requirement_count': 'UNDECIDED_PENDING_CONTENT_SCOPE',
            'source': 'docs/current/ITEM_ART_COVERAGE_V5.json',
        },
        'machine': {
            'mapped': 338,
            'active_version': 'scarlet-violet',
            'teaching_and_consumption_verified': 229,
            'version_profile_pending': 109,
            'source': 'modules/inventory/item_connections_v1.json:machine_rows + ITEM_FIELD_V8.csv',
        },
        'evolution': {
            'edges': 72,
            'item_ids': 26,
            'supported_routes_tested': 57,
            'other_routes_deferred': 15,
            'source': 'ITEM_FIELD_V8.csv:supported_evolution_routes_tested/other_evolution_routes',
        },
        'o110': {
            'reviewed_ids': sorted(SUPPORT_IDS_V2),
            'consumable_ids': sorted(item_id for item_id, row in load(SUPPORT_PROFILE)['items'].items() if row['consumable']),
            'reusable_ids': sorted(item_id for item_id, row in load(SUPPORT_PROFILE)['items'].items() if not row['consumable']),
            'friendship_base_gain': 'battleitem +1 under 200; origin/Luxury bonus pending',
        },
        'o120': {
            'smoke_ball': 'IMPLEMENTED_VERIFIED at the Run boundary; native descriptor present; no consumption',
            'cleanse_tag': 'PARTIAL_VERIFIED_RATE_ONLY 2/3 encounter rate; step-period semantics pending',
            'pure_incense': 'PARTIAL_VERIFIED_RATE_ONLY 2/3 encounter rate; step-period semantics pending',
            'concrete_dependencies': ['amulet_coin', 'exp_share', 'linking_cord', 'luck_incense'],
        },
        'sources_sha256': {
            path.relative_to(ROOT).as_posix(): sha256(path)
            for path in (CANON, POLICY, CONNECTIONS, V8_CSV, ART, V18, V19_AUDIT, V20,
                         V21, CAPTURE_V11, CAPTURE_V12, CAPTURE_V15, SYSTEM,
                         SUPPORT_PROFILE, MEDICINE_PROFILE, FIELD_HELD, FIELD_MISC, FIELD_WORLD)
        },
        'rows': items,
        'detail_paths': ['id', 'name_en', 'name_es', 'category', 'family',
                         'permission', 'art', 'equip', 'native_metadata', 'field_use',
                         'battle_use', 'evolution', 'machine', 'scenario', 'overall',
                         'dependency', 'notes'],
    }


CSV_FIELDS = [
    'id', 'name_en', 'name_es', 'category', 'family',
    'permission', 'permission_source', 'art', 'art_source', 'equip', 'equip_source',
    'native_metadata', 'native_source', 'field_use', 'field_source',
    'battle_use', 'battle_source', 'evolution', 'evolution_source',
    'machine', 'machine_source', 'scenario', 'scenario_source', 'overall',
    'dependency', 'notes', 'holdable', 'permitted', 'excluded', 'native_present',
    'art_installed', 'machine_verified', 'evolution_supported', 'evolution_other',
    'o110_support', 'o120_effect',
]


def render_json(coverage: dict) -> str:
    return json.dumps(coverage, ensure_ascii=False, indent=2) + '\n'


def render_csv(items: list[dict]) -> str:
    import io
    buffer = io.StringIO(newline='')
    writer = csv.DictWriter(buffer, fieldnames=CSV_FIELDS, lineterminator='\n')
    writer.writeheader()
    for item in items:
        writer.writerow({key: item[key] for key in CSV_FIELDS})
    return buffer.getvalue()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='verify that the committed COVERAGE files match a fresh generation')
    args = parser.parse_args()
    load_sources()
    canonical = load(CANON)['items']
    policy = load(POLICY)
    _, items = build(canonical, policy)
    summary = summarise(items)
    coverage = build_coverage(items, summary)
    json_text = render_json(coverage)
    csv_text = render_csv(items)
    if args.check:
        failures = []
        if not OUT_JSON.is_file():
            failures.append(f'missing {OUT_JSON}')
        elif OUT_JSON.read_text(encoding='utf-8') != json_text:
            failures.append(f'{OUT_JSON} does not match a fresh generation')
        if not OUT_CSV.is_file():
            failures.append(f'missing {OUT_CSV}')
        elif OUT_CSV.read_text(encoding='utf-8') != csv_text:
            failures.append(f'{OUT_CSV} does not match a fresh generation')
        if failures:
            for failure in failures:
                print('FAIL', failure, file=sys.stderr)
            return 1
        print('COVERAGE_CHECK PASS', json_text.count('\n'), 'json_lines', csv_text.count('\n'), 'csv_lines')
        return 0
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json_text, encoding='utf-8', newline='\n')
    OUT_CSV.write_text(csv_text, encoding='utf-8', newline='\n')
    print('COVERAGE', len(items), 'rows')
    print('COUNTS', json.dumps(summary['counts'], ensure_ascii=False, sort_keys=True))
    print('STATES', json.dumps(summary['state_distribution'], ensure_ascii=False, sort_keys=True))
    print('SHA256', json.dumps({
        OUT_JSON.relative_to(ROOT).as_posix(): sha256(OUT_JSON),
        OUT_CSV.relative_to(ROOT).as_posix(): sha256(OUT_CSV),
    }, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
