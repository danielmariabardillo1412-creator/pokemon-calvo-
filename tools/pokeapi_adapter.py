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
