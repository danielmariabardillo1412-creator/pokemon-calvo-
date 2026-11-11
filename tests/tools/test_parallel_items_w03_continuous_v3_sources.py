#!/usr/bin/env python3
"""W03 V3 Fase A. Audit only real local PokéAPI producers; no invented IDs."""
import json
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data/normalized/pokemon_api.json"
RAW = ROOT / "data/raw/pokemon_api.json"
VARIANTS = ROOT / "config/pokemon_variants_v1.json"

def read(p):
    return json.loads(p.read_text(encoding="utf-8"))

def keyed(data):
    if isinstance(data, dict):
        return data
    return {x["id"]: x for x in data if isinstance(x, dict) and "id" in x}

def source_summary():
    dataset = read(DATA)
    assert isinstance(dataset, dict), "normalized source must be a JSON object"
    species = keyed(dataset["species"])
    assert len(species) >= 500, "canonical species catalog unexpectedly small"
    variants_data = read(VARIANTS)
    overlay = keyed(variants_data.get("regional_species", {}))
    merged = {**species, **overlay}
    print("W03_V3_SOURCE dataset_keys=" + repr(sorted(dataset.keys())))
    print("W03_V3_SOURCE catalog_species=%d regional_variants=%d" % (len(species),len(overlay)))
    sample = ["jigglypuff","nidorina","clefairy","munna","mewtwo","stakataka","nihilego","celesteela","eternatus"]
    for sid in sample:
        row = merged.get(sid, {})
        if not isinstance(row, dict): continue
        meta = row.get("source_metadata") or {}
        evo = [e for e in row.get("evolutions",[]) if isinstance(e,dict) and ("moon" in str(e.get("item_id","")) or "stone" in str(e.get("item_id","")))]
        print("W03_V3_SOURCE species=%s meta=%s evo_stones=%s capture_rate=%s" %
              (sid,repr(meta),repr(evo),repr(row.get("capture_rate"))))
    weights = []
    tags = []
    for sid,row in merged.items():
        if not isinstance(row,dict): continue
        meta = row.get("source_metadata") or {}
        for key in ("weight","weight_hg","weight_kg","weight_hectograms","pokemon_weight"):
            if key in meta or key in row:
                weights.append((sid,key,meta.get(key,row.get(key))))
        for key in ("is_ultra_beast","ultra_beast","ultra_beast_flag","category","classification","species_category"):
            if key in meta or key in row: tags.append((sid,key,meta.get(key,row.get(key))))
    print("W03_V3_SOURCE runtime_weight_fields=%s count=%d" %(repr(weights[:7]),len(weights)))
    print("W03_V3_SOURCE ultra_candidate_fields=%s count=%d" %(repr(tags[:10]),len(tags)))
    moon=[]
    for sid,row in merged.items():
        if not isinstance(row,dict):continue
        for ev in row.get("evolutions",[]):
            if isinstance(ev,dict) and ev.get("item_id") in ("moon_stone","moon-stone"):
                moon.append((sid,ev.get("species_id"),ev.get("trigger"),ev.get("version_group"),ev.get("conditions")))
    print("W03_V3_SOURCE moon_evolutions=%s" % repr(moon[:60]))
    print("W03_V3_SOURCE moon_count=%d" %len(moon))

    # Selection policy is independent from capture odds: never generate an
    # excluded source species merely to obtain a boosted Ball test.
    randomlock = read(ROOT / "config/randomlock_content_v1.json")
    assert randomlock.get("profile_id") == "randomlock_v1", "wrong Randomlock profile"
    forbidden = set(randomlock.get("excluded_species_ids", []))
    invalid_moon = sorted({sid for sid,*_ in moon} & forbidden)
    print("W03_V3_SOURCE randomlock_moon_denied=%s" % repr(invalid_moon))
    assert not invalid_moon, "Moon source includes a Randomlock-excluded species"
    # The upstream PokeAPI pokemon endpoint keeps hectogram weight, but the
    # battle DefinitionCatalog species do NOT contain it; do not invent a
    # multiplier or read massive source files at capture time.
    original = read(ROOT / "data/api/v2/pokemon/35/index.json")
    assert original.get("id") == 35 and original.get("name") == "clefairy"
    assert original.get("weight") == 75, "upstream weight must be in hectograms"
    print("W03_V3_SOURCE raw_pokeapi_weight_clefairy_hg=%d runtime=ABSENT" %
          original["weight"])
    assert not weights, "re-evaluate Heavy Ball if trusted runtime weight appears"
    assert not tags, "re-evaluate Beast Ball if canonical Ultra Beast flag appears"

    if RAW.exists():
        raw = read(RAW)
        print("W03_V3_SOURCE raw_root=%s raw_keys=%s" %
              (type(raw).__name__, repr(list(raw.keys())[:30]) if isinstance(raw,dict) else "list"))
        if isinstance(raw,dict):
            for key in list(raw.keys())[:12]:
                d=raw[key]
                print("W03_V3_SOURCE raw_bucket=%s type=%s count=%s" % (key,type(d).__name__,len(d) if hasattr(d,"__len__") else -1))
    assert all(isinstance(row.get("source_metadata",{}),dict) for row in species.values())
    assert len(merged)>=len(species)
    print("W03_V3_SOURCE PASS checked=%d moon=%d runtime_weight=%d ultra_fields=%d" %
          (len(merged),len(moon),len(weights),len(tags)))
if __name__=="__main__":
    source_summary()
