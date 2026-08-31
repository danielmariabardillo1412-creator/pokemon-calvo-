#!/usr/bin/env python3
"""Move Effects V3 audit for final user-target stat moves with inseparable state/prerequisites.

Extreme Evoboost, Stockpile and Tidy Up expose real stat changes, but executing only
those changes removes an essential prerequisite, capped state transaction or
bilateral field cleanup. Coverage labels do not gate execution, so their generated
stat specs must remain hidden until Battle Core can reproduce the complete move.
"""
from __future__ import annotations


_TERMINAL_PACKAGES: dict[str, dict[str, int]] = {
    "extreme_evoboost": {
        "attack": 2,
        "defense": 2,
        "special_attack": 2,
        "special_defense": 2,
        "speed": 2,
    },
    "stockpile": {
        "defense": 1,
        "special_defense": 1,
    },
    "tidy_up": {
        "attack": 1,
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
                f"DATA V3 terminal-user move {sid} generated non-stat effect: {spec}"
            )
        if (
            spec.get("target") != "self"
            or int(spec.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(
                f"DATA V3 terminal-user move {sid} generated wrong-target/conditional stat: {spec}"
            )
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in result:
            raise RuntimeError(
                f"DATA V3 terminal-user move {sid} generated duplicate/invalid stat: {spec}"
            )
        result[stat_id] = int(spec.get("value", 0))
    return result


def _english_entries(move: dict) -> list[dict]:
    return [
        entry
        for entry in (move.get("effect_entries") or [])
        if (entry.get("language") or {}).get("name") == "en"
    ]


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in _english_entries(move):
        parts.append(str(entry.get("effect") or ""))
        parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower().replace("’", "'")


def _version_flavor(move: dict, version_group: str) -> str:
    parts: list[str] = []
    for entry in move.get("flavor_text_entries") or []:
        if (
            (entry.get("language") or {}).get("name") == "en"
            and (entry.get("version_group") or {}).get("name") == version_group
        ):
            parts.append(str(entry.get("flavor_text") or ""))
    return " ".join(parts).lower().replace("’", "'")


def _require_common(move: dict, sid: str, expected: dict[str, int]) -> None:
    if (
        (move.get("target") or {}).get("name") != "user"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("priority") or 0) != 0
    ):
        raise RuntimeError(f"DATA V3 terminal-user source shape changed for {sid}")
    if _source_stats(move) != expected:
        raise RuntimeError(
            f"DATA V3 terminal-user source stats changed for {sid}: {_source_stats(move)}"
        )


def _normalize_extreme_evoboost(move: dict) -> None:
    if (
        (move.get("generation") or {}).get("name") != "generation-vii"
        or int(move.get("pp") or 0) != 1
        or int(move.get("effect_chance") or 0) != 100
        or move.get("effect_changes")
    ):
        raise RuntimeError("DATA V3 Extreme Evoboost source metadata changed")
    meta = move.get("meta") or {}
    if (
        (meta.get("category") or {}).get("name") != "net-good-stats"
        or int(meta.get("stat_chance") or 0) != 100
    ):
        raise RuntimeError("DATA V3 Extreme Evoboost source meta changed")
    entries = _english_entries(move)
    text = _english_effect_text(move)
    if len(entries) != 1 or "all of the user's stats by two stages" not in text:
        raise RuntimeError("DATA V3 Extreme Evoboost source semantics changed")
    entries[0]["effect"] = (
        "Eevee's exclusive Z-Move, derived from Last Resort, raises the user's Attack, "
        "Defense, Special Attack, Special Defense, and Speed by two stages. It is not "
        "a normally selectable move in Generation VIII onward."
    )
    entries[0]["short_effect"] = (
        "Eevee's exclusive Z-Move; raises five battle stats by two stages and is not "
        "normally selectable from Generation VIII onward."
    )


def _normalize_stockpile(move: dict) -> None:
    if int(move.get("pp") or 0) != 20:
        raise RuntimeError("DATA V3 Stockpile PP changed")
    meta = move.get("meta") or {}
    if (
        (meta.get("category") or {}).get("name") != "unique"
        or int(meta.get("stat_chance") or 0) != 0
    ):
        raise RuntimeError("DATA V3 Stockpile meta changed")
    entries = _english_entries(move)
    text = _english_effect_text(move)
    if (
        len(entries) != 1
        or "up to three levels of energy can be stored" not in text
        or "spit up and swallow" not in text
        or "lost if the user leaves the field" not in text
    ):
        raise RuntimeError("DATA V3 Stockpile source semantics changed")
    entries[0]["short_effect"] = (
        "Stores one Stockpile level (maximum three) and raises Defense and Special "
        "Defense by one stage; Spit Up or Swallow consume the stored levels and the "
        "associated Stockpile stat boosts."
    )


def _normalize_tidy_up(move: dict) -> None:
    if (
        (move.get("generation") or {}).get("name") != "generation-ix"
        or int(move.get("pp") or 0) != 10
        or int(move.get("power") or 0) != 0
        or move.get("meta") is not None
        or move.get("effect_entries")
        or move.get("effect_changes")
    ):
        raise RuntimeError("DATA V3 Tidy Up source metadata shape changed")
    flavor = _version_flavor(move, "scarlet-violet")
    if not all(
        token in flavor
        for token in (
            "spikes",
            "stealth rock",
            "sticky web",
            "toxic spikes",
            "substitute",
            "attack and speed",
        )
    ):
        raise RuntimeError("DATA V3 Tidy Up Scarlet/Violet semantics changed")
    move["effect_entries"] = [
        {
            "effect": (
                "Raises the user's Attack and Speed by one stage and removes Spikes, "
                "Stealth Rock, Sticky Web, Toxic Spikes, and Substitute from both "
                "sides of the field."
            ),
            "short_effect": (
                "Raises Attack and Speed by one stage and clears hazards and "
                "Substitute from both sides."
            ),
            "language": {"name": "en", "url": "/api/v2/language/9/"},
        }
    ]


def apply_user_terminal_state(move: dict, generated: tuple):
    """Validate/neutralize the final audited user stat moves; pass others through."""
    sid = _slug(str(move.get("name", "")))
    expected = _TERMINAL_PACKAGES.get(sid)
    if expected is None:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    _require_common(move, sid, expected)
    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 terminal-user classification changed for {sid}: {classification}"
        )
    generated_stats = _generated_stats(specs, sid)
    if len(specs) != len(expected) or generated_stats != expected:
        raise RuntimeError(
            f"DATA V3 terminal-user generated stats changed for {sid}: {generated_stats}"
        )

    if sid == "extreme_evoboost":
        _normalize_extreme_evoboost(move)
    elif sid == "stockpile":
        _normalize_stockpile(move)
    elif sid == "tidy_up":
        _normalize_tidy_up(move)
    else:
        raise RuntimeError(f"DATA V3 unknown terminal-user move contract: {sid}")

    # Extreme Evoboost requires a Z-Move transaction, Stockpile requires a capped
    # persistent counter coupled to Spit Up/Swallow, and Tidy Up performs bilateral
    # field cleanup. Keeping only their stat gains would create stronger fake moves.
    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
