"""Explicit, pinned laboratory equivalents. Never claim the native gap is fixed."""
import copy
import hashlib
import json
from types import SimpleNamespace

CHOICES = {
    "brave_bird": ("SKYATTACK", "missing_pattern:1", "flying_attack_equivalent"),
    "supersonic_skystrike_physical": ("SKYATTACK", "missing_pattern:1", "low_priority_flying_equivalent"),
    "supersonic_skystrike_special": ("SKYATTACK", "missing_pattern:1", "low_priority_flying_equivalent"),
    "hex": ("SPITE", "missing_pattern:4", "targeted_ghost_equivalent"),
    # Photon Geyser's large target silhouette was rejected in temporal review.
    # Psybeam is a simpler psychic ring beam, NOT the missing native laser.
    "prismatic_laser": ("PSYBEAM", "missing_pattern:11", "psychic_ring_beam_equivalent_not_native_laser"),
    "rest": ("SLEEPTALK", "missing_pattern:5", "sleep_symbol_equivalent"),
    "twister": ("HURRICANE", "missing_pattern:18", "wind_vortex_equivalent"),
    "whirlwind": ("GUST", "missing_pattern:18", "wind_equivalent_not_switch_animation"),
    "future_sight": ("FUTUREDUMMY", "missing_sheet:PRAS- Darkness BG.png", "native_impact_phase_only_not_preparation"),
    "flower_trick": ("FLOWERTRICK", "missing_sheet:uwu.png", "petal_background_equivalent_only"),
}
SOURCE_HASHES = {
    "Move:SKYATTACK": "a69f683f3e012909ab6ea84168893ad62f0264fac9e02c5d7bc3e11546fa7c14",
    "OppMove:SKYATTACK": "ea02dd5b1acc35ae96c7e0a233aed816ca32c37f0f81adad56ebdc9ab89fa1ba",
    "Move:SPITE": "bfa86c2304a1f11d1efc6497be3e68bb1e9e69dd50d3a73e4260bb9819a20e9f",
    "Move:PSYBEAM": "1f4c8e7f286d76936c7e6d3004925791ba89f4233fa6afcc4cb6a70cb5f6db44",
    "OppMove:PSYBEAM": "84ebcdd2163973200f3de4a643d9218f8188af9249f073fce877139206249ab5",
    "Move:SLEEPTALK": "ef0cc8484e624579cc4abf0170cab353632b983ac5a08c124b5dc95120fd8150",
    "Move:HURRICANE": "f7d49e220635be460d92b5d2a830b2aead71feffdef040a7a48dbfd11c96714e",
    "OppMove:HURRICANE": "f93954cb2400aadeecd76ee9db1d993fc25de375747bd778d7c1e9f9df16f913",
    "Move:GUST": "8be2b6e4dcacd38449ff1fdd5397c81530f5cb0429735c55efa442c2a8636209",
    "Move:FUTUREDUMMY": "69a0d8800b375a0fb2688a380a21c94ea3df287ee220e810fd8e9d0680ad47ff",
    "Move:FLOWERTRICK": "a249c6ba14719bfe63defe5409c0f8c8fce5dd0c7101c18b890dae09926c275f",
}


def fingerprint(attrs):
    return hashlib.sha256(json.dumps(attrs, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def select_equivalent(move_id, names, primary_failure):
    if move_id not in CHOICES or CHOICES[move_id][1] != primary_failure:
        raise ValueError(primary_failure)
    label, _, kind = CHOICES[move_id]
    result = []
    for side in ("back", "front"):
        name = ("OppMove:" if side == "front" and names.get("OppMove:" + label) else "Move:") + label
        matches = names.get(name, [])
        if len(matches) != 1:
            raise ValueError("equivalent_source_missing_or_ambiguous:" + name)
        source = matches[0].attrs
        sha = fingerprint(source)
        if sha != SOURCE_HASHES.get(name):
            raise ValueError("equivalent_source_changed:" + name)
        attrs = copy.deepcopy(source)
        modifications = []
        if move_id == "flower_trick":
            matches = [t for t in attrs.get("@timing", []) if t.get("@name") == "uwu.png" and t.get("@timingType") == 1]
            if len(matches) != 1:
                raise ValueError("equivalent_background_source_changed")
            matches[0]["@name"] = "PRAS- Petal BG.png"
            modifications = [{"field": "timing_background_name", "from": "uwu.png", "to": "PRAS- Petal BG.png"}]
        metadata = {"policy": "explicit_pinned_visual_equivalent_v1", "kind": kind,
            "primary_source_status": "quarantined", "primary_source_issue": primary_failure,
            "source_name": name, "source_sha256": sha, "source_modifications": modifications,
            "native_gap_fixed": False, "mechanics_enabled": False}
        result.append((side, SimpleNamespace(attrs=attrs), metadata))
    return result
