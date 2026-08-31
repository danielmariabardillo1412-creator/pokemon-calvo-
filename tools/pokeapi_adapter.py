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


def _has_effect(specs: list[dict], kind: str, target: str | None = None) -> bool:
    for spec in specs:
        if spec.get("kind") == kind and (
            target is None or spec.get("target") == target
        ):
            return True
        children = spec.get("children") or []
        if isinstance(children, list) and _has_effect(children, kind, target):
            return True
    return False


def generate_move_specs(m: dict, contact_set: set):
    """V3 wrapper around the archived move-effect converter.

    Only semantics verified during Move Effects V3 are corrected here. The tuple
    contract remains identical to the archived helper.
    """
    specs, crit_rate_bp, makes_contact, coverage, override_count, unsupported_note = (
        _legacy.generate_move_specs(m, contact_set)
    )
    sid = _legacy.slug(str(m.get("name", "")))

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
