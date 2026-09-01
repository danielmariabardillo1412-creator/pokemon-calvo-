#!/usr/bin/env python3
"""Target-state DATA V3 ability contracts layered over the certified base audit.

This module is deliberately narrow. It delegates every pre-existing ability
classification to pokeapi_ability_runtime_contracts and adds only the source-backed
target-state decisions introduced by the target-state tranche.
"""
from __future__ import annotations

from typing import Iterable

import pokeapi_ability_runtime_contracts as base

RUNTIME_SUPPORTED = base.RUNTIME_SUPPORTED
PARTIAL_RUNTIME = base.PARTIAL_RUNTIME
DATA_ONLY = base.DATA_ONLY

_RUNTIME_TARGET_STATE_IDS = {"bad_dreams", "merciless"}
_DATA_ONLY_TARGET_STATE_IDS = {"rivalry", "stakeout"}


def audited_ids() -> tuple[str, ...]:
    return tuple(sorted(set(base.audited_ids()) | _RUNTIME_TARGET_STATE_IDS))


def classification_counts() -> dict[str, int]:
    counts = dict(base.classification_counts())
    counts[RUNTIME_SUPPORTED] = int(counts.get(RUNTIME_SUPPORTED, 0)) + len(
        _RUNTIME_TARGET_STATE_IDS
    )
    return counts


def classification_for(ability: dict) -> str:
    sid = _slug(str(ability.get("name", "")))
    if sid in _RUNTIME_TARGET_STATE_IDS:
        _validate_source_contract(ability, sid)
        return RUNTIME_SUPPORTED
    if sid in _DATA_ONLY_TARGET_STATE_IDS:
        _validate_source_contract(ability, sid)
        return DATA_ONLY
    return base.classification_for(ability)


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
            f"DATA V3 target-state source semantics changed for {sid}; missing {missing}"
        )


def _require_no_history(ability: dict, sid: str) -> None:
    if ability.get("effect_changes"):
        raise RuntimeError(f"DATA V3 {sid} history changed; re-audit")


def _validate_source_contract(ability: dict, sid: str) -> None:
    if not bool(ability.get("is_main_series", False)):
        raise RuntimeError(f"DATA V3 target-state ability is no longer main-series: {sid}")
    text = _english_text(ability.get("effect_entries"))
    if not text:
        raise RuntimeError(f"DATA V3 target-state ability lost English effect text: {sid}")

    if sid == "bad_dreams":
        if _generation_name(ability) != "generation-iv":
            raise RuntimeError("DATA V3 Bad Dreams generation changed; re-audit")
        _require_tokens(
            text,
            sid,
            ("1/8 of their maximum hp", "after each turn", "while they are asleep"),
        )
        _require_no_history(ability, sid)
        return

    if sid == "merciless":
        if _generation_name(ability) != "generation-vii":
            raise RuntimeError("DATA V3 Merciless generation changed; re-audit")
        _require_tokens(text, sid, ("critical hit", "poisoned targets"))
        _require_no_history(ability, sid)
        return

    if sid == "rivalry":
        if _generation_name(ability) != "generation-iv":
            raise RuntimeError("DATA V3 Rivalry generation changed; re-audit")
        _require_tokens(
            text,
            sid,
            (
                "1.25x as much regular damage",
                "same gender",
                "0.75x as much regular damage",
                "opposite gender",
                "genderless",
            ),
        )
        _require_no_history(ability, sid)
        return

    if sid == "stakeout":
        if _generation_name(ability) != "generation-vii":
            raise RuntimeError("DATA V3 Stakeout generation changed; re-audit")
        _require_tokens(text, sid, ("double power", "switched in this turn"))
        _require_no_history(ability, sid)
        return

    raise RuntimeError(f"DATA V3 unknown target-state ability contract: {sid}")


def _generation_name(ability: dict) -> str:
    return str((ability.get("generation") or {}).get("name", ""))
