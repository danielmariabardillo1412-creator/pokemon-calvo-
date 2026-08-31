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

# Healing semantics that DATA V3 can represent honestly with the current singles
# BattleEffectSpec target model.
_SIMPLE_HEAL_RUNTIME = {
    "heal_order",
    "heal_pulse",
    "milk_drink",
    "recover",
    "slack_off",
    "soft_boiled",
}
_PARTIAL_HEAL_RUNTIME = {
    "floral_healing",  # target heal is modeled; Grassy Terrain boost is not.
    "jungle_healing",  # self heal/cure modeled; ally-wide scope is not.
    "life_dew",  # self heal modeled; ally-wide scope is not.
    "moonlight",  # baseline heal modeled; weather scaling is not.
    "morning_sun",  # baseline heal modeled; weather scaling is not.
    "purify",  # target cure modeled; conditional self-heal dependency is not.
    "roost",  # heal modeled; temporary Flying-type suppression is not.
    "shore_up",  # baseline heal modeled; sandstorm scaling is not.
    "synthesis",  # baseline heal modeled; weather scaling is not.
}
_UNSUPPORTED_HEAL_RUNTIME = {
    "swallow",  # amount/consumption depends on Stockpile state not modeled yet.
}
_TARGET_HEAL_MOVES = {"heal_pulse", "floral_healing"}

