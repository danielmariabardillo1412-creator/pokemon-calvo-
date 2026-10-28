"""Pinned offline repairs of proven source defects; no guessed atlas cells."""
import hashlib
import io
import json
import math
from pathlib import Path
from PIL import Image

GAP_SHEETS = {
    "PRAS- White BG.png": {
        "commit": "41cc6cfd9b625b4f46cf3a5cb220cc1c3ee788cf",
        "source_sha256": "b274056661a104584b1c6eb5816fe5bc21dc44afc4a065b3cec01723235234cc",
        "source_size": [512, 384], "scale": 1,
        "credit": "Pagefault Games / Pokemon Reborn resource provenance; see visual notebook"},
    "PRAS- Giga Impact Opp BG.png": {
        "commit": "95845e7df6e032423818dd49ecbe317df05af668",
        "source_sha256": "6545ea60c2c46ad75d501cfa933445de73607dbf042dc5ce56dd879c6777eb65",
        "source_size": [256, 192], "scale": 2,
        "credit": "geefuoco / Pagefault Games, correction PR #1584; underlying Pokemon Reborn assets"},
}
PRIORITY_FALLBACK_EXPORTS = {
    "Move:CLANGOROUSSOULBLAZE": "1563fb4c6b237b56c9aff736c2450e8599b5fbd86f20b4eb14d2c4d7ba6ce498",
    "OppMove:CLANGOROUSSOULBLAZE": "ab26682bd98763caf41adb9de96690ac47645c5f9795577ee5f73b10cf48eca4",
}


def sheet_url(name, spec):
    from urllib.parse import quote
    return ("https://raw.githubusercontent.com/pagefaultgames/pokerogue-assets/" + spec["commit"]
            + "/images/battle_anims/" + quote(name))


def load_gap_sheet(name, cache):
    if name not in GAP_SHEETS or cache is None:
        raise ValueError("missing_sheet:" + name)
    spec = GAP_SHEETS[name]
    original = cache / (spec["source_sha256"] + ".png")
    if not original.is_file():
        raise ValueError("missing_pinned_gap_sheet:" + name)
    if hashlib.sha256(original.read_bytes()).hexdigest() != spec["source_sha256"]:
        raise ValueError("gap_sheet_source_changed:" + name)
    with Image.open(original) as image:
        if image.format != "PNG" or list(image.size) != spec["source_size"]:
            raise ValueError("gap_sheet_dimensions:" + name)
        scale = spec["scale"]
        if scale not in (1, 2):
            raise ValueError("gap_sheet_invalid_integer_scale")
        if scale == 1:
            path = original
        else:
            # Restore this supplier's half-resolution BG to the 512x384 canvas.
            # Integer nearest replication only: no invented colors or artwork.
            result = image.convert("RGBA").resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
            buffer = io.BytesIO()
            result.save(buffer, format="PNG")
            data = buffer.getvalue()
            path = cache / (hashlib.sha256(data).hexdigest() + ".png")
            if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != path.stem:
                temporary = path.with_suffix(".tmp")
                temporary.write_bytes(data)
                temporary.replace(path)
    return path, {**spec, "source_url": sheet_url(name, spec), "derived_sha256": path.stem,
                  "policy": "pinned_supplier_sheet_integer_canvas_v1"}


def normalize_priority(animation, frames):
    name = animation.get("@name")
    if name not in PRIORITY_FALLBACK_EXPORTS:
        return None
    fingerprint = hashlib.sha256(json.dumps(animation["@array"], separators=(",", ":")).encode()).hexdigest()
    if fingerprint != PRIORITY_FALLBACK_EXPORTS[name]:
        raise ValueError("priority_fallback_source_changed")
    targets = [c for f in frames for c in f if c is not None and c[25] == 4]
    if not targets:
        raise ValueError("priority_fallback_has_no_cells")
    count = len(targets)
    for cel in targets:
        cel[25] = 1
    return {"policy": "pinned_essentials_else_priority_80_v1", "source_frames_sha256": fingerprint,
            "original_priority": 4, "adapted_priority": 1, "changed_priority_cells": count}


def omit_invisible_missing_layers(layers, graphics):
    """Only missing textures whose EVERY baked use is provably invisible."""
    omitted = []
    names = {v["name"] for f in layers for v in f.values() if v["name"]}
    for name in sorted(names):
        if Path(name).name != name or ".." in name:
            raise ValueError("unsafe_sheet")
        path = graphics / name
        if not path.suffix:
            path = path.with_suffix(".png")
        if path.is_file():
            continue
        uses = [v for f in layers for v in f.values() if v["name"] == name]
        opacities = [v.get("opacity") for v in uses]
        if not all(isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v) and v <= 0 for v in opacities):
            continue
        fingerprint = hashlib.sha256(json.dumps(uses, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        omitted.append({"name": name, "uses": len(uses), "max_opacity": max(opacities),
                        "baked_uses_sha256": fingerprint, "policy": "missing_texture_all_uses_zero_visibility_v1"})
        for state in uses:
            state["name"] = ""
    return omitted
