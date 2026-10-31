"""Reviewed art substitutions, distinct from missing-source/native-gap fallbacks."""
import copy
from types import SimpleNamespace
from move_visual_equivalents import fingerprint

ART_CHOICES = {
    "armor_cannon": ("ARMORCANNON", "FLAMEBURST", "rectangular_poison_motif_in_native_fire_impact"),
    "max_flutterby": ("SAVAGESPINOUT", "SILVERWIND", "unrelated_pokemon_embedded_in_previous_max_equivalent"),
}
REJECTED_HASHES = {
    "Move:ARMORCANNON": "e976e05d1e2f52ba5446002c940bf93af0e3c5be81a610df024d7de4060c10c4",
    "Move:SAVAGESPINOUT": "c5d295dee3d059e868d44dc98e4c18e7284a7832ec7fa663eae01cff187a3ed6",
    "OppMove:SAVAGESPINOUT": "af3b5775a5719718e0625c2fa731e43ea2fe669afce55df61d2d611b20270f8f",
}
SOURCE_HASHES = {
    "Move:FLAMEBURST": "50bb71761655235ec6a8699230674c10e901ec605d34756d8bea2bd5f2da2cca",
    "OppMove:FLAMEBURST": "0f4f20515f1119972447fa57bcec48ace5b291c15585fc77562517af7ce51395",
    "Move:SILVERWIND": "386345ddd7e9bec4fdd2716bb18311135059e956d019088fb9996986e47e106d",
}


def _pinned(names, name, hashes):
    matches = names.get(name, [])
    if len(matches) != 1:
        raise ValueError("art_source_missing_or_ambiguous:" + name)
    attrs = matches[0].attrs
    if fingerprint(attrs) != hashes.get(name):
        raise ValueError("art_source_changed:" + name)
    return attrs


def select_art_choice(move_id, names):
    if move_id not in ART_CHOICES:
        raise ValueError("unlisted_art_substitution")
    previous, selected, reason = ART_CHOICES[move_id]
    rows = []
    for side in ("back", "front"):
        old_name = ("OppMove:" if side == "front" and names.get("OppMove:" + previous) else "Move:") + previous
        old = _pinned(names, old_name, REJECTED_HASHES)
        name = ("OppMove:" if side == "front" and names.get("OppMove:" + selected) else "Move:") + selected
        attrs = _pinned(names, name, SOURCE_HASHES)
        metadata = {"policy": "explicit_pinned_art_choice_v1", "reason": reason,
            "source_name": name, "source_sha256": fingerprint(attrs), "source_modifications": [],
            "replaced_source_name": old_name, "replaced_source_sha256": fingerprint(old),
            "replaced_source_status": "renderable_but_art_rejected", "native_source_repaired": False,
            "mechanics_enabled": False, "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL"}
        rows.append((side, SimpleNamespace(attrs=copy.deepcopy(attrs)), metadata))
    return rows
