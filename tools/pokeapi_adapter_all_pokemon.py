#!/usr/bin/env python3
"""Move Effects V3 audit for all-pokemon stat moves with type/state predicates.

Flower Shield and Rototiller target all Pokemon on the field, but only eligible
Grass-type Pokemon receive their boosts (and Rototiller additionally requires them
to be grounded in generations where it is usable). The current SELF/OPPONENT-only
effect model cannot express that fan-out/predicate. Legacy conversion incorrectly
collapses the source stat_changes to unconditional OPPONENT boosts, so those specs
must not remain executable.
"""
from __future__ import annotations


_EXPECTED = {
    "flower_shield": {"defense": 1},
    "rototiller": {"attack": 1, "special_attack": 1},
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
                f"DATA V3 all-pokemon move {sid} generated non-stat effect: {spec}"
            )
        if (
            spec.get("target") != "opponent"
            or int(spec.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(
                f"DATA V3 all-pokemon move {sid} generated unexpected stat shape: {spec}"
            )
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in result:
            raise RuntimeError(
                f"DATA V3 all-pokemon move {sid} generated duplicate/invalid stat: {spec}"
            )
        result[stat_id] = int(spec.get("value", 0))
    return result


def _english_entries(move: dict) -> list[dict]:
    return [
        entry
        for entry in (move.get("effect_entries") or [])
        if (entry.get("language") or {}).get("name") == "en"
    ]


def _english_text(move: dict) -> str:
    parts: list[str] = []
    for entry in _english_entries(move):
        parts.append(str(entry.get("effect") or ""))
        parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower().replace("’", "'")


def _require_common(move: dict, sid: str, expected: dict[str, int]) -> None:
    meta = move.get("meta") or {}
    if (
        (move.get("target") or {}).get("name") != "all-pokemon"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("priority") or 0) != 0
        or int(move.get("pp") or 0) != 10
        or (move.get("generation") or {}).get("name") != "generation-vi"
        or move.get("effect_changes")
    ):
        raise RuntimeError(f"DATA V3 all-pokemon source shape changed for {sid}")
    if (
        (meta.get("ailment") or {}).get("name") not in ("none", "", None)
        or int(meta.get("stat_chance") or 0) != 100
        or any(int(meta.get(key) or 0) != 0 for key in (
            "healing", "drain", "flinch_chance", "ailment_chance"
        ))
    ):
        raise RuntimeError(f"DATA V3 all-pokemon metadata changed for {sid}")
    if _source_stats(move) != expected:
        raise RuntimeError(
            f"DATA V3 all-pokemon source stats changed for {sid}: {_source_stats(move)}"
        )
    text = _english_text(move)
    if "all grass pokémon in battle" not in text and "all grass pokemon in battle" not in text:
        raise RuntimeError(f"DATA V3 all-pokemon Grass predicate changed for {sid}")


def _normalize_summary(move: dict, sid: str) -> None:
    entries = _english_entries(move)
    if len(entries) != 1:
        raise RuntimeError(
            f"DATA V3 expected one English all-pokemon entry for {sid}, found {len(entries)}"
        )
    if sid == "flower_shield":
        entries[0]["effect"] = (
            "In generations where it is usable, raises the Defense of every eligible "
            "Grass-type Pokémon on the field by one stage and fails if none are "
            "eligible. It cannot be selected in Generation IX."
        )
        entries[0]["short_effect"] = (
            "Raises Defense of eligible Grass-type Pokémon on the field; unavailable "
            "for selection in Generation IX."
        )
    elif sid == "rototiller":
        entries[0]["effect"] = (
            "In generations where it is usable, raises the Attack and Special Attack "
            "of every eligible grounded Grass-type Pokémon on the field by one stage "
            "and fails if none are eligible. It cannot be selected from Generation "
            "VIII onward."
        )
        entries[0]["short_effect"] = (
            "Raises Attack and Special Attack of eligible grounded Grass-type Pokémon; "
            "unavailable for selection from Generation VIII onward."
        )
    else:
        raise RuntimeError(f"DATA V3 unknown all-pokemon move contract: {sid}")


def apply_all_pokemon(move: dict, generated: tuple):
    """Validate and neutralize audited all-pokemon Grass boosts; pass others through."""
    sid = _slug(str(move.get("name", "")))
    expected = _EXPECTED.get(sid)
    if expected is None:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    _require_common(move, sid, expected)
    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 all-pokemon legacy classification changed for {sid}: {classification}"
        )
    generated_stats = _generated_stats(specs, sid)
    if len(specs) != len(expected) or generated_stats != expected:
        raise RuntimeError(
            f"DATA V3 all-pokemon generated stats changed for {sid}: {generated_stats}"
        )

    _normalize_summary(move, sid)

    # The generated OPPONENT package ignores all-Pokemon fan-out and eligibility
    # predicates and can buff an ineligible opponent while missing eligible allies or
    # the user. Keep the source record but expose no executable approximation.
    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
