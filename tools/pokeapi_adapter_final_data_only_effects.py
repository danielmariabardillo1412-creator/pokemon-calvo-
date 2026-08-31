#!/usr/bin/env python3
"""Final Move Effects V3 audit for DATA_ONLY records with executable effects.

Purify, Swallow and Beat Up are the last DATA_ONLY moves that still expose
BattleEffectSpec packages. In all three cases the generated effect is not a faithful
subset of the source mechanic: it removes a mandatory prerequisite/state transaction
or replaces a party-dependent attack with a fixed generic multi-hit action.

Coverage labels do not gate execution. Until Battle Core can model the complete
transaction, these records must remain DATA_ONLY with no executable effect_specs.
"""
from __future__ import annotations


def _slug(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


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


def _require_common(move: dict, sid: str) -> None:
    if int(move.get("priority") or 0) != 0:
        raise RuntimeError(f"DATA V3 final DATA_ONLY priority changed for {sid}")
    if move.get("stat_changes"):
        raise RuntimeError(f"DATA V3 final DATA_ONLY unexpected stat changes for {sid}")


def _require_purify(move: dict, specs: list[dict]) -> None:
    _require_common(move, "purify")
    meta = move.get("meta") or {}
    if (
        int(move.get("id") or 0) != 685
        or (move.get("target") or {}).get("name") != "selected-pokemon"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("pp") or 0) != 20
        or (move.get("generation") or {}).get("name") != "generation-vii"
        or move.get("effect_changes")
        or (meta.get("category") or {}).get("name") != "unique"
        or int(meta.get("healing") or 0) != 50
        or int(meta.get("drain") or 0) != 0
        or int(meta.get("flinch_chance") or 0) != 0
        or int(meta.get("ailment_chance") or 0) != 0
        or int(meta.get("stat_chance") or 0) != 0
    ):
        raise RuntimeError("DATA V3 Purify source contract changed")

    text = _english_text(move)
    if not all(
        token in text
        for token in (
            "cures the target",
            "major status ailment",
            "50%",
            "move will fail",
        )
    ):
        raise RuntimeError("DATA V3 Purify source semantics changed")

    expected = {
        "kind": "heal",
        "target": "self",
        "ratio_basis_points": 5000,
    }
    if len(specs) != 1 or specs[0] != expected:
        raise RuntimeError(f"DATA V3 Purify generated heal changed: {specs}")


def _require_swallow(move: dict, specs: list[dict]) -> None:
    _require_common(move, "swallow")
    meta = move.get("meta") or {}
    if (
        int(move.get("id") or 0) != 256
        or (move.get("target") or {}).get("name") != "user"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("pp") or 0) != 10
        or (move.get("generation") or {}).get("name") != "generation-iii"
        or move.get("effect_changes")
        or (meta.get("category") or {}).get("name") != "heal"
        or int(meta.get("healing") or 0) != 25
        or int(meta.get("drain") or 0) != 0
        or int(meta.get("flinch_chance") or 0) != 0
        or int(meta.get("ailment_chance") or 0) != 0
        or int(meta.get("stat_chance") or 0) != 0
    ):
        raise RuntimeError("DATA V3 Swallow source contract changed")

    text = _english_text(move)
    if not all(
        token in text
        for token in (
            "1/4",
            "1/2",
            "fully after three uses",
            "stored energy is consumed",
            "defense and special defense",
            "move will fail",
        )
    ):
        raise RuntimeError("DATA V3 Swallow source semantics changed")

    expected = {
        "kind": "heal",
        "target": "self",
        "ratio_basis_points": 2500,
    }
    if len(specs) != 1 or specs[0] != expected:
        raise RuntimeError(f"DATA V3 Swallow generated heal changed: {specs}")


