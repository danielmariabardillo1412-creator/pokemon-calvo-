#!/usr/bin/env python3
"""Move Effects V3 audit for user boosts with mandatory temporal/state transactions.

Geomancy and No Retreat currently generate stat changes that are individually real,
but the current Battle Core cannot represent the inseparable charge/trapping state.
Because DATA_ONLY is not an execution gate, leaving those boosts executable would
make the runtime moves materially stronger than their source mechanics.
"""
from __future__ import annotations


_MANDATORY_STATE_PACKAGES: dict[str, dict[str, int]] = {
    "geomancy": {
        "special_attack": 2,
        "special_defense": 2,
        "speed": 2,
    },
    "no_retreat": {
        "attack": 1,
        "defense": 1,
        "special_attack": 1,
        "special_defense": 1,
        "speed": 1,
    },
}


def _slug(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def _source_stats(move: dict) -> dict[str, int]:
    result: dict[str, int] = {}
    for change in move.get("stat_changes") or []:
        name = _slug(str((change.get("stat") or {}).get("name", "")))
        if name:
            result[name] = int(change.get("change", 0))
    return result


def _generated_stats(specs: list[dict], sid: str) -> dict[str, int]:
    result: dict[str, int] = {}
    for spec in specs:
        if spec.get("kind") != "modify_stat_stage":
            raise RuntimeError(
                f"DATA V3 mandatory-state move {sid} generated non-stat effect: {spec}"
            )
        if (
            spec.get("target") != "self"
            or int(spec.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(
                f"DATA V3 mandatory-state move {sid} generated wrong-target/conditional stat: {spec}"
            )
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in result:
            raise RuntimeError(
                f"DATA V3 mandatory-state move {sid} generated duplicate/invalid stat: {spec}"
            )
        result[stat_id] = int(spec.get("value", 0))
    return result


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            parts.append(str(entry.get("effect") or ""))
            parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower()


def _require_common(move: dict, sid: str, expected: dict[str, int]) -> None:
    meta = move.get("meta") or {}
    if (
        (move.get("target") or {}).get("name") != "user"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("priority") or 0) != 0
        or move.get("effect_changes")
    ):
        raise RuntimeError(f"DATA V3 mandatory-state source shape changed for {sid}")
    if (meta.get("category") or {}).get("name") != "net-good-stats":
        raise RuntimeError(f"DATA V3 mandatory-state category changed for {sid}")
    if (meta.get("ailment") or {}).get("name") not in ("none", "", None):
        raise RuntimeError(f"DATA V3 mandatory-state ailment changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance"
    )):
        raise RuntimeError(f"DATA V3 mandatory-state metadata changed for {sid}")
    if _source_stats(move) != expected:
        raise RuntimeError(
            f"DATA V3 mandatory-state source stats changed for {sid}: {_source_stats(move)}"
        )


def apply_user_mandatory_state(move: dict, generated: tuple):
    """Validate and neutralize audited mandatory-state moves; pass others through."""
    sid = _slug(str(move.get("name", "")))
    expected = _MANDATORY_STATE_PACKAGES.get(sid)
    if expected is None:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    _require_common(move, sid, expected)

    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 mandatory-state classification changed for {sid}: {classification}"
        )
    generated_stats = _generated_stats(specs, sid)
    if len(specs) != len(expected) or generated_stats != expected:
        raise RuntimeError(
            f"DATA V3 mandatory-state generated stats changed for {sid}: {generated_stats}"
        )

    meta = move.get("meta") or {}
    text = _english_effect_text(move)
    if sid == "geomancy":
        if int(meta.get("stat_chance") or 0) != 0:
            raise RuntimeError("DATA V3 Geomancy stat chance changed")
        if not (
            "takes one turn to charge" in text
            and "special attack" in text
            and "special defense" in text
            and "speed" in text
            and "two stages" in text
        ):
            raise RuntimeError("DATA V3 Geomancy charge semantics changed")
    elif sid == "no_retreat":
        if int(move.get("effect_chance") or 0) != 100 or int(meta.get("stat_chance") or 0) != 100:
            raise RuntimeError("DATA V3 No Retreat effect/stat chance changed")
        if not (
            "prevents user from switching out" in text
            and "raises all of the user" in text
            and "fails if the user already" in text
        ):
            raise RuntimeError("DATA V3 No Retreat trapping/reuse semantics changed")
    else:
        raise RuntimeError(f"DATA V3 unknown mandatory-state move contract: {sid}")

    # The generated boosts are real only as part of a larger transaction:
    # - Geomancy requires a charge turn (or a consumed Power Herb interaction).
    # - No Retreat applies persistent switch/escape restriction and reuse state.
    # The current effect model cannot represent those transactions, so exposing the
    # stat package alone would grant a materially stronger move.
    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
