#!/usr/bin/env python3
"""Explicit DATA V3 runtime-support contracts for audited abilities.

This module deliberately classifies only abilities whose immutable PokeAPI source
semantics have been compared with Battle Core. Every other preserved ability stays
DATA_ONLY until its semantic family is audited.

The checks below are fail-fast provenance guards, not text-to-code inference. They
ensure an upstream snapshot change cannot silently leave a stale support label in
canonical DATA V3.
"""
from __future__ import annotations

from typing import Iterable


RUNTIME_SUPPORTED = "RUNTIME_SUPPORTED"
PARTIAL_RUNTIME = "PARTIAL_RUNTIME"
DATA_ONLY = "DATA_ONLY"

_PINCH_TYPES = {
    "blaze": "fire",
    "overgrow": "grass",
    "swarm": "bug",
    "torrent": "water",
}

_CLASSIFICATION = {
    "blaze": RUNTIME_SUPPORTED,
    "overgrow": RUNTIME_SUPPORTED,
    "swarm": RUNTIME_SUPPORTED,
    "torrent": RUNTIME_SUPPORTED,
    "intimidate": PARTIAL_RUNTIME,
    "levitate": PARTIAL_RUNTIME,
    "static": PARTIAL_RUNTIME,
}


def audited_ids() -> tuple[str, ...]:
    return tuple(sorted(_CLASSIFICATION))


def classification_counts() -> dict[str, int]:
    counts = {RUNTIME_SUPPORTED: 0, PARTIAL_RUNTIME: 0, DATA_ONLY: 0}
    for value in _CLASSIFICATION.values():
        counts[value] += 1
    return counts


def classification_for(ability: dict) -> str:
    sid = _slug(str(ability.get("name", "")))
    classification = _CLASSIFICATION.get(sid)
    if classification is None:
        return DATA_ONLY
    _validate_source_contract(ability, sid)
    return classification


def _slug(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def _english_text(entries: Iterable[dict] | None) -> str:
    parts: list[str] = []
    for entry in entries or []:
        if (entry.get("language") or {}).get("name") != "en":
            continue
        parts.append(str(entry.get("effect") or ""))
        parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower().replace("×", "x").replace("’", "'")


def _require_tokens(text: str, sid: str, tokens: tuple[str, ...]) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise RuntimeError(
            f"DATA V3 ability source semantics changed for {sid}; missing {missing}"
        )


def _validate_swarm_history(ability: dict) -> None:
    """Swarm's recorded history changes only its old overworld side effect.

    DATA V3 ability coverage is a battle-runtime claim. Historical source records
    are still guarded here so a future battle-semantic change cannot be mistaken
    for the harmless overworld-only changes currently present in the snapshot.
    """
    changes = ability.get("effect_changes") or []
    if not changes:
        raise RuntimeError("DATA V3 Swarm history unexpectedly disappeared; re-audit")
    for change in changes:
        change_text = _english_text(change.get("effect_entries"))
        if not change_text or "overworld" not in change_text:
            raise RuntimeError(
                "DATA V3 Swarm history is no longer overworld-only; re-audit"
            )
        for battle_token in ("bug-type moves", "1.5x", "damage", "1/3"):
            if battle_token in change_text:
                raise RuntimeError(
                    "DATA V3 Swarm historical battle semantics changed; re-audit"
                )


def _validate_source_contract(ability: dict, sid: str) -> None:
    if not bool(ability.get("is_main_series", False)):
        raise RuntimeError(f"DATA V3 audited ability is no longer main-series: {sid}")
    if (ability.get("generation") or {}).get("name") != "generation-iii":
        raise RuntimeError(f"DATA V3 audited ability generation changed for {sid}")

    text = _english_text(ability.get("effect_entries"))
    if not text:
        raise RuntimeError(f"DATA V3 audited ability lost English effect text: {sid}")

    if sid in _PINCH_TYPES:
        move_type = _PINCH_TYPES[sid]
        _require_tokens(
            text,
            sid,
            (
                "1/3 or less",
                f"{move_type}-type moves",
                "1.5x",
                "damage",
            ),
        )
        if sid == "swarm":
            _validate_swarm_history(ability)
        elif ability.get("effect_changes"):
            # Blaze / Overgrow / Torrent have no historical effect override in the
            # immutable snapshot. If that changes, re-audit before retaining full
            # battle-runtime support.
            raise RuntimeError(f"DATA V3 pinch ability history changed for {sid}")
        return

    if sid == "intimidate":
        _require_tokens(
            text,
            sid,
            (
                "enters battle",
                "attack is lowered by one stage",
                "acquired during a battle",
                "substitute",
            ),
        )
        return

    if sid == "levitate":
        _require_tokens(
            text,
            sid,
            (
                "immune to ground-type moves",
                "spikes",
                "toxic spikes",
                "arena trap",
                "gravity",
                "ingrain",
                "iron ball",
            ),
        )
        return

    if sid == "static":
        _require_tokens(
            text,
            sid,
            (
                "move makes contact",
                "30% chance",
                "paralyzed",
            ),
        )
        return

    raise RuntimeError(f"DATA V3 unknown audited ability contract: {sid}")
