#!/usr/bin/env python3
"""Compatibility shim for DATA FOUNDATION V3 legacy move-effect helpers.

This module is intentionally NOT a runnable PokéAPI adapter. The obsolete V2
adapter lives in ``tools/archive/pokeapi_adapter_v2_legacy.py`` for provenance.
``pokeapi_adapter_v3.py`` still imports the historical module name while reusing
its mature move-effect conversion helpers, so this shim forwards attribute access
to the archived implementation without restoring V2 as a canonical pipeline.

The shim also contains the narrowly scoped compatibility corrections required
because the archived implementation predates DATA V3's normalized IDs and the
repository reorganization. The archived source itself remains untouched.
"""
from __future__ import annotations

import json
from pathlib import Path

from archive import pokeapi_adapter_v2_legacy as _legacy


_CONTACT_OVERRIDE = Path(__file__).with_name("move_flags_override.json")
_REQUIRED_CONTACT_SENTINELS = {"tackle", "thunder_punch"}
_REQUIRED_UNSUPPORTED_NORMALIZED = {
    "sleep_talk",
    "me_first",
    "mirror_move",
    "nature_power",
}

# Verified against the immutable DATA V3 snapshot. These moves are deliberately
# explicit rather than inferred from broad target-name heuristics: Move Effects V3
# is auditing one semantic family at a time so a hidden exception cannot silently
# alter hundreds of generated records.
_SELECTED_TARGET_HEALS = {"heal_pulse", "floral_healing"}
_TEAM_TARGET_HEALS = {"life_dew", "jungle_healing"}
_SIMPLE_SELF_HEALS = {
    "recover",
    "soft_boiled",
    "milk_drink",
    "slack_off",
    "heal_order",
}
_WEATHER_SELF_HEALS = {"morning_sun", "synthesis", "moonlight", "shore_up"}
_TEMP_TYPE_SELF_HEALS = {"roost"}
_AUDITED_DATA_ONLY_UNIQUE = {"rest", "wish"}
_PARTIAL_UNIQUE_STAT_HEALS = {"strength_sap"}
_AUDITED_DATA_ONLY_PROTECTION_CONTACT = {"silk_trap"}
_AUDITED_DATA_ONLY_ALLY_STAT = {"aromatic_mist": ("special_defense", 1)}
_AUDITED_DATA_ONLY_HELD_BERRY_STAT = {"stuff_cheeks": ("defense", 2)}
_PARTIAL_USER_AND_ALLIES_STAT = {"howl": ("attack", 1)}
_AUDITED_DATA_ONLY_ADJACENT_ALLY_STATS = {
    "coaching": {"attack": 1, "defense": 1},
}
_AUDITED_DATA_ONLY_PLUS_MINUS_SIDE_STATS = {
    "gear_up": {"attack": 1, "special_attack": 1},
    "magnetic_flux": {"defense": 1, "special_defense": 1},
}
_PLUS_MINUS_SIDE_EFFECT_PHRASES = {
    "gear_up": "raises the attack and special attack of all friendly",
    "magnetic_flux": "raises the defense and special defense of all friendly",
}
_SIMPLE_SELF_STAT_BOOSTS = {
    "acid_armor": ("defense", 2),
    "agility": ("speed", 2),
    "amnesia": ("special_defense", 2),
    "barrier": ("defense", 2),
    "cotton_guard": ("defense", 3),
    "double_team": ("evasion", 1),
    "harden": ("defense", 1),
    "iron_defense": ("defense", 2),
    "meditate": ("attack", 1),
    "nasty_plot": ("special_attack", 2),
    "rock_polish": ("speed", 2),
    "sharpen": ("attack", 1),
    "swords_dance": ("attack", 2),
    "tail_glow": ("special_attack", 3),
    "withdraw": ("defense", 1),
}
_PURE_SELF_STAT_PACKAGES = {
    "bulk_up": {"attack": 1, "defense": 1},
    "calm_mind": {"special_attack": 1, "special_defense": 1},
    "coil": {"attack": 1, "defense": 1, "accuracy": 1},
    "cosmic_power": {"defense": 1, "special_defense": 1},
    "defend_order": {"defense": 1, "special_defense": 1},
    "dragon_dance": {"attack": 1, "speed": 1},
    "hone_claws": {"attack": 1, "accuracy": 1},
    "quiver_dance": {"special_attack": 1, "special_defense": 1, "speed": 1},
    "shift_gear": {"attack": 1, "speed": 2},
    "work_up": {"attack": 1, "special_attack": 1},
}

