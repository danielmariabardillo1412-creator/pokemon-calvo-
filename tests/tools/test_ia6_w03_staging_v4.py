#!/usr/bin/env python3
"""IA6 W03 V4: deterministic integration boundary and protected-source assertions.

All checks run against the actual staging checkout. The reference protection
hashes are from IA6 staging e63b2e6, NOT from W03's historical branch.
"""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
checks = 0

def ck(ok, msg):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(msg)

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

def blob(path):
    return subprocess.check_output(
        ["git", "hash-object", str(ROOT / path)], text=True, cwd=ROOT).strip()

def run():
    # Preserve all preexisting IA6 code not owned by W03.
    protected = {
        "scenes/visual/field_item_bag.gd": "da0648a71f3efd4e5ba15daeb467fd012a7e9305",
        "modules/creatures/domain/creature_instance.gd": "bd70d1ce2ff6b78129525ba3bda34667f62c12d4",
        "modules/battle/backends/showdown/native_engine.cjs": "073e5c8523f47a477735b98a766437392c201e33",
        "config/item_selection_v1.json": "bf76a361b30e158f613f31ef275006862562cea8",
        "modules/inventory/field_item_service.gd": "f94066212e4572b5854eba8ff5847367247e723b",
    }
    for path, sha in protected.items():
        ck(blob(path) == sha, "IA6 protected baseline changed: " + path)
    items = json.loads(read("config/item_selection_v1.json"))
    ck("dynamax_candy" in items["excluded_ids"], "Dynamax Candy veto must survive V4")
    for candy in ("rare_candy", "exp_candy_xl"):
        ck(candy not in items["excluded_ids"], candy + " must not inherit Dynamax veto")

    source_history = read("modules/capture/caught_species_history_w03.gd")
    moon = read("modules/capture/capture_source_w03_v3.gd")
    owner = read("modules/creatures/storage/player_collection.gd")
    context = read("modules/capture/capture_battle_context.gd")
    effects = read("modules/capture/capture_context_ball_effects.gd")
    native = read("modules/gameplay/showdown_adventure_session.gd")
    save = read("modules/save/save_game_data.gd")
    repository = read("modules/save/save_game_repository.gd")
    field = read("modules/save/field_native_save.gd")
    load = read("modules/save/load_result.gd")

    ck("canonical_id(raw_id: StringName, catalogs: DefinitionCatalog)" in source_history,
       "ledger requires validated base species")
    ck("if not ledger.has(base):" in source_history and "ledger.sort()" in source_history,
       "successful capture ledger de-duplicates")
    ck("caught_history_duplicate" in source_history and "caught_history_version" in source_history,
       "hostile ledger is rejected")
    ck("has_previously_caught" in owner and "record_successful_capture" in owner
       and "caught_base_species_ids: Array[StringName]" in owner,
       "real owner ledger must be first class")
    ck("previously_caught_base_species" in context
       and "moon_stone_context_known" in context
       and "target_evolves_with_moon_stone" in context,
       "capture context additive fields are missing")
    ck("moon_stone" in moon and "evolution.version_group" in moon
       and "evolution.species_id" in moon and "evolution.trigger" in moon,
       "Moon context requires canonical evolution provenance")
    ids = re.search(r'const IDS: Array\[StringName\]\s*=\s*\[(.*?)\]', effects, re.S)
    ck(ids is not None and re.findall(r'&"([^"]+)"', ids.group(1)) ==
       ["quick_ball", "timer_ball", "level_ball", "repeat_ball", "moon_ball"],
       "only two additional contextual balls allowed")
    ck('"capture_moon_stone_context_missing"' in effects,
       "Moon rejects missing producer instead of granting a default multiplier")
    ck('3.5 if context.previously_caught_base_species' in effects
       and '4.0 if context.moon_stone_context_known and context.target_evolves_with_moon_stone' in effects,
       "Repeat/Moon context multipliers changed")
    capture = native.split("func capture(", 1)[1].split("\nfunc flee(", 1)[0]
    ck("context.previously_caught_base_species = player.has_previously_caught" in capture,
       "native Repeat must derive from owning ledger before spending")
    ck('if ball_id == &"moon_ball":' in capture
       and "moon_context(target.base_species_id(), catalogs)" in capture,
       "native Moon producer must be target base species")
    ck("if resolution.captured != null:" in capture
       and "player.record_successful_capture(resolution.captured.base_species_id(), catalogs)" in capture
       and capture.index("player.record_successful_capture") > capture.index("if result.accepted:"),
       "caught ledger must update after native committed capture")
    for danger in ("if ball_id == &\"heavy_ball\":", "if ball_id == &\"beast_ball\":",
                   "context.individual_gender", "context.fishing_method", "context.world_is_dark"):
        ck(danger not in capture, "invented producer or unauthorized ball: " + danger)
    ck('"caught_base_species_ids": caught_base_species_ids' in save
       and "CaughtHistory.parse(caught_base_species_ids)" in save,
       "optional SaveV2 ledger missing structural rejection")
    ck('d.get("caught_base_species_ids", {"schema_version": 1, "ids": []})' in save,
       "legacy saves must recover an empty ledger")
    ck("SaveGameData.build(pc.party, pc.storage, pc.inventory, pc.caught_base_species_ids)" in repository
       and "out.caught_base_species_ids = caught.ids" in repository,
       "transactional decode/repository owner ledger mismatch")
    ck("caught_base_species_ids: Array[StringName]" in load,
       "LoadResult missing parsed ledger field")
    ck("collection.caught_base_species_ids = decoded.caught_base_species_ids.duplicate()" in field
       and "validate_catalog(collection.caught_base_species_ids, catalogs)" in field,
       "native envelope must validate ledger against canonical species")
    ck("c.effective_nature_id if c.effective_nature_id != &\"\" else c.nature_id" in field,
       "IA6 mint effective nature validation was lost")
    ck("FieldItemBag" not in source_history and "SaveGameMigration" not in moon,
       "ledger/Moon helpers must remain local capture modules")
    ck(Path(ROOT / "tests/gameplay/parallel_items_w03_continuous_v3.gd").is_file(),
       "Moon native test is mandatory")
    ck(Path(ROOT / "tests/gameplay/parallel_items_w03_repeat_native_v4_negatives.gd").is_file(),
       "Repeat hostile ledger test is mandatory")
    print(f"IA6_W03_V4_PY PASS checks={checks} protected={len(protected)} contextual=5 veto_dynamax=true")

if __name__ == "__main__":
    run()