# Move-effect audit. Keep exact, already-supported effects executable; retain only
# safe weaker subsets when a beneficial mechanic is missing; remove specs when an
# omitted cost, prerequisite, target filter or state dependency would make the
# runtime move stronger or simply wrong.
_SIMPLE_STAT_RUNTIME = {"growl", "swords_dance"}
_SAFE_PARTIAL_STAT_RUNTIME = {
    "autotomize",  # Speed boost modeled; weight reduction is not.
    "charge",  # Sp. Def boost modeled; next Electric-move boost is not.
    "defense_curl",  # Defense boost modeled; Rollout/Ice Ball state is not.
    "defog",  # evasion drop modeled; field cleanup is not.
    "growth",  # baseline +1/+1 modeled; sun boost is not.
    "howl",  # self boost modeled; ally-wide scope is not.
    "stockpile",  # defensive stages modeled; Stockpile counter/state is not.
    "strength_sap",  # Attack drop modeled; healing from target Attack is not.
    "tar_shot",  # Speed drop modeled; persistent Fire weakness is not.
    "tidy_up",  # Attack/Speed boosts modeled; hazards/Substitute cleanup is not.
}
_UNSAFE_INCOMPLETE_STAT_RUNTIME = {
    "aromatic_mist",  # ally-only target is incorrectly mapped to self.
    "beat_up",  # hit count/damage depend on eligible party members, not fixed 6 hits.
    "captivate",  # opposite-gender prerequisite is absent.
    "clangorous_soul",  # mandatory HP cost is absent.
    "coaching",  # ally-only semantics are incorrectly mapped to opponent.
    "fillet_away",  # mandatory 50% max-HP cost/failure condition is absent.
    "flower_shield",  # requires all-Grass filtering across both sides.
    "gear_up",  # friendly Plus/Minus condition and side targeting are absent.
    "geomancy",  # charge turn is absent.
    "magnetic_flux",  # friendly Plus/Minus condition and side targeting are absent.
    "memento",  # mandatory user faint is absent.
    "minimize",  # minimized-state vulnerability to specific attacks is absent.
    "no_retreat",  # mandatory switch lock is absent.
    "parting_shot",  # mandatory user switch is absent.
    "rototiller",  # requires all-Grass filtering across both sides.
    "silk_trap",  # Protect/contact reaction is absent; legacy stat target is wrong.
    "stuff_cheeks",  # berry requirement/consumption is absent.
    "venom_drench",  # poisoned-target prerequisite is absent.
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


def _rewrite_kind_target(specs: list[dict], kind: str, target: str) -> int:
    changed = 0
    for spec in specs:
        if spec.get("kind") == kind and spec.get("target") != target:
            spec["target"] = target
            changed += 1
        changed += _rewrite_kind_target(spec.get("children", []) or [], kind, target)
    return changed


def _normalize_chance_children(specs: list[dict]) -> int:
    """Keep probability on CHANCE wrappers, matching BattleEffectRegistry's contract.

    The archived converter wrote the same chance on the wrapper and its status/stat
    child. BattleEffectExecutor only rolls the wrapper, but tactical evaluation
    multiplies chance_basis_points at every level, so 10% was evaluated as 1%.
    Only the exact duplicated parent/child pattern is rewritten; nested independent
    chances remain untouched.
    """
    changed = 0
    for spec in specs:
        children = spec.get("children", []) or []
        if spec.get("kind") == "chance":
            parent_bp = int(spec.get("chance_basis_points", 10000) or 10000)
            if parent_bp < 10000:
                for child in children:
                    child_bp = int(child.get("chance_basis_points", 10000) or 10000)
                    if child.get("kind") != "chance" and child_bp == parent_bp:
                        child["chance_basis_points"] = 10000
                        changed += 1
        changed += _normalize_chance_children(children)
    return changed


def _assert_stat_contract(sid: str, specs: list[dict], classification: str) -> None:
    """Fail closed if a curated move-effect correction regresses."""
    if sid == "growl":
        expected = [{
            "kind": "modify_stat_stage", "target": "opponent",
            "stat_id": "attack", "value": -1, "chance_basis_points": 10000,
        }]
        if classification != "RUNTIME_SUPPORTED" or specs != expected:
            raise RuntimeError("DATA V3 Growl stat contract regressed")
    elif sid == "swords_dance":
        expected = [{
            "kind": "modify_stat_stage", "target": "self",
            "stat_id": "attack", "value": 2, "chance_basis_points": 10000,
        }]
        if classification != "RUNTIME_SUPPORTED" or specs != expected:
            raise RuntimeError("DATA V3 Swords Dance stat contract regressed")
    elif sid == "howl":
        expected = [{
            "kind": "modify_stat_stage", "target": "self",
            "stat_id": "attack", "value": 1, "chance_basis_points": 10000,
        }]
        if classification != "PARTIAL_RUNTIME" or specs != expected:
            raise RuntimeError("DATA V3 Howl safe-subset contract regressed")
    elif sid in _UNSAFE_INCOMPLETE_STAT_RUNTIME:
        if classification != "UNSUPPORTED" or specs:
            raise RuntimeError(
                f"DATA V3 unsafe incomplete move remained executable: {sid}"
            )
    elif sid in _SAFE_PARTIAL_STAT_RUNTIME:
        if classification != "PARTIAL_RUNTIME" or not specs:
            raise RuntimeError(f"DATA V3 safe partial contract regressed: {sid}")


def generate_move_specs(move: dict, contact_set: set):
    """Reuse the V2 converter, then apply audited DATA V3 semantic corrections."""
    specs, crit_bp, contact, classification, override_count, unsupported_note = (
        _legacy.generate_move_specs(move, contact_set)
    )
    sid = _legacy.slug(str(move.get("name", "")))

    # Canonical schema convention: conditional probability belongs to the CHANCE
    # wrapper. Removing duplicated child chances preserves executor behavior while
    # making tactical expected-value calculations correct.
    override_count += _normalize_chance_children(specs)

    # Heal Pulse / Floral Healing restore HP to the selected target, not the user.
    if sid in _TARGET_HEAL_MOVES:
        override_count += _rewrite_kind_target(specs, "heal", "opponent")

    # Jungle Healing has a safe self-side subset in singles: heal + cure status.
    # Ally-wide application remains explicitly partial until Battle Core grows a
    # side/team target selector.
    if sid == "jungle_healing":
        specs.append({"kind": "cure_status", "target": "self"})
        override_count += 1

    # Purify can safely model the selected target's cure. Its self heal is
    # conditional on a successful cure; execute_all cannot express that dependency,
    # so remove the misleading unconditional heal until conditional sequencing lands.
    if sid == "purify":
        specs = [{"kind": "cure_status", "target": "opponent"}]
        override_count += 1

    # Swallow's amount depends on Stockpile count and also consumes that state. A
    # fixed 25% heal is not an honest partial model, so expose no executable spec.
    if sid in _UNSUPPORTED_HEAL_RUNTIME:
        specs = []
        classification = "UNSUPPORTED"
        unsupported_note = True
        override_count += 1
    elif sid in _SIMPLE_HEAL_RUNTIME:
        classification = "RUNTIME_SUPPORTED"
    elif sid in _PARTIAL_HEAL_RUNTIME:
        classification = "PARTIAL_RUNTIME"

    # The manual BattleEffectRegistry already implements these exact stat effects;
    # generated V3 specs match it byte-for-byte, so DATA_ONLY was stale metadata.
    if sid in _SIMPLE_STAT_RUNTIME:
        classification = "RUNTIME_SUPPORTED"

    # Howl's source target is user-and-allies. The current singles target model can
    # safely preserve the user's own +1 Attack, but cannot fan out to allies.
    if sid == "howl":
        override_count += _rewrite_kind_target(specs, "modify_stat_stage", "self")

    if sid in _SAFE_PARTIAL_STAT_RUNTIME:
        classification = "PARTIAL_RUNTIME"

    # Do not execute a beneficial effect while silently omitting its mandatory cost,
    # prerequisite or target filter. That would change battle balance, often making
    # the move strictly stronger than canon. Preserve source data, expose no runtime
    # spec, and wait for the required Battle Core primitive.
    if sid in _UNSAFE_INCOMPLETE_STAT_RUNTIME:
        specs = []
        classification = "UNSUPPORTED"
        unsupported_note = True
        override_count += 1

    _assert_stat_contract(sid, specs, classification)
    return specs, crit_bp, contact, classification, override_count, unsupported_note


def __getattr__(name: str):
    return getattr(_legacy, name)
