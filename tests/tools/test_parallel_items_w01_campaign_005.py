#!/usr/bin/env python3
"""IA1/W01 CAMP005 — contrato acumulativo autorizado para 10 bloques funcionales.

No atribuye PASS de Godot: el recibo de efecto positivo corresponde al runner
real tests/gameplay/parallel_items_w01_campaign_005.gd y a CI del mismo SHA.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_005_W01_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W01/CAMP_005_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_005.json"
INVENTORY = ROOT / "docs/current/ITEM_INVENTORY.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
PRIOR_PROGRESS = BASE / "reports/W01/CAMP_004_PROGRESO.csv"
PARENT_RUNNER = ROOT / "tests/gameplay/parallel_items_w01_campaign_004.gd"
PARENT_FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_004.json"
RUNNER = ROOT / "tests/gameplay/parallel_items_w01_campaign_005.gd"
HISTORY = ROOT / "tools/item_audit/held_effect_sweep_v2.cjs"
FLINCH_HISTORY = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
SPECIES_HISTORY = FLINCH_HISTORY
BLOCK07_HOOKS = {"quick_powder": "onModifySpe", "razor_claw": "onModifyCritRatio",
                 "razor_fang": "onModifyMove"}
NATIVE_B07 = ROOT / "tests/tools/repro_w01_camp005_b07_native.cjs"
NATIVE_B09 = ROOT / "tests/tools/repro_w01_camp005_b09_native.cjs"
NATIVE_B10 = ROOT / "tests/tools/repro_w01_camp005_b10_native.cjs"
SPECIES_HOOKS = {
    "deep_sea_scale": "onModifySpD",
    "deep_sea_tooth": "onModifySpA",
    "metal_powder": "onModifyDef",
}
# suffix, operation, holder species, foe species, own move, foe move, seeds.
SPECIES_CASES = {
    "deep_sea_scale": [
        ("special", "holder_special_defense", "clamperl", "mew", "reflect", "confusion", [19, 23]),
        ("physical", "physical_damage_control", "clamperl", "snorlax", "reflect", "tackle", [19]),
        ("wrong_species", "wrong_species_defense", "mew", "mew", "reflect", "confusion", [19]),
    ],
    "deep_sea_tooth": [
        ("special", "holder_special_attack", "clamperl", "mew", "water_gun", "amnesia", [19, 23]),
        ("physical", "physical_attack_control", "clamperl", "mew", "tackle", "amnesia", [19]),
        ("wrong_species", "wrong_species_attack", "mew", "mew", "water_gun", "amnesia", [19]),
    ],
    "metal_powder": [
        ("physical", "holder_physical_defense", "ditto", "snorlax", "reflect", "tackle", [19, 23]),
        ("special", "special_damage_control", "ditto", "mew", "reflect", "confusion", [19]),
        ("transformed", "transformed_no_boost", "ditto", "snorlax", "transform", "tackle", [19]),
    ],
}


# Contrato fijo 07: sufijo, operación, portador, rival, movimientos, semillas, segundo movimiento.
BLOCK07_CASES = {
    "quick_powder": [
        ("speed", "quick_powder_untransformed", "ditto", "gyarados", "reflect", "tackle", [19, 23], None),
        ("wrong_species", "quick_powder_wrong_species", "mew", "gyarados", "reflect", "tackle", [19], None),
        ("transformed", "quick_powder_transformed", "ditto", "snorlax", "transform", "tackle", [19], None),
    ],
    "razor_claw": [
        ("focus_critical", "razor_claw_focus_critical", "mew", "snorlax", "focus_energy", "amnesia", list(range(1, 17)), "tackle"),
        ("immune", "razor_claw_immune", "mew", "gengar", "tackle", "amnesia", [19], None),
        ("status", "razor_claw_status", "mew", "snorlax", "reflect", "amnesia", [19], None),
    ],
    "razor_fang": [
        ("flinch", "razor_fang_flinch", "mew", "snorlax", "tackle", "tackle", list(range(1, 65)), None),
        ("immune", "razor_fang_immune", "mew", "gengar", "tackle", "tackle", [19], None),
        ("status", "razor_fang_status", "mew", "snorlax", "reflect", "tackle", [19], None),
    ],
}
BLOCK09_CASES = {
    "sea_incense":[("matching","matching_type_boost","mew","mew","water_gun","amnesia",[19,23],"type_boost"),("nonmatching","nonmatching_control","mew","mew","tackle","amnesia",[19],"wrong_type"),("status","status_control","mew","mew","reflect","amnesia",[19],"status_control")],
    "full_incense":[("last","full_incense_last","mew","snorlax","reflect","tackle",[19,23],"last_same_priority"),("priority","full_incense_priority","mew","snorlax","quick_attack","tackle",[19],"priority_preserved"),("status","full_incense_status","mew","snorlax","reflect","amnesia",[19],"last_same_priority")],
    "lax_incense":[("accuracy","lax_incense_accuracy","mew","snorlax","reflect","tackle",list(range(1,17)),"accuracy_rng"),("never_miss","lax_incense_never_miss","mew","snorlax","reflect","aerial_ace",[19],"guaranteed_hit"),("status","lax_incense_status","mew","snorlax","reflect","amnesia",[19],"status_no_accuracy")]
}
B09_HOOKS = {"sea_incense":"onBasePower","full_incense":"","lax_incense":"onModifyAccuracy"}
BLOCK10_CASES = {
    "normal_gem": [("matching","gem_matching","tackle",[19,23]),
                   ("nonmatching","gem_nonmatching","water_gun",[19]),
                   ("status","gem_status","swords_dance",[19])],
    "fire_gem": [("matching","gem_matching","fire_punch",[19,23]),
                 ("nonmatching","gem_nonmatching","tackle",[19]),
                 ("status","gem_status","sunny_day",[19])],
    "water_gem": [("matching","gem_matching","surf",[19,23]),
                  ("nonmatching","gem_nonmatching","tackle",[19]),
                  ("status","gem_status","rain_dance",[19])],
}
# ID, tipo, ataque positivo y clave nativa; misma referencia ya probada en CAMP004.
ITEMS = {
    "black_glasses": ("dark", "dark_pulse", "blackglasses"),
    "dragon_fang": ("dragon", "dragon_pulse", "dragonfang"),
    "hard_stone": ("rock", "smack_down", "hardstone"),
    "miracle_seed": ("grass", "energy_ball", "miracleseed"),
    "mystic_water": ("water", "surf", "mysticwater"),
    "never_melt_ice": ("ice", "ice_beam", "nevermeltice"),
    "poison_barb": ("poison", "sludge_bomb", "poisonbarb"),
    "sharp_beak": ("flying", "aerial_ace", "sharpbeak"),
    "silk_scarf": ("normal", "tackle", "silkscarf"),
    "silver_powder": ("bug", "bug_buzz", "silverpowder"),
    "soft_sand": ("ground", "earth_power", "softsand"),
    "spell_tag": ("ghost", "shadow_ball", "spelltag"),
    "twisted_spoon": ("psychic", "psychic", "twistedspoon"),
    "metal_coat": ("steel", "flash_cannon", "metalcoat"),
    "kings_rock": ("flinch", "tackle", "kingsrock"),
    "deep_sea_scale": ("defense", "confusion", "deepseascale"),
    "deep_sea_tooth": ("attack", "water_gun", "deepseatooth"),
    "metal_powder": ("defense", "tackle", "metalpowder"),
    "quick_powder": ("speed", "reflect", "quickpowder"),
    "razor_claw": ("critical", "focus_energy", "razorclaw"),
    "razor_fang": ("flinch", "tackle", "razorfang"),
    "odd_incense": ("psychic", "confusion", "oddincense"),
    "rock_incense": ("rock", "smack_down", "rockincense"),
    "rose_incense": ("grass", "energy_ball", "roseincense"),
    "sea_incense": ("water", "water_gun", "seaincense"),
    "full_incense": ("order", "reflect", "fullincense"),
    "lax_incense": ("accuracy", "reflect", "laxincense"),
    "normal_gem": ("normal", "tackle", "normalgem"),
    "fire_gem": ("fire", "fire_punch", "firegem"),
    "water_gem": ("water", "surf", "watergem"),
}
MODES = ["active", "none", "reserve"]
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}
CHECKS = 0


def check(condition: bool, reason: str) -> None:
    global CHECKS
    CHECKS += 1
    if not condition:
        raise ValueError(reason)


def rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def validate() -> int:
    queue = rows(QUEUE)
    check(len(queue) == 10, "Cola CAMP005 W01 debe contener 10 bloques")
    check([r["bloque"] for r in queue] == [f"{i:02d}" for i in range(1, 11)],
          "Orden de bloques no autorizado")
    check(all(r["trabajadora"] == "W01" and r["tipo"] == "NEW_IDS"
              and r["familia"] == "HELD_COMBAT" and r["estado"] == "AUTORIZADO_NO_EJECUTADO"
              for r in queue), "Cola no coincide con autoridad IA6")
    all_ids = [x for r in queue for x in r["ids"].split(";")]
    check(len(all_ids) == len(set(all_ids)) == 30, "Cola CAMP005 duplica objetos")
    check(queue[0]["ids"] == "black_glasses;dragon_fang;hard_stone",
          "Primer bloque fuera de encargo de IA6")
    check(queue[1]["ids"] == "miracle_seed;mystic_water;never_melt_ice",
          "Segundo bloque fuera de encargo de IA6")
    check(queue[2]["ids"] == "poison_barb;sharp_beak;silk_scarf",
          "Tercer bloque fuera de encargo de IA6")
    check(queue[3]["ids"] == "silver_powder;soft_sand;spell_tag",
          "Cuarto bloque fuera de encargo de IA6")
    check(queue[4]["ids"] == "twisted_spoon;metal_coat;kings_rock",
          "Quinto bloque fuera de encargo de IA6")
    check(queue[5]["ids"] == "deep_sea_scale;deep_sea_tooth;metal_powder",
          "Sexto bloque fuera de encargo de IA6")
    check(queue[6]["ids"] == "quick_powder;razor_claw;razor_fang",
          "Séptimo bloque fuera de encargo de IA6")
    check(queue[7]["ids"] == "odd_incense;rock_incense;rose_incense",
          "Octavo bloque fuera de encargo de IA6")
    check(queue[8]["ids"] == "sea_incense;full_incense;lax_incense",
          "Noveno bloque fuera de encargo de IA6")
    check(queue[9]["ids"] == "normal_gem;fire_gem;water_gem",
          "Décimo bloque fuera de encargo IA6")

    progress = rows(PROGRESS)
    check(len(progress) == 10, "Bloque 10 exige progreso exacto 10/10")
    first = progress[0]
    check(first["bloque"] == "01" and first["ids"] == queue[0]["ids"],
          "La fila 01 no pertenece a W01")
    check(first["estado"] == "CI_PASS_VERIFICADO"
          and first["sha_pruebas"] == "bd33aeb3f993804c3c85217b81892356af39aac5"
          and first["ci_run"] == "41767517526",
          "Bloque 01 sin certificado GitHub Actions real")
    second = progress[1]
    check(second["bloque"] == "02" and second["ids"] == queue[1]["ids"]
          and second["estado"] == "CI_PASS_VERIFICADO"
          and second["sha_pruebas"] == "69438bfb81921456a87eb7da18b3442f50c79873"
          and second["ci_run"] == "41778911208",
          "Bloque 02 no tiene el certificado de CI oficial")
    third = progress[2]
    check(third["bloque"] == "03" and third["ids"] == queue[2]["ids"]
          and third["estado"] == "CI_PASS_VERIFICADO"
          and third["sha_pruebas"] == "67d0fe6041e690cc8059fd626eea7cdd4a840db2"
          and third["ci_run"] == "41783664400",
          "Bloque 03 sin certificado de CI oficial")
    fourth = progress[3]
    check(fourth["bloque"] == "04" and fourth["ids"] == queue[3]["ids"]
          and fourth["estado"] == "CI_PASS_VERIFICADO"
          and fourth["sha_pruebas"] == "814943eb7445acee0161763eff85eb87285ed3ec"
          and fourth["ci_run"] == "41954611857",
          "Bloque 04 sin certificado de CI oficial")
    fifth = progress[4]
    check(fifth["bloque"] == "05" and fifth["ids"] == queue[4]["ids"]
          and fifth["estado"] == "CI_PASS_VERIFICADO"
          and fifth["sha_pruebas"] == "fc4fe90c83a89b98aee1cb4b02963ffac5f015ed"
          and fifth["ci_run"] == "41966189357",
          "Bloque 05 no tiene certificado de CI real")
    sixth = progress[5]
    check(sixth["bloque"] == "06" and sixth["ids"] == queue[5]["ids"]
          and sixth["estado"] == "CI_PASS_VERIFICADO"
          and sixth["sha_pruebas"] == "2900431b3b50d3d47dbf7fabbb554915cd9c8319"
          and sixth["ci_run"] == "42679854792",
          "No perder certificado funcional exacto del bloque 06")
    seventh = progress[6]
    check(seventh["bloque"] == "07" and seventh["ids"] == queue[6]["ids"]
          and seventh["estado"] == "CI_PASS_VERIFICADO"
          and seventh["sha_pruebas"] == "1e713a1925fe3fa582f21b5353e2c7f265ba928d"
          and seventh["ci_run"] == "42689328705",
          "No perder el certificado funcional exacto del bloque 07")
    eighth = progress[7]
    check(eighth["bloque"] == "08" and eighth["ids"] == queue[7]["ids"]
          and eighth["estado"] == "CI_PASS_VERIFICADO"
          and eighth["sha_pruebas"] == "271cb9af74fdd03928fc42c53cced746ebe6b801"
          and eighth["ci_run"] == "42705717830", "Perdido certificado del bloque 08")
    ninth = progress[8]
    check(ninth["bloque"] == "09" and ninth["ids"] == queue[8]["ids"]
          and ninth["estado"] == "CI_PASS_VERIFICADO"
          and ninth["sha_pruebas"] == "db2339fca101db900ac7d266328701da62a0a90b"
          and ninth["ci_run"] == "42713116537",
          "Bloque 09 no conserva certificado oficial")
    tenth = progress[9]
    check(tenth["bloque"] == "10" and tenth["ids"] == queue[9]["ids"]
          and tenth["estado"] in STATES, "Fila 10 no autorizada")
    check(bool(first["sha_pruebas"]) and bool(first["ci_run"]),
          "Progreso sin trazabilidad de estado pendiente")

    previous = rows(PRIOR_PROGRESS)
    check(len(previous) == 10 and all(r["estado"] == "CI_PASS_VERIFICADO" for r in previous),
          "Se han perdido las diez certificaciones CAMP004")
    check(previous[9]["ids"] == "black_belt;charcoal;magnet"
          and previous[9]["ci_run"] == "41733777992"
          and previous[9]["sha_pruebas"] ==
          "9770b71a7f7c6d5e9b6e93eeaef81e96d42a094b",
          "CI final CAMP004 no está anclada al SHA certificado")
    check(git_blob_sha(PARENT_RUNNER) ==
          "67849ef12762919172e6297cdc242f1fcea6d13e",
          "Runner heredado CAMP004 ha cambiado: revisar regresión")
    check(git_blob_sha(PARENT_FIXTURE) ==
          "f1a094395cc83d55fefbf9a1c27fe235cb5193d7",
          "Fixture heredado CAMP004 ha cambiado: revisar regresión")

    scope = {r["id"]: r for r in rows(SCOPE)}
    inventory = {r["id"]: r for r in rows(INVENTORY)}
    history = HISTORY.read_text(encoding="utf-8")
    flinch_history = FLINCH_HISTORY.read_text(encoding="utf-8")
    species_history = SPECIES_HISTORY.read_text(encoding="utf-8")
    for id, history_move in (("odd_incense", "confusion"),
                              ("rock_incense", "smack_down"),
                              ("rose_incense", "absorb")):
        check(f"'{id}','{history_move}'" in species_history
              and "add(id,'type_boost'" in species_history
              and "add(id,'wrong_type'" in species_history,
              "Falta prueba nativa histórica de incienso " + id)
    check("add(id,'last_same_priority'" in species_history and
          "add(id,'priority_preserved'" in species_history and
          "add('lax_incense','accuracy_rng'" in species_history and
          "['full_incense','lagging_tail']" in species_history,
          "Historial funcional nativo B09 no encontrado")
    for specific in SPECIES_HOOKS:
        check(f"'{specific}'" in species_history and
              ("species_defense" in species_history or "species_boost" in species_history),
              "No hay antecedente nativo específico de " + specific)
    check("kings_rock" in flinch_history and "flinch_rng" in flinch_history
          and "l.includes('|flinch')" in flinch_history,
          "Falta referencia histórica nativa de retroceso Roca del Rey")
    check("for(const [family,table] of [['type_boost',booster]" in history,
          "No hay escenario histórico nativo positivo de potenciadores de tipo")
    check("family+'_nonmatching'" in history
          and "foe(a).hp<foe(b).hp" in history,
          "Falta control histórico positivo/negativo de daño")
    for item, (kind, move, native) in ITEMS.items():
        check(item in ";".join(r["ids"] for r in queue[:10]).split(";"),
              "Objeto fuera de los diez bloques autorizados " + item)
        check(scope[item]["estado_contenido"] == "SELECCIONADO"
              and scope[item]["familia"] == "HELD_COMBAT_CANDIDATE",
              "Objeto no seleccionado: " + item)
        check(inventory[item]["family"] == "HELD_COMBAT_CANDIDATE"
              and inventory[item]["native_entry"] == "True"
              and inventory[item]["native_id"] == native
              and ((item == "full_incense" and inventory[item]["native_hooks"] == "") or
                   (B09_HOOKS.get(item) or BLOCK07_HOOKS.get(item) or SPECIES_HOOKS.get(item) or
                    ("onModifyMove" if item == "kings_rock" else
                     "onSourceTryPrimaryHit" if item.endswith("_gem") else "onBasePower"))
                   in inventory[item]["native_hooks"]),
              "Objeto sin soporte nativo funcional: " + item)
        if (item != "kings_rock" and item not in SPECIES_HOOKS
                and item not in BLOCK07_HOOKS and item not in B09_HOOKS
                and not item.endswith("_incense") and not item.endswith("_gem")):
            check(f"{kind}:'{item}'" in history and f"{kind}:'{move}'" in history,
                  "Referencias de tipo y ataque incoherentes: " + item)

    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(data["schema_version"] == 1 and data["worker"] == "W01"
          and data["campaign"] == "CAMP_005" and data["kind"] == "NEW_IDS"
          and data["format"] == "gen9calvounifiedv1", "Fixture CAMPAÑA_005 inválido")
    check(data["variants"] == MODES, "Falta un modo activo, sin objeto o reserva")
    check(len(data["blocks"]) == 10
          and [b["block"] for b in data["blocks"]] ==
              ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10"]
          and all(data["blocks"][i]["ids"] == list(ITEMS)[i*3:(i+1)*3]
                  for i in range(10)),
          "Fixture no sigue los bloques 01 a 10 exactos de IA6")
    cases = data["cases"]
    check(len(cases) == 90 and len({c["id"] for c in cases}) == 90,
          "Se exigen 90 escenarios distintos")
    for i, block in enumerate(data["blocks"]):
        check(set(block["cases"]) == {c["id"] for c in cases
                                       if c["block"] == f"{i+1:02d}"},
              "Escenarios fuera del bloque oficial " + block["block"])
    pairs = 0
    seen = set()
    for index, (item, (_, matching_move, _)) in enumerate(ITEMS.items()):
        if item in BLOCK10_CASES:
            for suffix,op,move,seeds in BLOCK10_CASES[item]:
                label = f"{item}_{suffix}"
                found = [c for c in cases if c["id"] == label]
                check(len(found) == 1, "Falta escenario B10 " + label)
                c = found[0]
                check(c["block"] == "10" and c["item_id"] == item and c["op"] == op,
                      "B10 fuera de propiedad " + label)
                check((c["actor_species"],c["foe_species"],c["own_move"],c["foe_move"]) ==
                      ("mew","mew",move,"amnesia") and c["seeds"] == seeds,
                      "B10 altera datos o semillas " + label)
                check(c["history"] == "showdown_native_items:onSourceTryPrimaryHit",
                      "B10 no vincula el hook canónico " + label)
                seen.add(label)
                pairs += len(seeds)
            continue
        if item in BLOCK09_CASES:
            for suffix,op,actor,foe,own,foe_move,seeds,tag in BLOCK09_CASES[item]:
                key = f"{item}_{suffix}"
                found = [c for c in cases if c["id"] == key]
                check(len(found) == 1, "B09 falta caso " + key)
                c = found[0]
                check(c["block"] == "09" and c["item_id"] == item and c["op"] == op,
                      "B09 caso fuera de propiedad " + key)
                check((c["actor_species"],c["foe_species"],c["own_move"],c["foe_move"]) ==
                      (actor,foe,own,foe_move) and c["seeds"] == seeds,
                      "B09 cambia Pokémon, movimientos o RNG " + key)
                check(c["history"] == "tools/item_audit/held_effect_sweep_v3.cjs:"+tag,
                      "B09 sin procedencia de regla " + key)
                seen.add(key)
                pairs += len(seeds)
            continue
        if item in BLOCK07_CASES:
            for suffix, op, actor, foe, own_move, foe_move, seeds, follow in BLOCK07_CASES[item]:
                label = f"{item}_{suffix}"
                found = [c for c in cases if c["id"] == label]
                check(len(found) == 1, "Caso funcional B07 ausente: " + label)
                c = found[0]
                check(c["block"] == "07" and c["item_id"] == item and c["op"] == op,
                      "Caso B07 fuera de propiedad: " + label)
                check((c["actor_species"], c["foe_species"], c["own_move"], c["foe_move"])
                      == (actor, foe, own_move, foe_move), "Portador o combate alterado B07: " + label)
                check(c.get("follow_move") == follow and c["seeds"] == seeds
                      and all(type(i) is int and i > 0 for i in seeds),
                      "Semillas o segundo movimiento B07 cambiados: " + label)
                check(c["history"] == "tools/item_audit/held_effect_sweep_v3.cjs:" +
                      {"quick_powder":"speed_species","razor_claw":"critical_stage","razor_fang":"flinch_rng"}[item],
                      "Sin trazabilidad histórica B07: " + label)
                seen.add(label)
                pairs += len(seeds)
            continue
        if item in SPECIES_CASES:
            for suffix, op, actor, foe, move, foe_move, seeds in SPECIES_CASES[item]:
                label = f"{item}_{suffix}"
                found = [c for c in cases if c["id"] == label]
                check(len(found) == 1, "Caso por especie ausente: " + label)
                c = found[0]
                check(c["block"] == f"{index // 3 + 1:02d}" and
                      c["item_id"] == item and c["op"] == op,
                      "Escenario de especie fuera de autorización: " + label)
                check(c["actor_species"] == actor and c["foe_species"] == foe and
                      c["own_move"] == move and c["foe_move"] == foe_move,
                      "Contratos de portador, rival o categoría alterados: " + label)
                check(c["seeds"] == seeds and
                      all(type(seed) is int and seed > 0 for seed in seeds),
                      "Semillas específicas alteradas: " + label)
                check(c["history"] ==
                      "tools/item_audit/held_effect_sweep_v3.cjs:species_effect",
                      "Sin referencia nativa del efecto por especie: " + label)
                seen.add(label)
                pairs += len(seeds)
            continue
        wrong_move = "water_gun" if item == "silk_scarf" else "tackle"
        plans = ((
            ("flinch", "kings_rock_flinch", "tackle", list(range(1, 65))),
            ("immune", "kings_rock_immune", "tackle", [19]),
            ("status", "kings_rock_status", "reflect", [19]),
        ) if item == "kings_rock" else (
            ("matching", "matching_type_boost", matching_move, [19, 23]),
            ("nonmatching", "nonmatching_control", wrong_move, [19]),
            ("status", "status_control", "reflect", [19]),
        ))
        for suffix, op, move, seeds in plans:
            label = f"{item}_{suffix}"
            found = [c for c in cases if c["id"] == label]
            check(len(found) == 1, "Caso funcional ausente " + label)
            c = found[0]
            check(c["block"] == f"{index // 3 + 1:02d}"
                  and c["item_id"] == item and c["op"] == op,
                  "Operación o propietario incorrecto: " + label)
            target = ("gengar" if suffix == "immune" else "snorlax") if item == "kings_rock" else "mew"
            target_move = "tackle" if item == "kings_rock" else "amnesia"
            check(c["actor_species"] == "mew" and c["foe_species"] == target
                  and c["own_move"] == move and c["foe_move"] == target_move,
                  "Pokémon y movimiento real alterado: " + label)
            check(c["seeds"] == seeds and all(type(i) is int and i > 0 for i in seeds),
                  "Semillas de control alteradas: " + label)
            reference = ("tools/item_audit/held_effect_sweep_v3.cjs:flinch_rng"
                         if item == "kings_rock" else
                         ("tools/item_audit/held_effect_sweep_v3.cjs:" +
                          ("type_boost" if suffix == "matching" else
                           "wrong_type" if suffix == "nonmatching" else "status_control"))
                         if item.endswith("_incense") else
                         "tools/item_audit/held_effect_sweep_v2.cjs:type_boost")
            check(c["history"] == reference,
                  "Sin trazabilidad a prueba nativa: " + label)
            seen.add(label)
            pairs += len(seeds)
    check(seen == {c["id"] for c in cases} and pairs == 272,
          "No hay 272 pares caso-semilla autorizados")

    runner = RUNNER.read_text(encoding="utf-8")
    for token in (
        'extends "res://tests/gameplay/parallel_items_w01_campaign_004.gd"',
        'call_deferred("_w01_c004_probe_lane"',
        '_compare_c005(row, observed)',
        'x.get("restored", false)',
        'x.get("owner_unchanged", false)',
        'a.damage > n.damage',
        'a.damage == n.damage',
        'not a.after.own_consumed',
        'CAMP005_W01_GODOT PASS blocks=',
    ):
        check(token in runner, "Runner carece de contrato funcional: " + token)
    for token in ("kings_rock_flinch", "kings_rock_immune", "kings_rock_status",
                  "c005_king_rock_activated", "c005_king_rock_not_activated",
                  "flinched", "super._probe_w01_c004"):
        check(token in runner, "Falta verificación positiva nativa Roca del Rey: " + token)
    for token in ("holder_special_defense", "holder_special_attack",
                  "holder_physical_defense", "transformed_no_boost",
                  "wrong_species_defense", "wrong_species_attack",
                  "a.start.hp", "a.after.hp", "a.damage > n.damage",
                  "_probe_c005_transformed_stable", "_switch_choice(session, &\"reserve\")",
                  "post_switch_stable", "stable_snapshot"):
        check(token in runner, "No hay control positivo o negativo por especie: " + token)
    for token in ("quick_powder_untransformed", "quick_powder_wrong_species",
                  "quick_powder_transformed", "razor_claw_focus_critical",
                  "razor_claw_immune", "razor_claw_status", "razor_fang_flinch",
                  "razor_fang_immune", "razor_fang_status",
                  "c005_razor_claw_exclusive", "c005_razor_fang_activated",
                  "c005_razor_fang_not_activated", "_probe_c005_transformed_stable"):
        check(token in runner, "No hay efecto o control B07 en Godot: " + token)
    for label in ("odd_incense", "rock_incense", "rose_incense"):
        check(f'"{label}"' in runner, "No se comprueba L2 nativo de incienso en Godot: " + label)
    check("a.damage > n.damage and n.damage > 0 and n.damage == r.damage" in runner,
          "Falta prueba real de daño aumentado solo al portador")
    for token in ("full_incense_last", "full_incense_priority", "full_incense_status",
                  "lax_incense_accuracy", "lax_incense_never_miss", "lax_incense_status",
                  "c005_lax_missed", "c005_lax_hit", "foe_missed",
                  "sea_incense", "full_incense", "lax_incense"):
        check(token in runner, "Falta control B09 en Godot: " + token)
    for token in ("gem_matching", "gem_nonmatching", "gem_status",
                  "_probe_c005_gem_matching", "gem_first_consumed",
                  "gem_second_consumed", "gem_mid_save", "gem_final_save",
                  "normal_gem", "fire_gem", "water_gem"):
        check(token in runner, "Falta prueba de gemas y SaveV2: " + token)
    check(NATIVE_B10.is_file(), "Falta prueba nativa B10")
    check(NATIVE_B09.is_file(), "Falta prueba nativa B09")
    check(NATIVE_B07.is_file(), "Falta prueba nativa específica B07")
    check("await _restore_probe(" in PARENT_RUNNER.read_text(encoding="utf-8"),
          "Falta restauración real SaveV2 heredada")

    return len(progress)


def main() -> int:
    argparse.ArgumentParser(description=__doc__).add_argument("--ci", action="store_true")
    try:
        n = validate()
        native = subprocess.run(["node", str(NATIVE_B07)], cwd=ROOT,
                                check=True, text=True, capture_output=True)
        check("W01_B07_NATIVE_SPEED PASS cases=3" in native.stdout,
              "Prueba nativa B07 no certificó Velocidad y Transformación")
        print(native.stdout.strip())
        native09 = subprocess.run(["node", str(NATIVE_B09)], cwd=ROOT,
                                  check=True, text=True, capture_output=True)
        check("W01_B09_NATIVE PASS" in native09.stdout,
              "B09 no acreditó potencia, prioridad y RNG")
        print(native09.stdout.strip())
        native10 = subprocess.run(["node", str(NATIVE_B10)], cwd=ROOT,
                                  check=True, text=True, capture_output=True)
        check("W01_B10_NATIVE PASS" in native10.stdout,
              "B10 no acredita consumo único + casos negativos")
        print(native10.stdout.strip())
    except (ValueError, KeyError, OSError, json.JSONDecodeError, TypeError,
            subprocess.CalledProcessError) as exc:
        if isinstance(exc, subprocess.CalledProcessError):
            print("W01_B07_NATIVE_STDERR:", exc.stderr)
            print("W01_B07_NATIVE_STDOUT:", exc.stdout)
        print("CAMP005_W01_PY FAIL:", exc)
        return 1
    print(f"CAMP005_W01_PY PASS blocks={n} checks={CHECKS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
