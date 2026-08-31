#!/usr/bin/env python3
"""Narrow DATA V3 audit layer for safe user-targeted stateful stat moves.

This layer does not invent or rewrite effects. It verifies exact immutable-source
semantics plus the already-generated SELF stat package before changing coverage.

Policies in this tranche:
- Shell Smash: complete stat transaction -> RUNTIME_SUPPORTED.
- Charge: Special Defense +1 is faithful; Electric-boost state is missing -> PARTIAL_RUNTIME.
- Defense Curl: Defense +1 is faithful; Rollout/Ice Ball boost flag is missing -> PARTIAL_RUNTIME.
- Growth: neutral-weather +1 Attack/+1 SpAtk is faithful; harsh-sun +2/+2 is missing -> PARTIAL_RUNTIME.
"""
from __future__ import annotations

from typing import Any

import pokeapi_adapter_user_audit_chain as user_audit_chain


_POLICIES: dict[str, dict[str, Any]] = {
    "charge": {
        "coverage": "PARTIAL_RUNTIME",
        "stats": {"special_defense": 1},
    },
    "defense_curl": {
        "coverage": "PARTIAL_RUNTIME",
        "stats": {"defense": 1},
    },
    "growth": {
        "coverage": "PARTIAL_RUNTIME",
        "stats": {"attack": 1, "special_attack": 1},
    },
    "shell_smash": {
        "coverage": "RUNTIME_SUPPORTED",
        "stats": {
            "defense": -1,
            "special_defense": -1,
            "attack": 2,
            "special_attack": 2,
            "speed": 2,
        },
    },
}


def _slug(value: str) -> str:
    return value.strip().lower().replace("-", "_").replace(" ", "_")


def _source_stats(move: dict) -> dict[str, int]:
    out: dict[str, int] = {}
    for change in move.get("stat_changes") or []:
        stat_name = str((change.get("stat") or {}).get("name", ""))
        if stat_name:
            out[_slug(stat_name)] = int(change.get("change", 0))
    return out


def _generated_stats(specs: list[dict]) -> dict[str, int]:
    out: dict[str, int] = {}
    for spec in specs:
        if spec.get("kind") != "modify_stat_stage":
            raise RuntimeError(f"DATA V3 user-stateful unexpected generated effect: {spec}")
        if spec.get("target") != "self":
            raise RuntimeError(f"DATA V3 user-stateful expected SELF effect: {spec}")
        if int(spec.get("chance_basis_points", 0)) != 10000:
            raise RuntimeError(f"DATA V3 user-stateful expected deterministic stat effect: {spec}")
        stat_id = str(spec.get("stat_id", ""))
        if not stat_id or stat_id in out:
            raise RuntimeError(f"DATA V3 user-stateful duplicate/invalid stat effect: {spec}")
        out[stat_id] = int(spec.get("value", 0))
    return out


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            parts.append(str(entry.get("effect") or ""))
            parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower()


def _require_source_contract(move: dict, sid: str, expected_stats: dict[str, int]) -> None:
    if (move.get("target") or {}).get("name") != "user":
        raise RuntimeError(f"DATA V3 user-stateful target changed for {sid}")
    if (move.get("damage_class") or {}).get("name") != "status":
        raise RuntimeError(f"DATA V3 user-stateful damage class changed for {sid}")
    if move.get("accuracy") is not None or int(move.get("priority") or 0) != 0:
        raise RuntimeError(f"DATA V3 user-stateful accuracy/priority changed for {sid}")
    if _source_stats(move) != expected_stats:
        raise RuntimeError(
            f"DATA V3 user-stateful source stats changed for {sid}: {_source_stats(move)}"
        )

    text = _english_effect_text(move)
    if sid == "charge":
        if not (
            "special defense by one stage" in text
            and "electric" in text
            and ("doubled" in text or "double" in text)
        ):
            raise RuntimeError("DATA V3 Charge semantic text changed")
    elif sid == "defense_curl":
        if not (
            "defense by one stage" in text
            and "ice ball" in text
            and "rollout" in text
            and "doubled" in text
        ):
            raise RuntimeError("DATA V3 Defense Curl semantic text changed")
    elif sid == "growth":
        if not (
            "attack and special attack by one stage" in text
            and "sunny day" in text
            and "two stages" in text
        ):
            raise RuntimeError("DATA V3 Growth semantic text changed")
    elif sid == "shell_smash":
        if not (
            "attack, special attack, and speed by two stages" in text
            and "defense and special defense by one stage" in text
        ):
            raise RuntimeError("DATA V3 Shell Smash semantic text changed")
    else:
        raise RuntimeError(f"DATA V3 unknown user-stateful safe contract: {sid}")


def _apply_remaining_user_audits(move: dict, generated: tuple):
    return user_audit_chain.apply_user_audits(move, generated)


def apply_user_stateful_safe(move: dict, generated: tuple):
    """Validate/classify safe user-stateful moves, then apply stricter user audits."""
    sid = _slug(str(move.get("name", "")))
    policy = _POLICIES.get(sid)
    if policy is None:
        return _apply_remaining_user_audits(move, generated)

    specs, crit_bp, contact, classification, override_count, unsupported_note = generated
    expected_stats = dict(policy["stats"])

    _require_source_contract(move, sid, expected_stats)
    if classification != "DATA_ONLY":
        raise RuntimeError(
            f"DATA V3 user-stateful legacy classification changed for {sid}: {classification}"
        )
    generated_stats = _generated_stats(specs)
    if generated_stats != expected_stats or len(specs) != len(expected_stats):
        raise RuntimeError(
            f"DATA V3 user-stateful generated stats changed for {sid}: {generated_stats}"
        )

    audited = (
        specs,
        crit_bp,
        contact,
        str(policy["coverage"]),
        override_count,
        unsupported_note,
    )
    return _apply_remaining_user_audits(move, audited)
