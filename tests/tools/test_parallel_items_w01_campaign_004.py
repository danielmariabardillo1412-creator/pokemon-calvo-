#!/usr/bin/env python3
"""W01 CAMP004: contrato auditable de especies, fixtures y fuentes nativas.
Las aserciones de batalla y SaveV2 se ejecutan separadamente en Godot.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W01_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W01/CAMP_004_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_004.json"
NATIVE = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
REFS = {
    "docs/current/ITEM_INVENTORY.csv": "2aaf18643bb2b071226118a1ad556cffca4707dd",
    "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv": "8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b",
    "tools/item_audit/held_effect_sweep_v3.cjs": "fd5d9d0b1eecf8b84f14e606631df93b40728586",
    "tools/item_audit/held_effect_sweep_v2.cjs": "c9ba4d7bcddad6ae69f085f4b69983461ad05219",
    "tools/item_audit/held_pilot.cjs": "c8a59a18f546d772ff34e4f8640a4246a00a822b",
    "modules/gameplay/showdown_adventure_session.gd": "1542086a8c44c58eb41c7ca8c592a40b61d5abf1",
    "modules/gameplay/held_escape_items.gd": "7603f52b522e8f8f0a6e26948697562f95dfa44d",
    "tests/gameplay/opencode_world_held_v2.gd": "5a777a1f11784eb4663662c80cef0b5c9182dd3c",
}
EXPECTED = {
    "ball_pikachu_special": ("light_ball", "damage_boost_compatible", "pikachu", "thunder_shock", "", (19, 23)),
    "ball_pikachu_physical": ("light_ball", "damage_boost_compatible", "pikachu", "tackle", "", (19, 23)),
    "ball_wrong_species": ("light_ball", "wrong_holder_no_damage_boost", "mew", "thunder_shock", "", (19,)),
    "club_cubone_physical": ("thick_club", "damage_boost_compatible", "cubone", "tackle", "", (19, 23)),
    "club_marowak_physical": ("thick_club", "damage_boost_compatible", "marowak", "tackle", "", (19, 23)),
    "club_wrong_species": ("thick_club", "wrong_holder_no_damage_boost", "mew", "tackle", "", (19,)),
    "punch_chansey_critical": ("lucky_punch", "critical_ratio_compatible", "chansey", "focus_energy", "tackle", tuple(range(1, 17))),
    "punch_wrong_species": ("lucky_punch", "wrong_holder_no_critical_ratio", "mew", "focus_energy", "tackle", tuple(range(1, 9))),
    "rain_duration": ("damp_rock", "weather_duration", "mew", "rain_dance", "", (19, 23)),
    "rain_no_weather": ("damp_rock", "no_weather", "mew", "reflect", "", (19,)),
    "snow_duration": ("icy_rock", "weather_duration", "mew", "snowscape", "", (19, 23)),
    "snow_no_weather": ("icy_rock", "no_weather", "mew", "reflect", "", (19,)),
    "weight_grass_knot": ("float_stone", "weight_damage_reduced", "garchomp", "reflect", "", (19, 23)),
    "weight_tackle_control": ("float_stone", "fixed_power_control", "garchomp", "reflect", "", (19,)),
    "dice_bullet_seed": ("loaded_dice", "loaded_dice_multihit", "mew", "bullet_seed", "", tuple(range(1, 13))),
    "dice_tackle_control": ("loaded_dice", "loaded_dice_single_hit", "mew", "tackle", "", (19,)),
    "misty_seed_trigger": ("misty_seed", "misty_seed_terrain", "mew", "reflect", "", (19, 23)),
    "misty_seed_wrong_terrain": ("misty_seed", "misty_seed_no_trigger", "mew", "reflect", "", (19,)),
    "power_herb_solar_beam": ("power_herb", "power_herb_skip_charge", "mew", "solar_beam", "", (19, 23)),
    "power_herb_noncharge": ("power_herb", "power_herb_no_charge_control", "mew", "tackle", "", (19,)),
    "psychic_seed_trigger": ("psychic_seed", "psychic_seed_terrain", "mew", "reflect", "", (19, 23, 31)),
    "psychic_seed_wrong_terrain": ("psychic_seed", "psychic_seed_wrong_terrain", "mew", "reflect", "", (19,)),
    "punching_glove_boost": ("punching_glove", "punching_glove_punch", "mew", "thunder_punch", "", (19, 23)),
    "punching_glove_tackle": ("punching_glove", "punching_glove_contact_control", "mew", "tackle", "", (19,)),
    "punching_glove_water": ("punching_glove", "punching_glove_noncontact_control", "mew", "water_gun", "", (19,)),
    "ring_gengar_normal": ("ring_target", "ring_target_type_immunity", "gengar", "reflect", "", (19, 23)),
    "ring_charizard_ground": ("ring_target", "ring_target_type_immunity", "charizard", "reflect", "", (19, 23)),
    "ring_levitate_immune": ("ring_target", "ring_target_ability_immunity", "mew", "reflect", "", (19,)),
    "service_trick_room": ("room_service", "room_service_activated", "mew", "reflect", "", (19, 23)),
    "service_no_room": ("room_service", "room_service_not_activated", "mew", "reflect", "", (19,)),
    "scope_focus_crit": ("scope_lens", "scope_lens_focus_critical", "mew", "focus_energy", "tackle", (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)),
    "scope_no_damage_control": ("scope_lens", "scope_lens_status_control", "mew", "reflect", "", (19,)),
    "shell_mean_look": ("shed_shell", "shed_shell_escape_trap", "mew", "reflect", "", (19, 23)),
    "shell_no_trap": ("shed_shell", "shed_shell_no_trap_control", "mew", "reflect", "", (19,)),
    "smoke_look_escape": ("smoke_ball", "smoke_ball_escape_trapped", "mew", "reflect", "", (19, 23)),
    "smoke_plain_escape": ("smoke_ball", "smoke_ball_escape_normal", "mew", "reflect", "", (19,)),
    "smoke_magic_room_negative": ("smoke_ball", "smoke_ball_magic_room_suppressed", "mew", "reflect", "", (19,)),
    "smoke_no_run": ("smoke_ball", "smoke_ball_no_trigger", "mew", "reflect", "", (19,)),
    "sandstorm_duration": ("smooth_rock", "weather_duration", "mew", "sandstorm", "", (19, 23)),
    "sandstorm_no_weather": ("smooth_rock", "no_weather", "mew", "reflect", "", (19,)),
    "snowball_ice_hit": ("snowball", "snowball_ice_trigger", "mew", "reflect", "", (19, 23)),
    "snowball_water_hit": ("snowball", "snowball_wrong_type", "mew", "reflect", "", (19,)),
    "snowball_no_hit": ("snowball", "snowball_no_hit", "mew", "reflect", "", (19,)),
    "sticky_residual": ("sticky_barb", "sticky_barb_residual", "mew", "reflect", "", (19, 23)),
    "sticky_contact_transfer": ("sticky_barb", "sticky_barb_transfer", "mew", "reflect", "", (19, 23)),
    "sticky_special_no_transfer": ("sticky_barb", "sticky_barb_no_contact", "mew", "reflect", "", (19,)),
    "terrain_electric_extended": ("terrain_extender", "terrain_extender_duration", "mew", "electric_terrain", "", (19, 23)),
    "terrain_psychic_extended": ("terrain_extender", "terrain_extender_duration", "mew", "psychic_terrain", "", (19,)),
    "terrain_none": ("terrain_extender", "terrain_extender_no_terrain", "mew", "reflect", "", (19,)),
    "spray_round": ("throat_spray", "throat_spray_sound_trigger", "mew", "round", "", (19, 23)),
    "spray_growl": ("throat_spray", "throat_spray_sound_trigger", "mew", "growl", "", (19,)),
    "spray_tackle": ("throat_spray", "throat_spray_non_sound", "mew", "tackle", "", (19,)),
    "spray_reflect": ("throat_spray", "throat_spray_non_sound", "mew", "reflect", "", (19,)),
    "toxic_end_turn": ("toxic_orb", "toxic_orb_end_turn", "mew", "reflect", "", (19, 23)),
    "toxic_poison_immune": ("toxic_orb", "toxic_orb_type_immune", "gengar", "reflect", "", (19,)),
    "toxic_magic_room": ("toxic_orb", "toxic_orb_suppressed", "mew", "reflect", "", (19,)),
    "umbrella_sun_fire": ("utility_umbrella", "utility_umbrella_weather", "mew", "sunny_day", "", (19, 23)),
    "umbrella_rain_water": ("utility_umbrella", "utility_umbrella_weather", "mew", "rain_dance", "", (19, 23)),
    "umbrella_clear_fire": ("utility_umbrella", "utility_umbrella_clear", "mew", "reflect", "", (19,)),
    "policy_electric": ("weakness_policy", "weakness_policy_super_effective", "gyarados", "reflect", "", (19, 23)),
    "policy_neutral": ("weakness_policy", "weakness_policy_no_trigger", "gyarados", "reflect", "", (19,)),
    "policy_no_hit": ("weakness_policy", "weakness_policy_no_trigger", "gyarados", "reflect", "", (19,)),
}
NEW_CASE_IDS = {"rain_duration", "rain_no_weather", "snow_duration", "snow_no_weather",
                "weight_grass_knot", "weight_tackle_control"}
BLOCK_03_CASES = {"dice_bullet_seed", "dice_tackle_control", "misty_seed_trigger",
                  "misty_seed_wrong_terrain", "power_herb_solar_beam", "power_herb_noncharge"}
BLOCK_04_CASES = {"psychic_seed_trigger", "psychic_seed_wrong_terrain", "punching_glove_boost", "punching_glove_tackle", "punching_glove_water", "ring_gengar_normal", "ring_charizard_ground", "ring_levitate_immune"}
BLOCK_05_CASES = {"service_trick_room", "service_no_room", "scope_focus_crit", "scope_no_damage_control", "shell_mean_look", "shell_no_trap"}
BLOCK_06_CASES = {"smoke_look_escape", "smoke_plain_escape", "smoke_magic_room_negative", "smoke_no_run", "sandstorm_duration", "sandstorm_no_weather", "snowball_ice_hit", "snowball_water_hit", "snowball_no_hit"}
BLOCK_07_CASES = {"sticky_residual", "sticky_contact_transfer", "sticky_special_no_transfer", "terrain_electric_extended", "terrain_psychic_extended", "terrain_none", "spray_round", "spray_growl", "spray_tackle", "spray_reflect"}
BLOCK_08_CASES = {"toxic_end_turn", "toxic_poison_immune", "toxic_magic_room", "umbrella_sun_fire", "umbrella_rain_water", "umbrella_clear_fire", "policy_electric", "policy_neutral", "policy_no_hit"}
BLOCK_08_FOE_SPECIES = {"umbrella_sun_fire": "snorlax", "umbrella_rain_water": "snorlax", "umbrella_clear_fire": "snorlax"}
BLOCK_07_FOE = {"sticky_contact_transfer": "tackle", "sticky_special_no_transfer": "water_gun"}
BLOCK_04_FOE_ITEMS = {"punching_glove_boost": "rocky_helmet", "punching_glove_tackle": "rocky_helmet", "punching_glove_water": "rocky_helmet"}
BLOCK_04_ABILITIES = {"ring_levitate_immune": "levitate"}
EXPECTED_FOE_MOVES = {"weight_grass_knot": "grass_knot", "weight_tackle_control": "tackle",
                      "misty_seed_trigger": "misty_terrain", "misty_seed_wrong_terrain": "electric_terrain",
                      "psychic_seed_trigger": "psychic_terrain", "psychic_seed_wrong_terrain": "electric_terrain",
                      "ring_gengar_normal": "tackle", "ring_charizard_ground": "earthquake",
                      "ring_levitate_immune": "earthquake",
                      "service_trick_room": "trick_room", "shell_mean_look": "mean_look",
                      "smoke_look_escape": "mean_look", "smoke_magic_room_negative": "magic_room",
                      "snowball_ice_hit": "powder_snow", "snowball_water_hit": "water_gun",
                      **BLOCK_07_FOE,
                       "toxic_magic_room": "magic_room",
                       "umbrella_sun_fire": "ember", "umbrella_rain_water": "water_gun",
                       "umbrella_clear_fire": "ember", "policy_electric": "thunder_shock",
                       "policy_neutral": "tackle"}
MODES = ("active", "none", "reserve")
CHECKS = 0

def require(test: bool, message: str):
    global CHECKS
    CHECKS += 1
    if not test:
        raise ValueError(message)

def read_rows(path: Path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))

def blob_sha(path: Path):
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()

def validate():
    queue = read_rows(QUEUE)
    progress = read_rows(PROGRESS)
    require(len(queue) == 10 and all(x["trabajadora"] == "W01" for x in queue), "Cola de W01 inválida")
    require(len(progress) == 8, "El contrato exige exactamente los bloques 01 a 08")
    require(progress[0]["bloque"] == "01" and progress[0]["ids"] == "light_ball;lucky_punch;thick_club", "Progreso distinto a W01/01")
    require(progress[0]["ids"] == queue[0]["ids"], "Bloque 01 distinto de cola árbitra")
    require(progress[0]["estado"] == "CI_PASS_VERIFICADO" and progress[0]["ci_run"] == "41580332632",
            "Bloque 01 sin certificado CI oficial")
    require(progress[1]["bloque"] == "02" and progress[1]["ids"] == queue[1]["ids"],
            "Bloque 02 no coincide con la cola autorizada")
    require(progress[1]["estado"] == "CI_PASS_VERIFICADO"
            and progress[1]["ci_run"] == "41584708689"
            and progress[1]["sha_pruebas"] == "970db4c7696364cc1c5ebaf51719405d60430af0",
            "Bloque 02 sin certificado CI oficial")
    require(progress[2]["bloque"] == "03" and progress[2]["ids"] == queue[2]["ids"],
            "Bloque 03 fuera de cola W01")
    require(progress[2]["estado"] == "CI_PASS_VERIFICADO"
            and progress[2]["sha_pruebas"] == "b9aa52cd282938221e1b2554132a31ce0189d886"
            and progress[2]["ci_run"] == "41590511208",
            "Bloque 03 sin certificado CI")
    require(progress[3]["bloque"] == "04" and progress[3]["ids"] == queue[3]["ids"],
            "Bloque 04 fuera de cola")
    require(progress[3]["estado"] == "CI_PASS_VERIFICADO"
            and progress[3]["sha_pruebas"] == "ec13e1c6b30a58c8ac8c7c6bab3052d2ddec8699"
            and progress[3]["ci_run"] == "41592180823",
            "Bloque 04 sin CI aprobada")
    require(progress[4]["bloque"] == "05" and progress[4]["ids"] == queue[4]["ids"],
            "Bloque 05 no autorizado")
    require(progress[4]["estado"] == "CI_PASS_VERIFICADO"
            and progress[4]["sha_pruebas"] == "7034b8c783eb9996369cbf1c97229c05713c9a08"
            and progress[4]["ci_run"] == "41602276948",
            "Bloque 05 sin certificado CI + regresión CAMP003")
    require(progress[5]["bloque"] == "06" and progress[5]["ids"] == queue[5]["ids"],
            "Bloque 06 fuera de cola W01")
    require(progress[5]["estado"] == "CI_PASS_VERIFICADO"
            and progress[5]["sha_pruebas"] == "bc2f236ba9cd23072b78589d6f100437c436e7e8"
            and progress[5]["ci_run"] == "41707616043",
            "Bloque 06 sin CI aprobada")
    require(progress[6]["bloque"] == "07" and progress[6]["ids"] == queue[6]["ids"]
            and progress[6]["estado"] in ("EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "CI_PASS_VERIFICADO"),
            "Bloque 07 fuera de cola o estado inválido")
    require(progress[6]["estado"] == "CI_PASS_VERIFICADO"
            and progress[6]["sha_pruebas"] == "328227633b204f04aebffe3af1773ca30e9d4955"
            and progress[6]["ci_run"] == "41711361003", "Bloque 07 sin CI oficial aprobada")
    require(progress[7]["bloque"] == "08" and progress[7]["ids"] == queue[7]["ids"]
            and progress[7]["estado"] in ("EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "CI_PASS_VERIFICADO"),
            "Bloque 08 fuera de cola o estado inválido")
    require(all(row["sha_pruebas"] and row["ci_run"] for row in progress), "Progreso sin trazabilidad")
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    require(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004" and fixture["worker"] == "W01", "Identidad de fixture incorrecta")
    require(fixture["scope"] == "HELD_COMBAT_CANDIDATE" and fixture["format"] == "gen9calvounifiedv1", "Motor o familia no permitidos")
    require(tuple(fixture["variants"]) == MODES, "Faltan los tres controles activo/ausente/reserva")
    require(len(fixture["blocks"]) == 8 and [b["block"] for b in fixture["blocks"]] == ["01", "02", "03", "04", "05", "06", "07", "08"],
            "Fixture debe contener bloques 01 a 08")
    require(fixture["blocks"][0]["ids"] == queue[0]["ids"].split(";"), "Propiedad de IDs alterada")
    require(fixture["blocks"][1]["ids"] == queue[1]["ids"].split(";"), "IDs del bloque 02 alterados")
    require(set(fixture["blocks"][1]["cases"]) == NEW_CASE_IDS, "Casos del bloque 02 incompletos")
    require(fixture["blocks"][2]["ids"] == queue[2]["ids"].split(";"), "IDs del bloque 03 alterados")
    require(set(fixture["blocks"][2]["cases"]) == BLOCK_03_CASES, "Casos del bloque 03 incompletos")
    require(fixture["blocks"][3]["ids"] == queue[3]["ids"].split(";"), "IDs bloque 04 incorrectos")
    require(set(fixture["blocks"][3]["cases"]) == BLOCK_04_CASES, "Casos bloque 04 incompletos")
    require(fixture["blocks"][4]["ids"] == queue[4]["ids"].split(";"), "IDs bloque 05 incorrectos")
    require(set(fixture["blocks"][4]["cases"]) == BLOCK_05_CASES, "Bloque 05 incompleto")
    require(fixture["blocks"][5]["ids"] == queue[5]["ids"].split(";"), "IDs del bloque 06 distintos de IA6")
    require(set(fixture["blocks"][5]["cases"]) == BLOCK_06_CASES, "Casos del bloque 06 incompletos")
    require(fixture["blocks"][6]["ids"] == queue[6]["ids"].split(";"), "IDs del bloque 07 alterados")
    require(set(fixture["blocks"][6]["cases"]) == BLOCK_07_CASES, "Bloque 07 no cubre sus casos")
    require(fixture["blocks"][7]["ids"] == queue[7]["ids"].split(";"), "IDs del bloque 08 alterados")
    require(set(fixture["blocks"][7]["cases"]) == BLOCK_08_CASES, "Bloque 08 no cubre sus casos")
    require(len(fixture["cases"]) == len(EXPECTED) == 62, "Se exigen 62 escenarios únicos")
    require(set(fixture["blocks"][0]["cases"]) == set(EXPECTED) - NEW_CASE_IDS - BLOCK_03_CASES - BLOCK_04_CASES - BLOCK_05_CASES - BLOCK_06_CASES - BLOCK_07_CASES - BLOCK_08_CASES,
            "Falta caso original del bloque 01")
    require(len(fixture["sources"]) == len(REFS), "Fuentes añadidas o omitidas")
    for source in fixture["sources"]:
        path = source["path"]
        require(path in REFS, "Fuente fuera de inventario: " + path)
        require(source["git_blob_sha"] == REFS[path], "Hash declarado incorrecto: " + path)
        require(blob_sha(ROOT / path) == REFS[path], "Fuente canónica cambiada: " + path)
    scope = {r["id"]: r for r in read_rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    inventory = {r["id"]: r for r in read_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    canonical = {"light_ball": "lightball", "lucky_punch": "luckypunch",
                 "thick_club": "thickclub", "damp_rock": "damprock",
                 "float_stone": "floatstone", "icy_rock": "icyrock",
                 "loaded_dice": "loadeddice", "misty_seed": "mistyseed", "power_herb": "powerherb",
                 "psychic_seed": "psychicseed", "punching_glove": "punchingglove", "ring_target": "ringtarget",
                 "room_service": "roomservice", "scope_lens": "scopelens", "shed_shell": "shedshell",
                 "smoke_ball": "", "smooth_rock": "smoothrock", "snowball": "snowball",
                 "sticky_barb": "stickybarb", "terrain_extender": "terrainextender", "throat_spray": "throatspray",
                 "toxic_orb": "toxicorb", "utility_umbrella": "utilityumbrella", "weakness_policy": "weaknesspolicy"}
    for stage in queue[:8]:
        for item in stage["ids"].split(";"):
            require(scope[item]["estado_contenido"] == "SELECCIONADO", "Item no seleccionado: " + item)
            require(inventory[item]["family"] == "HELD_COMBAT_CANDIDATE", "Familia incompatible: " + item)
            require(inventory[item]["native_id"] == canonical[item], "Clave nativa incorrecta: " + item)
            if item == "smoke_ball":
                require(inventory[item]["connection"] == "DATA_ONLY" and inventory[item]["native_entry"] == "False",
                        "Smoke Ball es regla AdventureSession, no efecto de ataque")
    require("onModifyWeight" in inventory["float_stone"]["native_hooks"],
            "Piedra Pómez sin gancho nativo de peso")
    require("onModifyMove" in inventory["loaded_dice"]["native_hooks"],
            "Dado Trucado sin gancho nativo de golpes múltiples")
    require("onTerrainChange" in inventory["misty_seed"]["native_hooks"],
            "Semilla Bruma sin gancho nativo de terreno")
    require("onChargeMove" in inventory["power_herb"]["native_hooks"],
            "Hierba Única sin gancho nativo de carga")
    require("onTerrainChange" in inventory["psychic_seed"]["native_hooks"], "Sin gancho de Semilla Psique")
    require("onModifyMove" in inventory["punching_glove"]["native_hooks"]
            and "onBasePower" in inventory["punching_glove"]["native_hooks"], "Sin ganchos Guante de Boxeo")
    require("onAnyPseudoWeatherChange" in inventory["room_service"]["native_hooks"],
            "Servicio Raro sin efecto pseudo-clima")
    require("onModifyCritRatio" in inventory["scope_lens"]["native_hooks"],
            "Periscopio sin efecto crítico")
    require("onMaybeTrapPokemon" in inventory["shed_shell"]["native_hooks"]
            and "onTrapPokemon" in inventory["shed_shell"]["native_hooks"],
            "Muda Concha sin ganchos de escape")
    require("onHit" in inventory["sticky_barb"]["native_hooks"]
            and "onResidual" in inventory["sticky_barb"]["native_hooks"],
            "Toxiestrella sin transferencia o residual")
    require(inventory["terrain_extender"]["native_id"] == "terrainextender"
            and inventory["terrain_extender"]["native_entry"] == "True",
            "Cubresuelos sin descriptor nativo")
    require("onAfterMoveSecondarySelf" in inventory["throat_spray"]["native_hooks"],
            "Espray Bucal sin disparador sonoro")
    require("onResidual" in inventory["toxic_orb"]["native_hooks"], "Toxisfera sin activación residual")
    require(all(hook in inventory["utility_umbrella"]["native_hooks"] for hook in ("onStart", "onUpdate", "onEnd")),
            "Parasol Multiuso sin ganchos de clima")
    require("onDamagingHit" in inventory["weakness_policy"]["native_hooks"], "Seguro Debilidad sin disparador")
    require("onDamagingHit" in inventory["snowball"]["native_hooks"],
            "Bola de Nieve sin gancho por impacto")
    require(inventory["smooth_rock"]["native_entry"] == "True",
            "Roca Suave sin descriptor nativo")
    held_escape = (ROOT / "modules/gameplay/held_escape_items.gd").read_text(encoding="utf-8")
    adventure = (ROOT / "modules/gameplay/showdown_adventure_session.gd").read_text(encoding="utf-8")
    world_suite = (ROOT / "tests/gameplay/opencode_world_held_v2.gd").read_text(encoding="utf-8")
    require('const SMOKE_BALL := &"smoke_ball"' in held_escape
            and "return held_item_active and supports(held_item_id)" in held_escape,
            "Bola de Humo debe usar actividad nativa real")
    require("HeldEscapeItems.guaranteed" in adventure
            and "func flee(expected_revision: int)" in adventure
            and 'smoke["smoke_ball"] = true' in adventure,
            "Bola de Humo no conectada a huida real")
    require("func smoke_ball_cases()" in world_suite
            and "func smoke_ball_suppression()" in world_suite,
            "Sin precedentes nativos de huida y supresión")
    historical_v2 = (ROOT / "tools/item_audit/held_effect_sweep_v2.cjs").read_text(encoding="utf-8")
    pilot = (ROOT / "tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
    require("add('loaded_dice','multi_hit_bound'" in historical_v2
            and "['bullet_seed']" in historical_v2 and "'|-hitcount|'" in historical_v2,
            "Sin referencia nativa de Dado Trucado y su contador de impactos")
    require("add('toxic_orb','end_turn_status'" in historical_v2
            and "own(a).status_id,'badly_poisoned'" in historical_v2,
            "Sin evidencia histórica nativa de Toxisfera")
    require("add('weakness_policy','super_effective_boost'" in historical_v2
            and "own(a).boosts.atk,2" in historical_v2 and "own(a).boosts.spa,2" in historical_v2,
            "Sin evidencia histórica nativa de Seguro Debilidad")
    require("throat_spray:{moves:['round']" in pilot
            and "assert.equal(own(a).boosts.spa,1)" in pilot,
            "Falta prueba nativa histórica de Espray Bucal")
    require("power_herb:{moves:['solar_beam']" in pilot,
            "Sin referencia nativa de Hierba Única que evita carga")
    require("['snowball','powder_snow','atk']" in historical_v2,
            "Bola de Nieve sin contrato histórico de impacto de hielo")
    require("add('punching_glove','punch_boost_and_contact'" in historical_v2
            and "['thunder_punch']" in historical_v2 and "foeItem:'rocky_helmet'" in historical_v2,
            "Sin referencia nativa de Guante de Boxeo y Casco Dentado")
    historical = NATIVE.read_text(encoding="utf-8")
    for fragment in (
        "['light_ball','pikachu','thunder_shock']",
        "['light_ball','pikachu','tackle']",
        "['thick_club','cubone','tackle']",
        "['thick_club','marowak','tackle']",
        "id==='lucky_punch'?'chansey'",
        "moves:['focus_energy','tackle']",
        "add(id,'wrong_species'",
        "add(id,'wrong_holder_",
        "add('float_stone','weight_threshold'",
        "add('float_stone','fixed_power_control'",
        "['damp_rock','rain_dance']",
        "['icy_rock','snowscape']",
        "['smooth_rock','sandstorm']",
        "add('sticky_barb','residual'",
        "add('sticky_barb','contact_transfer'",
        "add('terrain_extender','terrain_duration'",
        "add('utility_umbrella','incoming_sun_fire'",
        "add('utility_umbrella','incoming_rain_water'",
        "add('utility_umbrella','clear_weather'",
        "['psychic_seed','psychic_terrain','spd']",
        "add('ring_target','type_immunity_",
        "add('ring_target','ability_immunity_preserved'",
        "add('room_service','trick_room'",
        "add('room_service','no_room'",
        "add('shed_shell','switch_despite_trap'",
        "for(const id of ['scope_lens','razor_claw','lucky_punch','stick'])",
    ):
        require(fragment in historical, "Referencia histórica sin contrato: " + fragment)
    seen = set()
    pairs = 0
    for case in fixture["cases"]:
        name = case["id"]
        require(name in EXPECTED and name not in seen, "Caso no autorizado o duplicado: " + name)
        seen.add(name)
        expected_block = ("08" if name in BLOCK_08_CASES else
                          "07" if name in BLOCK_07_CASES else
                          "06" if name in BLOCK_06_CASES else
                          "05" if name in BLOCK_05_CASES else
                          "04" if name in BLOCK_04_CASES else
                          "03" if name in BLOCK_03_CASES else
                          "02" if name in NEW_CASE_IDS else "01")
        require(case["block"] == expected_block, "Caso fuera de bloque " + expected_block)
        actual = (case["item_id"], case["op"], case["actor_species"], case["own_move"],
                  case.get("follow_move", ""), tuple(case["seeds"]))
        require(actual == EXPECTED[name], "Condiciones de mecánica y semillas alteradas: " + name)
        require(case["foe_species"] == BLOCK_08_FOE_SPECIES.get(name, "mew") and
                case["foe_move"] == EXPECTED_FOE_MOVES.get(name, "amnesia"),
                "Rival o movimiento alterado: " + name)
        require(case.get("foe_item", "") == BLOCK_04_FOE_ITEMS.get(name, ""),
                "Casco Dentado no corresponde al escenario")
        require(case.get("actor_ability", "") == BLOCK_04_ABILITIES.get(name, ""),
                "Habilidad del portador alterada")
        origin = ("opencode_world_held_v2:" if case["item_id"] == "smoke_ball" else
                  "held_pilot:" if case["item_id"] == "throat_spray" else
                  "held_effect_sweep_v2:" if case["item_id"] in ("loaded_dice", "punching_glove", "snowball", "toxic_orb", "weakness_policy") else
                  "held_pilot:" if case["item_id"] == "power_herb" else "held_effect_sweep_v3:")
        require(case["history"].startswith(origin), "Sin referencia de origen: " + name)
        require(all(type(i) is int and 1 <= i <= 65535 for i in case["seeds"]), "Semilla inválida: " + name)
        require(len(case["seeds"]) == len(set(case["seeds"])), "Semillas repetidas: " + name)
        if name in ("punch_chansey_critical", "punch_wrong_species", "scope_focus_crit"):
            require(case["follow_move"] == "tackle" and case["own_move"] == "focus_energy",
                    "Objeto de crítico sin secuencia real Foco Energía + Placaje")
        else:
            require("follow_move" not in case, "Secuencia extra no permitida")
        pairs += len(case["seeds"])
    require(len(seen) == 62 and pairs == 137, "Matriz debe tener 62 casos y 137 pares")
    runner = (ROOT / "tests/gameplay/parallel_items_w01_campaign_004.gd").read_text(encoding="utf-8")
    for fragment in ("Native.new(catalogs, owner, automation.format)",
                     "await _restore_probe(", "session.submit(", "session._checkpoint",
                     "_compare_c004(", "CAMP004_W01_GODOT PASS"):
        require(fragment in runner, "Falta ruta de validación real: " + fragment)
    return len(progress)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    global CHECKS
    try:
        blocks = validate()
    except (KeyError, OSError, ValueError, TypeError, json.JSONDecodeError) as error:
        print("CAMP004_W01_PY FAIL:", str(error))
        return 1
    print(f"CAMP004_W01_PY PASS blocks={blocks} checks={CHECKS}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
