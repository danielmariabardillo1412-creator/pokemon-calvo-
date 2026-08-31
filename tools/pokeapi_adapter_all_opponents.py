#!/usr/bin/env python3
"""Move Effects V3 audit for all-opponents stat moves.

The current battle model is singles, so an all-adjacent-opponents base effect can
faithfully collapse to OPPONENT when the move has no unsupported intrinsic
predicate. Conditional moves remain effect-free until those predicates exist.
"""
from __future__ import annotations

from typing import Any

import pokeapi_adapter_user_hp_cost as user_hp_cost

_SIMPLE_BASE_EFFECTS: dict[str, tuple[int, int, dict[str, int]]] = {
    # move_id: (source accuracy, source stat_chance, exact current stat package)
    "growl": (100, 0, {"attack": -1}),
    "leer": (100, 100, {"defense": -1}),
    "string_shot": (95, 0, {"speed": -2}),
    "sweet_scent": (100, 0, {"evasion": -2}),
    "tail_whip": (100, 0, {"defense": -1}),
}

_CONDITIONAL_EFFECTS: dict[str, tuple[int, int, dict[str, int]]] = {
    "captivate": (100, 0, {"special_attack": -2}),
    "venom_drench": (
        100,
        100,
        {"attack": -1, "special_attack": -1, "speed": -1},
    ),
    "cotton_spore": (100, 0, {"speed": -2}),
}


def _source_stats(move: dict) -> dict[str, int]:
    result: dict[str, int] = {}
    for change in move.get("stat_changes") or []:
        stat_name = (change.get("stat") or {}).get("name")
        if stat_name:
            result[str(stat_name).replace("-", "_")] = int(change.get("change", 0))
    return result


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            parts.append(str(entry.get("effect") or ""))
            parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower()


def _generated_stats(specs: list[dict]) -> dict[str, int]:
    result: dict[str, int] = {}
    for spec in specs:
        if spec.get("kind") != "modify_stat_stage":
            raise RuntimeError(f"DATA V3 all-opponents generated non-stat effect: {spec}")
        if spec.get("target") != "opponent" or int(spec.get("chance_basis_points", 0)) != 10000:
            raise RuntimeError(f"DATA V3 all-opponents generated wrong stat shape: {spec}")
        result[str(spec.get("stat_id", ""))] = int(spec.get("value", 0))
    return result


def _require_common(
    move: dict,
    specs: list[dict],
    sid: str,
    expected_accuracy: int,
    expected_stat_chance: int,
    expected_stats: dict[str, int],
) -> None:
    meta = move.get("meta") or {}
    if (move.get("target") or {}).get("name") != "all-opponents":
        raise RuntimeError(f"DATA V3 all-opponents target changed for {sid}")
    if (move.get("damage_class") or {}).get("name") != "status":
        raise RuntimeError(f"DATA V3 all-opponents damage class changed for {sid}")
    if int(move.get("accuracy") or 0) != expected_accuracy or int(move.get("priority") or 0) != 0:
        raise RuntimeError(f"DATA V3 all-opponents accuracy/priority changed for {sid}")
    if move.get("effect_changes"):
        raise RuntimeError(f"DATA V3 all-opponents effect history changed for {sid}")
    if (meta.get("category") or {}).get("name") != "net-good-stats":
        raise RuntimeError(f"DATA V3 all-opponents category changed for {sid}")
    if (meta.get("ailment") or {}).get("name") not in ("none", "", None):
        raise RuntimeError(f"DATA V3 all-opponents ailment changed for {sid}")
    if int(meta.get("stat_chance") or 0) != expected_stat_chance:
        raise RuntimeError(f"DATA V3 all-opponents stat chance changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 all-opponents metadata changed for {sid}")
    if _source_stats(move) != expected_stats:
        raise RuntimeError(
            f"DATA V3 all-opponents source stats changed for {sid}: {_source_stats(move)}"
        )
    if len(specs) != len(expected_stats) or _generated_stats(specs) != expected_stats:
        raise RuntimeError(
            f"DATA V3 all-opponents generated stats changed for {sid}: {specs}"
        )


def _normalize_sweet_scent_summary(move: dict) -> None:
    """Align stale prose with the snapshot's current structured Evasion -2 value."""
    changed = 0
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") != "en":
            continue
        entry["effect"] = "Lowers the target’s evasion by two stages."
        entry["short_effect"] = "Lowers the target’s evasion by two stages."
        changed += 1
    if changed != 1:
        raise RuntimeError(
            f"DATA V3 expected one English Sweet Scent effect entry, found {changed}"
        )


def apply_all_opponents(
    move: dict,
    generated: tuple[list[dict], int, bool, str, int, Any],
) -> tuple[list[dict], int, bool, str, int, Any]:
    specs, crit_rate_bp, makes_contact, coverage, override_count, unsupported_note = generated
    sid = str(move.get("name", "")).replace("-", "_")

    if sid in _SIMPLE_BASE_EFFECTS:
        accuracy, stat_chance, expected_stats = _SIMPLE_BASE_EFFECTS[sid]
        _require_common(move, specs, sid, accuracy, stat_chance, expected_stats)
        if sid == "sweet_scent":
            _normalize_sweet_scent_summary(move)
        # In the current singles model there is exactly one opposing active target.
        # These five moves have a complete unconditional base stat effect, so the
        # generated OPPONENT package is faithful. Ability-driven immunities remain
        # part of the separate ability interaction audit.
        coverage = "RUNTIME_SUPPORTED"

    elif sid in _CONDITIONAL_EFFECTS:
        accuracy, stat_chance, expected_stats = _CONDITIONAL_EFFECTS[sid]
        _require_common(move, specs, sid, accuracy, stat_chance, expected_stats)
        text = _english_effect_text(move)

        if sid == "captivate":
            if "opposite gender" not in text or "move will fail" not in text:
                raise RuntimeError("DATA V3 Captivate gender predicate changed")
            # The engine has no move-effect gender predicate. An unconditional
            # SpAtk -2 would affect same-gender and genderless targets illegally.
            specs = []
            coverage = "DATA_ONLY"

        elif sid == "venom_drench":
            if "if it is poisoned" not in text:
                raise RuntimeError("DATA V3 Venom Drench poison predicate changed")
            # The generated -1/-1/-1 package currently ignores the required
            # poisoned-target predicate. Never expose it unconditionally.
            specs = []
            coverage = "DATA_ONLY"

        elif sid == "cotton_spore":
            # Public core-series mechanics classify Cotton Spore as a powder/spore
            # move. From Gen VI onward Grass types are intrinsically immune, even
            # before considering Overcoat or Safety Goggles. BattleEffectSpec has
            # no powder/type target predicate, so unconditional Speed -2 is unsafe.
            specs = []
            coverage = "DATA_ONLY"

    audited = (
        specs,
        crit_rate_bp,
        makes_contact,
        coverage,
        override_count,
        unsupported_note,
    )
    return user_hp_cost.apply_user_hp_cost(move, audited)