def _require_beat_up(move: dict, specs: list[dict]) -> None:
    _require_common(move, "beat_up")
    meta = move.get("meta") or {}
    if (
        int(move.get("id") or 0) != 251
        or (move.get("target") or {}).get("name") != "selected-pokemon"
        or (move.get("damage_class") or {}).get("name") != "physical"
        or int(move.get("accuracy") or 0) != 100
        or int(move.get("pp") or 0) != 10
        or move.get("power") is not None
        or (move.get("generation") or {}).get("name") != "generation-ii"
        or (meta.get("category") or {}).get("name") != "damage"
        or int(meta.get("min_hits") or 0) != 6
        or int(meta.get("max_hits") or 0) != 6
        or int(meta.get("healing") or 0) != 0
        or int(meta.get("drain") or 0) != 0
        or int(meta.get("flinch_chance") or 0) != 0
        or int(meta.get("ailment_chance") or 0) != 0
        or int(meta.get("stat_chance") or 0) != 0
    ):
        raise RuntimeError("DATA V3 Beat Up source contract changed")

    text = _english_text(move)
    if not all(
        token in text
        for token in (
            "every pokémon in the user's party",
            "fainted",
            "major status effect",
            "base stats",
        )
    ):
        raise RuntimeError("DATA V3 Beat Up source semantics changed")

    changes = move.get("effect_changes") or []
    change_text = " ".join(
        str(entry.get("effect") or "")
        for change in changes
        if (change.get("version_group") or {}).get("name") == "black-white"
        for entry in (change.get("effect_entries") or [])
        if (entry.get("language") or {}).get("name") == "en"
    ).lower()
    if not (
        "base attack" in change_text
        and "base defense" in change_text
    ):
        raise RuntimeError("DATA V3 Beat Up Generation V effect change disappeared")

    expected = {
        "kind": "multi_hit",
        "target": "opponent",
        "min_hits": 6,
        "max_hits": 6,
        "children": [],
    }
    if len(specs) != 1 or specs[0] != expected:
        raise RuntimeError(f"DATA V3 Beat Up generated multi-hit changed: {specs}")


def _normalize_summary(move: dict, sid: str) -> None:
    entries = _english_entries(move)
    if len(entries) != 1:
        raise RuntimeError(
            f"DATA V3 expected one English effect entry for {sid}, found {len(entries)}"
        )

    if sid == "purify":
        entries[0]["effect"] = (
            "Cures the selected target's non-volatile status condition and then heals "
            "the user for up to 50% of its maximum HP. If the target has no eligible "
            "status condition, the move fails and the user is not healed."
        )
        entries[0]["short_effect"] = (
            "Cures the target's major status and heals the user by up to 50% only if "
            "the cure succeeds."
        )
    elif sid == "swallow":
        entries[0]["effect"] = (
            "Requires stored Stockpile energy. One, two, or three Stockpile levels heal "
            "25%, 50%, or 100% of the user's maximum HP respectively; using Swallow "
            "consumes the stored levels and removes the associated Stockpile Defense "
            "and Special Defense changes. It fails with no Stockpile energy."
        )
        entries[0]["short_effect"] = (
            "Consumes Stockpile: heals 25%/50%/100% at levels 1/2/3 and fails at level 0."
        )
    elif sid == "beat_up":
        entries[0]["effect"] = (
            "Hits once for the user and each conscious party member without a "
            "non-volatile status condition. From Generation V onward, each strike's "
            "base power depends on that party member's base Attack while damage uses "
            "the Beat Up user's Attack."
        )
        entries[0]["short_effect"] = (
            "Party-dependent multi-hit attack; fainted or statused party members do not contribute."
        )
    else:
        raise RuntimeError(f"DATA V3 unknown final DATA_ONLY move contract: {sid}")


def apply_final_data_only_effects(move: dict, generated: tuple):
    """Neutralize the final unsafe DATA_ONLY specs; pass all other moves through."""
    sid = _slug(str(move.get("name", "")))
    if sid not in {"purify", "swallow", "beat_up"}:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 final DATA_ONLY classification changed for {sid}: {classification}"
        )

    if sid == "purify":
        _require_purify(move, specs)
    elif sid == "swallow":
        _require_swallow(move, specs)
    elif sid == "beat_up":
        _require_beat_up(move, specs)

    _normalize_summary(move, sid)

    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
