#!/usr/bin/env python3
"""W04 TANDA02 narrow canonical form producer contract (static gate only).
Godot runner supplies real gameplay/SaveV2 positive and negative evidence.
"""
import csv
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs/coordination/items_parallel_v1/reports/W04"
checks = 0

def test(value, desc):
    global checks
    if not value:
        raise AssertionError(desc)
    checks += 1

def jload(rel):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))

def text_file(rel):
    return (ROOT / rel).read_text(encoding="utf-8")

config = jload("config/pokemon_variants_v1.json")
regional = config["regional_species"]["slowpoke_galar"]
meta = regional["source_metadata"]
test(regional["id"] == "slowpoke_galar" and meta["base_species_id"] == "slowpoke"
     and meta["regional_form"] == "galar" and meta["source_pokemon_id"] == 10164,
     "Factory has a truly regional catalog-selected species")
pokemon = jload("data/api/v2/pokemon/10164/index.json")
form = jload("data/api/v2/pokemon-form/10323/index.json")
test(pokemon["name"] == "slowpoke-galar" and pokemon["species"]["name"] == "slowpoke"
     and {"name": "slowpoke-galar", "url": "/api/v2/pokemon-form/10323/"} in pokemon["forms"],
     "PokeAPI pokemon 10164 references actual canonical form")
test(form["name"] == "slowpoke-galar" and form["id"] == 10323
     and form["pokemon"]["name"] == "slowpoke-galar" and form["form_name"] == "galar",
     "PokeAPI form10323 anchors exact slug")
for path in [
    "modules/creatures/progression/canonical_form_identity_w04.gd",
    "tests/gameplay/w04_autorun_v2_form_identity.gd",
    "modules/creatures/domain/creature_instance.gd",
    "modules/creatures/progression/creature_factory.gd",
    "modules/save/field_native_save.gd",
    "modules/save/save_game_data.gd",
]:
    test((ROOT / path).is_file(), "runtime + test file exists " + path)
helper = text_file("modules/creatures/progression/canonical_form_identity_w04.gd")
test("PILOT_POKEMON_ID := 10164" in helper and "PILOT_FORM_ID := 10323" in helper
     and "static func from_factory_source(" in helper
     and "static func valid_persistent_form(" in helper
     and "policy.form_allowed(" in helper, "exact catalog + Randomlock validator")
creature = text_file("modules/creatures/domain/creature_instance.gd")
test("var form_id: StringName = &\"\"" in creature
     and 'if form_id != &"": result["form_id"] = String(form_id)' in creature
     and 'var raw_form: Variant = data.get("form_id", "")' in creature,
     "optional form no default inference and round trip")
factory = text_file("modules/creatures/progression/creature_factory.gd")
test('species.id == &"slowpoke_galar"' in factory
     and "from_factory_source(species, catalogs)" in factory
     and 'overrides.get("form_id"' not in factory, "factory accepts actual source only")
save = text_file("modules/save/save_game_data.gd")
test('invalid_creature_form_type' in save and 'invalid_creature_form_id' in save
     and "const CURRENT_VERSION := 2" in save
     and 'creatures.append((c as CreatureInstance).to_dict())' in save,
     "save structural validation additive with no new schema")
native = text_file("modules/save/field_native_save.gd")
test("valid_persistent_form(c, catalogs, policy)" in native
     and "StatCalculator.compute(" in native
     and "schema" in native
     and "_valid_creature" in native,
     "native integrity + stats preserved")
history = (ROOT / "tests/fixtures/parallel_items/w04_campaign_005.json").read_bytes()
sha = hashlib.sha1(b"blob " + str(len(history)).encode() + b"\0" + history).hexdigest()
test(sha == "a504b65c73a399ab6c00e80b02481fe26392ec0e",
     "historic immutable fixture CAMP005")
for bad in ["modules/save/save_game_serializer.gd",
            "modules/save/save_game_migration.gd",
            "modules/save/save_game_repository.gd"]:
    test((ROOT / bad).is_file(), "protected file still exists " + bad)
tester = text_file("tests/gameplay/w04_autorun_v2_form_identity.gd")
for check in ["WildEncounterSystem.resolve(", "SaveGameRepository.new()",
              "SaveGameData.build(", "native.write(", "native.read(",
              "owner.deposit(", "owner.withdraw(",
              "native_rejects_invalid_form_without_overwriting_good_save",
              "SaveV2_legacy_without_form_still_valid",
              "real_encounter_sources_verified_form_no_manual_assignment"]:
    test(check in tester, "real test route present "+check)
progress_path = REPORT / "AUTORUN_V2_PROGRESS.csv"
if progress_path.exists():
    with progress_path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    test(len(rows) == 10 and [r["fila"] for r in rows] == [f"{x:02d}" for x in range(1, 11)],
         "TANDA02 independent ten-row progress")
print(f"W04_AUTORUN_V2_PY PASS checks={checks} source=real_slowpoke_galar expected_form=slowpoke-galar")