# The V2 list mixes raw PokéAPI hyphenated names with the underscore-normalized
# IDs used by the adapter. Normalize it once for the archived helper functions.
# ``astonish`` was an old placeholder: its damage + flinch effect is fully
# representable by generate_move_specs(), so keeping it unsupported is incorrect.
_legacy.UNSUPPORTED_MOVE_NAMES = {
    _legacy.slug(name) for name in _legacy.UNSUPPORTED_MOVE_NAMES
}
_legacy.UNSUPPORTED_MOVE_NAMES.discard("astonish")

if not _REQUIRED_UNSUPPORTED_NORMALIZED.issubset(_legacy.UNSUPPORTED_MOVE_NAMES):
    raise RuntimeError("DATA V3 legacy unsupported-move normalization failed")
if "astonish" in _legacy.UNSUPPORTED_MOVE_NAMES:
    raise RuntimeError("DATA V3 legacy Astonish placeholder was not removed")


def _load_contact_override() -> set[str]:
    if not _CONTACT_OVERRIDE.is_file():
        raise FileNotFoundError(
            f"DATA V3 contact override missing: {_CONTACT_OVERRIDE}"
        )
    try:
        data = json.loads(_CONTACT_OVERRIDE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(
            f"DATA V3 contact override is unreadable: {_CONTACT_OVERRIDE}"
        ) from exc

    contact = set(data.get("contact", []))
    missing = sorted(_REQUIRED_CONTACT_SENTINELS - contact)
    if missing:
        raise RuntimeError(
            "DATA V3 contact override lost required sentinels: %s"
            % ", ".join(missing)
        )
    return contact


def _rewrite_effect_target(specs: list[dict], kind: str, target: str) -> int:
    """Rewrite matching effects recursively and return the number changed."""
    changed = 0
    for spec in specs:
        if spec.get("kind") == kind:
            spec["target"] = target
            changed += 1
        children = spec.get("children") or []
        if isinstance(children, list):
            changed += _rewrite_effect_target(children, kind, target)
    return changed


def _matching_effects(specs: list[dict], kind: str, target: str | None = None) -> list[dict]:
    found: list[dict] = []
    for spec in specs:
        if spec.get("kind") == kind and (
            target is None or spec.get("target") == target
        ):
            found.append(spec)
        children = spec.get("children") or []
        if isinstance(children, list):
            found.extend(_matching_effects(children, kind, target))
    return found


def _has_effect(specs: list[dict], kind: str, target: str | None = None) -> bool:
    return bool(_matching_effects(specs, kind, target))


def _require_single_self_heal(specs: list[dict], sid: str, ratio_basis_points: int) -> None:
    heals = _matching_effects(specs, "heal")
    if len(heals) != 1:
        raise RuntimeError(
            f"DATA V3 expected exactly one heal effect for {sid}, found {len(heals)}"
        )
    heal = heals[0]
    if heal.get("target") != "self" or heal.get("ratio_basis_points") != ratio_basis_points:
        raise RuntimeError(
            f"DATA V3 self-heal contract mismatch for {sid}: {heal}"
        )


def _require_simple_self_stat_boost(
    m: dict,
    specs: list[dict],
    sid: str,
    stat_id: str,
    value: int,
) -> None:
    """Verify a source-checked pure self stat boost has no hidden generated effect."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if target != "user" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 simple self-boost source contract changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 simple self-boost metadata changed for {sid}")
    if len(stat_changes) != 1:
        raise RuntimeError(f"DATA V3 expected one source stat change for {sid}")
    source_change = stat_changes[0]
    if (
        (source_change.get("stat") or {}).get("name") != stat_id.replace("special_", "special-")
        or int(source_change.get("change", 0)) != value
    ):
        raise RuntimeError(f"DATA V3 simple self-boost stat contract changed for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != 1 or len(stages) != 1:
        raise RuntimeError(f"DATA V3 simple self-boost generated unexpected effects for {sid}: {specs}")
    stage = stages[0]
    if (
        stage.get("target") != "self"
        or stage.get("stat_id") != stat_id
        or int(stage.get("value", 0)) != value
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(f"DATA V3 simple self-boost effect mismatch for {sid}: {stage}")


def _require_pure_self_stat_package(
    m: dict,
    specs: list[dict],
    sid: str,
    expected_stats: dict[str, int],
) -> None:
    """Verify a source-audited move is exactly an unconditional SELF stat package."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    if target != "user" or category != "net-good-stats" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 pure self-stat source contract changed for {sid}")
    if int(meta.get("stat_chance") or 0) != 0:
        raise RuntimeError(f"DATA V3 pure self-stat chance changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 pure self-stat metadata changed for {sid}")

    source_stats = {}
    for change in m.get("stat_changes") or []:
        stat_name = (change.get("stat") or {}).get("name")
        if stat_name:
            source_stats[stat_name.replace("-", "_")] = int(change.get("change", 0))
    if source_stats != expected_stats:
        raise RuntimeError(f"DATA V3 pure self-stat source changes mismatch for {sid}: {source_stats}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != len(expected_stats) or len(stages) != len(expected_stats):
        raise RuntimeError(f"DATA V3 pure self-stat generated unexpected effects for {sid}: {specs}")
    generated_stats = {}
    for stage in stages:
        stat_id = str(stage.get("stat_id", ""))
        if (
            stage.get("target") != "self"
            or int(stage.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(f"DATA V3 pure self-stat generated effect mismatch for {sid}: {stage}")
        generated_stats[stat_id] = int(stage.get("value", 0))
    if generated_stats != expected_stats:
        raise RuntimeError(f"DATA V3 pure self-stat generated stats mismatch for {sid}: {generated_stats}")


def _require_audited_data_only_unique(m: dict, specs: list[dict], sid: str) -> None:
    """Fail if a source-verified unique move starts receiving guessed runtime effects."""
    meta = m.get("meta") or {}
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    target = (m.get("target") or {}).get("name")
    if specs:
        raise RuntimeError(
            f"DATA V3 audited DATA_ONLY move {sid} unexpectedly generated effects: {specs}"
        )
    if category != "unique" or int(meta.get("healing") or 0) != 0:
        raise RuntimeError(
            f"DATA V3 audited unique-move metadata changed for {sid}"
        )
    if ailment not in ("none", "", None) or target != "user":
        raise RuntimeError(
            f"DATA V3 audited unique-move status/target changed for {sid}"
        )


def _require_strength_sap_partial(m: dict, specs: list[dict]) -> None:
    """Verify the representable Strength Sap subset without inventing its heal."""
    meta = m.get("meta") or {}
    category = (meta.get("category") or {}).get("name")
    target = (m.get("target") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if category != "unique" or target != "selected-pokemon":
        raise RuntimeError("DATA V3 Strength Sap source contract changed")
    if int(meta.get("healing") or 0) != 0 or len(stat_changes) != 1:
        raise RuntimeError("DATA V3 Strength Sap metadata changed")
    stat_change = stat_changes[0]
    if (
        int(stat_change.get("change", 0)) != -1
        or (stat_change.get("stat") or {}).get("name") != "attack"
    ):
        raise RuntimeError("DATA V3 Strength Sap Attack-drop contract changed")

    stages = _matching_effects(specs, "modify_stat_stage")
    heals = _matching_effects(specs, "heal")
    if len(stages) != 1 or heals:
        raise RuntimeError(
            f"DATA V3 Strength Sap generated unexpected effects: {specs}"
        )
    stage = stages[0]
    if (
        stage.get("target") != "opponent"
        or stage.get("stat_id") != "attack"
        or int(stage.get("value", 0)) != -1
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(
            f"DATA V3 Strength Sap stat effect mismatch: {stage}"
        )


def _require_silk_trap_data_only(m: dict, specs: list[dict]) -> None:
    """Verify Silk Trap source semantics and the legacy false self-debuff signature."""
    target = (m.get("target") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if target != "user" or int(m.get("priority") or 0) != 4 or m.get("meta") is not None:
        raise RuntimeError("DATA V3 Silk Trap source contract changed")
    if len(stat_changes) != 1:
        raise RuntimeError("DATA V3 Silk Trap expected one source stat change")
    source_change = stat_changes[0]
    if (
        int(source_change.get("change", 0)) != -1
        or (source_change.get("stat") or {}).get("name") != "speed"
    ):
        raise RuntimeError("DATA V3 Silk Trap Speed-drop metadata changed")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != 1 or len(stages) != 1:
        raise RuntimeError(
            f"DATA V3 Silk Trap legacy generated shape changed unexpectedly: {specs}"
        )
    stage = stages[0]
    if (
        stage.get("target") != "self"
        or stage.get("stat_id") != "speed"
        or int(stage.get("value", 0)) != -1
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(
            f"DATA V3 Silk Trap legacy false-self-debuff signature changed: {stage}"
        )


def _require_ally_stat_data_only(
    m: dict,
    specs: list[dict],
    sid: str,
    stat_id: str,
    value: int,
) -> None:
    """Verify an ally-targeted stat move before removing its false SELF effect."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if target != "ally" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 ally-stat source contract changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 ally-stat metadata changed for {sid}")
    if len(stat_changes) != 1:
        raise RuntimeError(f"DATA V3 expected one ally stat change for {sid}")
    source_change = stat_changes[0]
    if (
        (source_change.get("stat") or {}).get("name") != stat_id.replace("special_", "special-")
        or int(source_change.get("change", 0)) != value
    ):
        raise RuntimeError(f"DATA V3 ally-stat source change mismatch for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != 1 or len(stages) != 1:
        raise RuntimeError(f"DATA V3 ally-stat legacy shape changed for {sid}: {specs}")
    stage = stages[0]
    if (
        stage.get("target") != "self"
        or stage.get("stat_id") != stat_id
        or int(stage.get("value", 0)) != value
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(f"DATA V3 ally-stat false-SELF signature changed for {sid}: {stage}")


def _require_held_berry_stat_data_only(
    m: dict,
    specs: list[dict],
    sid: str,
    stat_id: str,
    value: int,
) -> None:
    """Verify a held-Berry-gated stat move before removing its unconditional effect."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if target != "user" or category != "net-good-stats" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 held-Berry stat source contract changed for {sid}")
    if int(meta.get("stat_chance") or 0) != 100:
        raise RuntimeError(f"DATA V3 held-Berry stat chance changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 held-Berry stat metadata changed for {sid}")
    if len(stat_changes) != 1:
        raise RuntimeError(f"DATA V3 expected one held-Berry stat change for {sid}")
    source_change = stat_changes[0]
    if (
        (source_change.get("stat") or {}).get("name") != stat_id.replace("special_", "special-")
        or int(source_change.get("change", 0)) != value
    ):
        raise RuntimeError(f"DATA V3 held-Berry stat source change mismatch for {sid}")

    english_effects = []
    for entry in m.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            english_effects.append(str(entry.get("effect") or ""))
            english_effects.append(str(entry.get("short_effect") or ""))
    effect_text = " ".join(english_effects).lower()
    if "cannot be used unless the user is holding a berry" not in effect_text or "consumes a berry" not in effect_text:
        raise RuntimeError(f"DATA V3 held-Berry semantic contract changed for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != 1 or len(stages) != 1:
        raise RuntimeError(f"DATA V3 held-Berry legacy shape changed for {sid}: {specs}")
    stage = stages[0]
    if (
        stage.get("target") != "self"
        or stage.get("stat_id") != stat_id
        or int(stage.get("value", 0)) != value
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(f"DATA V3 held-Berry unconditional signature changed for {sid}: {stage}")


def _require_user_and_allies_stat_partial(
    m: dict,
    specs: list[dict],
    sid: str,
    stat_id: str,
    value: int,
) -> None:
    """Verify a modern user-and-allies stat move before preserving only SELF."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    stat_changes = m.get("stat_changes") or []
    if target != "user-and-allies" or category != "net-good-stats" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 user-and-allies source contract changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 user-and-allies metadata changed for {sid}")
    if len(stat_changes) != 1:
        raise RuntimeError(f"DATA V3 expected one user-and-allies stat change for {sid}")
    source_change = stat_changes[0]
    if (
        (source_change.get("stat") or {}).get("name") != stat_id.replace("special_", "special-")
        or int(source_change.get("change", 0)) != value
    ):
        raise RuntimeError(f"DATA V3 user-and-allies stat source change mismatch for {sid}")

    current_texts = []
    for entry in m.get("flavor_text_entries") or []:
        if (
            (entry.get("language") or {}).get("name") == "en"
            and (entry.get("version_group") or {}).get("name") == "scarlet-violet"
        ):
            current_texts.append(str(entry.get("flavor_text") or ""))
    current_text = " ".join(current_texts).lower()
    if "itself and its allies" not in current_text or "attack stats" not in current_text:
        raise RuntimeError(f"DATA V3 current user-and-allies semantics changed for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != 1 or len(stages) != 1:
        raise RuntimeError(f"DATA V3 user-and-allies legacy shape changed for {sid}: {specs}")
    stage = stages[0]
    if (
        stage.get("target") != "opponent"
        or stage.get("stat_id") != stat_id
        or int(stage.get("value", 0)) != value
        or int(stage.get("chance_basis_points", 0)) != 10000
    ):
        raise RuntimeError(f"DATA V3 user-and-allies false-opponent signature changed for {sid}: {stage}")


def _require_adjacent_ally_stats_data_only(
    m: dict,
    specs: list[dict],
    sid: str,
    expected_stats: dict[str, int],
) -> None:
    """Verify an ally-only multi-stat move before removing false OPPONENT buffs."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    if target != "user-and-allies" or category != "net-good-stats" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 adjacent-ally source contract changed for {sid}")
    if int(meta.get("stat_chance") or 0) != 100:
        raise RuntimeError(f"DATA V3 adjacent-ally stat chance changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 adjacent-ally metadata changed for {sid}")

    source_stats = {}
    for change in m.get("stat_changes") or []:
        stat_name = (change.get("stat") or {}).get("name")
        if stat_name:
            source_stats[stat_name.replace("-", "_")] = int(change.get("change", 0))
    if source_stats != expected_stats:
        raise RuntimeError(f"DATA V3 adjacent-ally stat source changes mismatch for {sid}: {source_stats}")

    english_effects = []
    for entry in m.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            english_effects.append(str(entry.get("effect") or ""))
            english_effects.append(str(entry.get("short_effect") or ""))
    effect_text = " ".join(english_effects).lower()
    if (
        "raises the target's attack and defense by 1 stage" not in effect_text
        or "fails if there is no ally adjacent to the user" not in effect_text
    ):
        raise RuntimeError(f"DATA V3 adjacent-ally effect semantics changed for {sid}")

    current_texts = []
    for entry in m.get("flavor_text_entries") or []:
        if (
            (entry.get("language") or {}).get("name") == "en"
            and (entry.get("version_group") or {}).get("name") == "scarlet-violet"
        ):
            current_texts.append(str(entry.get("flavor_text") or ""))
    current_text = " ".join(current_texts).lower()
    if "ally pokémon" not in current_text or "attack and defense stats" not in current_text:
        raise RuntimeError(f"DATA V3 current adjacent-ally semantics changed for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != len(expected_stats) or len(stages) != len(expected_stats):
        raise RuntimeError(f"DATA V3 adjacent-ally legacy shape changed for {sid}: {specs}")
    generated_stats = {}
    for stage in stages:
        stat_id = str(stage.get("stat_id", ""))
        if (
            stage.get("target") != "opponent"
            or int(stage.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(f"DATA V3 adjacent-ally false-opponent signature changed for {sid}: {stage}")
        generated_stats[stat_id] = int(stage.get("value", 0))
    if generated_stats != expected_stats:
        raise RuntimeError(f"DATA V3 adjacent-ally legacy stat changes mismatch for {sid}: {generated_stats}")


def _require_plus_minus_side_stats_data_only(
    m: dict,
    specs: list[dict],
    sid: str,
    expected_stats: dict[str, int],
) -> None:
    """Verify Plus/Minus-gated friendly-side stats before removing false OPPONENT buffs."""
    meta = m.get("meta") or {}
    target = (m.get("target") or {}).get("name")
    category = (meta.get("category") or {}).get("name")
    ailment = (meta.get("ailment") or {}).get("name")
    if target != "user-and-allies" or category != "net-good-stats" or ailment not in ("none", "", None):
        raise RuntimeError(f"DATA V3 Plus/Minus source contract changed for {sid}")
    if int(meta.get("stat_chance") or 0) != 0:
        raise RuntimeError(f"DATA V3 Plus/Minus stat chance changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 Plus/Minus metadata changed for {sid}")

    source_stats = {}
    for change in m.get("stat_changes") or []:
        stat_name = (change.get("stat") or {}).get("name")
        if stat_name:
            source_stats[stat_name.replace("-", "_")] = int(change.get("change", 0))
    if source_stats != expected_stats:
        raise RuntimeError(f"DATA V3 Plus/Minus stat source changes mismatch for {sid}: {source_stats}")

    english_effects = []
    for entry in m.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            english_effects.append(str(entry.get("effect") or ""))
            english_effects.append(str(entry.get("short_effect") or ""))
    effect_text = " ".join(english_effects).lower()
    expected_phrase = _PLUS_MINUS_SIDE_EFFECT_PHRASES.get(sid, "")
    if (
        not expected_phrase
        or expected_phrase not in effect_text
        or "with plus or minus" not in effect_text
    ):
        raise RuntimeError(f"DATA V3 Plus/Minus effect semantics changed for {sid}")

    stages = _matching_effects(specs, "modify_stat_stage")
    if len(specs) != len(expected_stats) or len(stages) != len(expected_stats):
        raise RuntimeError(f"DATA V3 Plus/Minus legacy shape changed for {sid}: {specs}")
    generated_stats = {}
    for stage in stages:
        stat_id = str(stage.get("stat_id", ""))
        if (
            stage.get("target") != "opponent"
            or int(stage.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(f"DATA V3 Plus/Minus false-opponent signature changed for {sid}: {stage}")
        generated_stats[stat_id] = int(stage.get("value", 0))
    if generated_stats != expected_stats:
        raise RuntimeError(f"DATA V3 Plus/Minus legacy stat changes mismatch for {sid}: {generated_stats}")


def generate_move_specs(m: dict, contact_set: set):
    """V3 wrapper around the archived move-effect converter.

    Only semantics verified during Move Effects V3 are corrected here. The tuple
    contract remains identical to the archived helper.
    """
    specs, crit_rate_bp, makes_contact, coverage, override_count, unsupported_note = (
        _legacy.generate_move_specs(m, contact_set)
    )
    sid = _legacy.slug(str(m.get("name", "")))

    if sid in _SIMPLE_SELF_HEALS:
        _require_single_self_heal(specs, sid, 5000)
        # Snapshot-verified: these moves have no additional battle effect.
        coverage = "RUNTIME_SUPPORTED"

    if sid in _WEATHER_SELF_HEALS:
        _require_single_self_heal(specs, sid, 5000)
        # The generated 1/2 heal is the correct neutral-weather behavior, but the
        # current BattleEffectSpec cannot express weather-dependent ratios. Keep
        # the representable base effect while explicitly refusing full coverage.
        coverage = "PARTIAL_RUNTIME"

    if sid in _TEMP_TYPE_SELF_HEALS:
        _require_single_self_heal(specs, sid, 5000)
        # Roost's base healing is representable, but BattleEffectSpec has no
        # temporary type suppression/change effect for its Flying-type rule.
        coverage = "PARTIAL_RUNTIME"

    if sid in _SIMPLE_SELF_STAT_BOOSTS:
        stat_id, value = _SIMPLE_SELF_STAT_BOOSTS[sid]
        _require_simple_self_stat_boost(m, specs, sid, stat_id, value)
        # These source-verified moves are exactly one unconditional self stat
        # stage increase and Battle Core executes that effect directly.
        coverage = "RUNTIME_SUPPORTED"

    if sid in _PURE_SELF_STAT_PACKAGES:
        expected_stats = _PURE_SELF_STAT_PACKAGES[sid]
        _require_pure_self_stat_package(m, specs, sid, expected_stats)
        # These source-audited moves are exactly unconditional stat packages on
        # the user. The generic converter already emits the complete SELF package;
        # this branch only certifies that exact shape and coverage.
        coverage = "RUNTIME_SUPPORTED"

    if sid in _AUDITED_DATA_ONLY_UNIQUE:
        _require_audited_data_only_unique(m, specs, sid)
        # These source-verified unique moves require mechanics outside the current
        # generic effect model. Rest needs status replacement and move-specific
        # sleep semantics; Wish needs a persisted delayed heal that follows the
        # user's side through switching. Empty specs are safer than plausible but
        # false immediate effects.
        coverage = "DATA_ONLY"

    if sid in _PARTIAL_UNIQUE_STAT_HEALS:
        _require_strength_sap_partial(m, specs)
        # The target's Attack drop is fully representable and already executes in
        # Battle Core. Healing by the target's current Attack value is not expressible
        # as the current fixed/ratio HEAL effect, so full support would be dishonest.
        coverage = "PARTIAL_RUNTIME"

    if sid in _AUDITED_DATA_ONLY_PROTECTION_CONTACT:
        _require_silk_trap_data_only(m, specs)
        # Silk Trap's source target is USER because it protects the user. The -1
        # Speed stat change applies only to an attacker that makes direct contact.
        # Mapping the source target onto the stat change produced a false SELF -1
        # Speed effect. Battle Core has no protect/contact-trigger effect model, so
        # a no-op DATA_ONLY representation is safer than any unconditional debuff.
        specs = []
        coverage = "DATA_ONLY"

    if sid in _AUDITED_DATA_ONLY_ALLY_STAT:
        stat_id, value = _AUDITED_DATA_ONLY_ALLY_STAT[sid]
        _require_ally_stat_data_only(m, specs, sid, stat_id, value)
        # Aromatic Mist raises a selected ally's Special Defense. The generic
        # converter collapses that unsupported ally target into SELF, which would
        # execute on the wrong creature. Until ally targeting exists, preserve the
        # move as DATA_ONLY with no executable effect rather than lying about target.
        specs = []
        coverage = "DATA_ONLY"

    if sid in _AUDITED_DATA_ONLY_HELD_BERRY_STAT:
        stat_id, value = _AUDITED_DATA_ONLY_HELD_BERRY_STAT[sid]
        _require_held_berry_stat_data_only(m, specs, sid, stat_id, value)
        # Stuff Cheeks may only succeed while the user holds a Berry, consumes that
        # Berry, triggers its effect, and then raises Defense. The current generic
        # effect model cannot require/consume a held Berry, so an unconditional
        # Defense +2 would grant an illegal benefit. Keep the move effect-free until
        # the held-item prerequisite/consumption transaction is represented.
        specs = []
        coverage = "DATA_ONLY"

    if sid in _PARTIAL_USER_AND_ALLIES_STAT:
        stat_id, value = _PARTIAL_USER_AND_ALLIES_STAT[sid]
        _require_user_and_allies_stat_partial(m, specs, sid, stat_id, value)
        changed = _rewrite_effect_target(specs, "modify_stat_stage", "self")
        if changed != 1:
            raise RuntimeError(f"DATA V3 expected one Howl stat effect rewrite, found {changed}")
        # Modern Howl boosts the user and allies. SELF Attack +1 is a faithful
        # executable subset; ally targeting remains outside the current effect
        # model. Never leave the legacy OPPONENT boost in place.
        coverage = "PARTIAL_RUNTIME"

    if sid in _AUDITED_DATA_ONLY_ADJACENT_ALLY_STATS:
        expected_stats = _AUDITED_DATA_ONLY_ADJACENT_ALLY_STATS[sid]
        _require_adjacent_ally_stats_data_only(m, specs, sid, expected_stats)
        # Coaching affects allied Pokémon, not the user, and fails when no adjacent
        # ally exists. Current Battle Core has neither ally targeting nor that
        # adjacency/failure condition. The legacy OPPONENT buffs are actively false,
        # so preserve only the data record until those mechanics exist.
        specs = []
        coverage = "DATA_ONLY"

    if sid in _AUDITED_DATA_ONLY_PLUS_MINUS_SIDE_STATS:
        expected_stats = _AUDITED_DATA_ONLY_PLUS_MINUS_SIDE_STATS[sid]
        _require_plus_minus_side_stats_data_only(m, specs, sid, expected_stats)
        # Gear Up and Magnetic Flux affect only friendly Pokémon whose Ability is
        # Plus or Minus. Current Battle Core cannot target a friendly side with an
        # ability predicate, so any unconditional SELF or OPPONENT boost would be
        # false. Preserve the source data without executable specs.
        specs = []
        coverage = "DATA_ONLY"

    if sid in _SELECTED_TARGET_HEALS:
        changed = _rewrite_effect_target(specs, "heal", "opponent")
        if changed != 1:
            raise RuntimeError(
                f"DATA V3 expected exactly one heal effect for {sid}, found {changed}"
            )
        # Heal Pulse is fully representable by the current single-target battle
        # model. Floral Healing has an additional Grassy Terrain dependency, so
        # its base 1/2 heal is represented but coverage must remain partial.
        coverage = "RUNTIME_SUPPORTED" if sid == "heal_pulse" else "PARTIAL_RUNTIME"

    if sid in _TEAM_TARGET_HEALS:
        # Battle Core currently exposes SELF/OPPONENT only. The user's own heal is
        # a valid subset in singles, but ally-side targeting cannot be represented,
        # so these moves must never claim full runtime coverage.
        coverage = "PARTIAL_RUNTIME"
        if sid == "jungle_healing" and not _has_effect(specs, "cure_status", "self"):
            # The snapshot explicitly says Jungle Healing also cures the user's
            # side's status conditions. Preserve the representable SELF subset;
            # ally curing remains part of the PARTIAL_RUNTIME limitation.
            specs.append({"kind": "cure_status", "target": "self"})

    return (
        specs,
        crit_rate_bp,
        makes_contact,
        coverage,
        override_count,
        unsupported_note,
    )


def __getattr__(name: str):
    return getattr(_legacy, name)
