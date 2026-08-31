#!/usr/bin/env python3
"""Move Effects V3 audit for user boosts with omitted persistent battle state.

Autotomize and Minimize expose a real stat boost, but each also creates persistent
state with battle-relevant consequences. The current Battle Core has neither a
weight-modification state nor a Minimized vulnerability state. Keeping only the
boost can make the runtime move materially stronger than the source mechanic.
"""
from __future__ import annotations


_PERSISTENT_PACKAGES: dict[str, dict[str, int]] = {
    "autotomize": {"speed": 2},
    "minimize": {"evasion": 2},
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
                f"DATA V3 persistent-state move {sid} generated non-stat effect: {spec}"
            )
        if (
            spec.get("target") != "self"
            or int(spec.get("chance_basis_points", 0)) != 10000
        ):
            raise RuntimeError(
                f"DATA V3 persistent-state move {sid} generated wrong-target/conditional stat: {spec}"
            )
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in result:
            raise RuntimeError(
                f"DATA V3 persistent-state move {sid} generated duplicate/invalid stat: {spec}"
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
    return " ".join(parts).lower()


def _require_common(move: dict, sid: str, expected: dict[str, int]) -> None:
    meta = move.get("meta") or {}
    if (
        (move.get("target") or {}).get("name") != "user"
        or (move.get("damage_class") or {}).get("name") != "status"
        or move.get("accuracy") is not None
        or int(move.get("priority") or 0) != 0
    ):
        raise RuntimeError(f"DATA V3 persistent-state source shape changed for {sid}")
    if (meta.get("category") or {}).get("name") != "net-good-stats":
        raise RuntimeError(f"DATA V3 persistent-state category changed for {sid}")
    if (meta.get("ailment") or {}).get("name") not in ("none", "", None):
        raise RuntimeError(f"DATA V3 persistent-state ailment changed for {sid}")
    if any(int(meta.get(key) or 0) != 0 for key in (
        "healing", "drain", "flinch_chance", "ailment_chance", "stat_chance"
    )):
        raise RuntimeError(f"DATA V3 persistent-state metadata changed for {sid}")
    if _source_stats(move) != expected:
        raise RuntimeError(
            f"DATA V3 persistent-state source stats changed for {sid}: {_source_stats(move)}"
        )


def _normalize_autotomize_summary(move: dict) -> None:
    entries = _english_entries(move)
    if len(entries) != 1:
        raise RuntimeError(
            f"DATA V3 expected one English Autotomize effect entry, found {len(entries)}"
        )
    text = _english_effect_text(move)
    if "halves the user’s weight" not in text or "does not stack" not in text:
        raise RuntimeError("DATA V3 Autotomize stale snapshot wording changed")
    entries[0]["effect"] = (
        "Raises the user’s Speed by two stages. Each successful use lowers the "
        "user’s weight by 100 kg, stacking to a minimum of 0.1 kg."
    )
    entries[0]["short_effect"] = (
        "Raises the user’s Speed by two stages and lowers its weight by 100 kg."
    )


def _normalize_minimize_summary(move: dict) -> None:
    entries = _english_entries(move)
    if len(entries) != 1:
        raise RuntimeError(
            f"DATA V3 expected one English Minimize effect entry, found {len(entries)}"
        )
    text = _english_effect_text(move)
    if (
        "evasion by two stages" not in text
        or "stomp" not in text
        or "steamroller" not in text
    ):
        raise RuntimeError("DATA V3 Minimize snapshot semantics changed")
    entries[0]["effect"] = (
        "Raises the user’s evasion by two stages and applies the Minimized state. "
        "Certain moves deal double damage to a Minimized target and, under modern "
        "core-series rules, bypass normal accuracy and evasion checks."
    )
    entries[0]["short_effect"] = (
        "Raises the user’s evasion by two stages and applies the Minimized state."
    )


def apply_user_persistent_state(move: dict, generated: tuple):
    """Validate/neutralize audited persistent-state moves; pass all others through."""
    sid = _slug(str(move.get("name", "")))
    expected = _PERSISTENT_PACKAGES.get(sid)
    if expected is None:
        return generated

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    _require_common(move, sid, expected)
    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 persistent-state classification changed for {sid}: {classification}"
        )
    generated_stats = _generated_stats(specs, sid)
    if len(specs) != len(expected) or generated_stats != expected:
        raise RuntimeError(
            f"DATA V3 persistent-state generated stats changed for {sid}: {generated_stats}"
        )

    if sid == "autotomize":
        _normalize_autotomize_summary(move)
    elif sid == "minimize":
        _normalize_minimize_summary(move)
    else:
        raise RuntimeError(f"DATA V3 unknown persistent-state move contract: {sid}")

    # Autotomize's weight change can be beneficial or detrimental depending on
    # weight-based attacks. Minimize's vulnerability state is an explicit drawback.
    # Keeping only the stat boost can therefore make either move falsely stronger.
    return (
        [],
        crit_bp,
        contact,
        "DATA_ONLY",
        override_count,
        unsupported_note,
    )
