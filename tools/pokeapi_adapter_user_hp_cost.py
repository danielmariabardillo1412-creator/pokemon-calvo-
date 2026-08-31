#!/usr/bin/env python3
"""Move Effects V3 audit layer for user-target boosts with mandatory HP costs.

These moves currently generate correct stat changes but Battle Core cannot express
an atomic max-HP payment + failure prerequisite. Because DATA_ONLY is not an
execution gate, exposing the stat package alone would grant a false free boost.
"""
from __future__ import annotations


_HP_COST_PACKAGES = {
    "clangorous_soul": {
        "attack": 1,
        "defense": 1,
        "special_attack": 1,
        "special_defense": 1,
        "speed": 1,
    },
    "fillet_away": {
        "attack": 2,
        "special_attack": 2,
        "speed": 2,
    },
}


def _slug(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def _source_stats(move: dict) -> dict[str, int]:
    result: dict[str, int] = {}
    for change in move.get("stat_changes") or []:
        name = str((change.get("stat") or {}).get("name", "")).replace("-", "_")
        if name:
            result[name] = int(change.get("change", 0))
    return result


def _generated_stat_package(specs: list[dict], sid: str) -> dict[str, int]:
    generated: dict[str, int] = {}
    for spec in specs:
        if spec.get("kind") != "modify_stat_stage":
            raise RuntimeError(
                f"DATA V3 HP-cost move {sid} generated non-stat effect: {spec}"
            )
        if (
            spec.get("target") != "self"
            or int(spec.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(
                f"DATA V3 HP-cost move {sid} generated conditional/wrong-target stat: {spec}"
            )
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in generated:
            raise RuntimeError(
                f"DATA V3 HP-cost move {sid} generated duplicate/empty stat: {spec}"
            )
        generated[stat_id] = int(spec.get("value", 0))
    return generated


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            parts.append(str(entry.get("effect") or ""))
            parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower()


def _scarlet_violet_english_flavor(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("flavor_text_entries") or []:
        if (
            (entry.get("language") or {}).get("name") == "en"
            and (entry.get("version_group") or {}).get("name") == "scarlet-violet"
        ):
            parts.append(str(entry.get("flavor_text") or ""))
    return " ".join(parts).lower()


def apply_user_hp_cost(move: dict, generated: tuple):
    """Validate and neutralize audited HP-cost boost moves; pass all others through."""
    sid = _slug(str(move.get("name", "")))
    if sid not in _HP_COST_PACKAGES:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    expected = _HP_COST_PACKAGES[sid]

    if (
        (move.get("target") or {}).get("name") != "user"
        or (move.get("damage_class") or {}).get("name") != "status"
        or int(move.get("priority") or 0) != 0
        or move.get("effect_changes")
    ):
        raise RuntimeError(f"DATA V3 HP-cost source shape changed for {sid}")

    source_stats = _source_stats(move)
    if source_stats != expected:
        raise RuntimeError(
            f"DATA V3 HP-cost source stats changed for {sid}: {source_stats}"
        )

    generated_stats = _generated_stat_package(specs, sid)
    if len(specs) != len(expected) or generated_stats != expected:
        raise RuntimeError(
            f"DATA V3 HP-cost generated stats changed for {sid}: {generated_stats}"
        )

    if sid == "clangorous_soul":
        meta = move.get("meta") or {}
        if (
            int(move.get("accuracy") or 0) != 100
            or (meta.get("category") or {}).get("name") != "net-good-stats"
            or int(meta.get("healing") or 0) != -33
            or int(meta.get("stat_chance") or 0) != 100
        ):
            raise RuntimeError("DATA V3 Clangorous Soul HP-cost metadata changed")
        text = _english_effect_text(move)
        if (
            "loses 33% of its max hp" not in text
            or "fails if the user would faint" not in text
            or "raises all of the user" not in text
        ):
            raise RuntimeError("DATA V3 Clangorous Soul HP-cost semantics changed")
    elif sid == "fillet_away":
        if move.get("accuracy") is not None or move.get("meta") is not None or move.get("effect_entries"):
            raise RuntimeError("DATA V3 Fillet Away source metadata shape changed")
        text = _scarlet_violet_english_flavor(move)
        if (
            "sharply boosts its attack, sp. atk, and speed stats" not in text
            or "using its own hp" not in text
        ):
            raise RuntimeError("DATA V3 Fillet Away HP-cost semantics changed")
    else:
        raise RuntimeError(f"DATA V3 unknown HP-cost move contract: {sid}")

    # The stat package is real, but exposing it without the mandatory max-HP
    # payment/failure transaction would make the move materially stronger than the
    # source mechanic. Preserve the data record and remove executable effects until
    # Battle Core has an appropriate HP-payment primitive.
    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
