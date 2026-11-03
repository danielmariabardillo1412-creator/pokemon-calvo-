"""Contratos de pruebas W02/CAMP003. --ci valida evidencia estática real;
la CI ejecuta separadamente Godot nativo y exige ambos recibos.
"""
import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_003.json"
QUEUE = ROOT / "docs/coordination/items_parallel_v1/CAMPAIGN_003_QUEUE_APPROVED.csv"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv"
NATIVE_V2 = ROOT / "tools/item_audit/held_effect_sweep_v2.cjs"
NATIVE_V3 = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
MODES = ("active", "none", "reserve")
IDS_01 = ("aguav_berry", "apicot_berry", "aspear_berry", "babiri_berry")
EXPECTED_01 = {
    "aguav_disliked_naughty": ("aguav_berry", "heal_flavor", "naughty", "fifth", "", "amnesia", True, True),
    "aguav_neutral_hardy": ("aguav_berry", "heal_flavor", "hardy", "fifth", "", "amnesia", True, False),
    "aguav_above_threshold": ("aguav_berry", "heal_flavor", "naughty", "near_full", "", "amnesia", False, False),
    "apicot_pinch": ("apicot_berry", "boost_spd", "hardy", "fifth", "", "amnesia", True, False),
    "apicot_not_triggered": ("apicot_berry", "boost_spd", "hardy", "near_full", "", "amnesia", False, False),
    "aspear_frozen": ("aspear_berry", "cure_freeze", "hardy", "full", "freeze", "amnesia", True, False),
    "aspear_healthy": ("aspear_berry", "cure_freeze", "hardy", "full", "", "amnesia", False, False),
    "babiri_super_effective_steel": ("babiri_berry", "resist_steel", "hardy", "full", "", "flash_cannon", True, False),
    "babiri_wrong_type": ("babiri_berry", "resist_steel", "hardy", "full", "", "tackle", False, False),
}


EXPECTED_02 = {
    "charti_matching_c003": ("charti_berry", "charizard", "smack_down", True, "rock"),
    "charti_nonmatching_c003": ("charti_berry", "charizard", "tackle", False, "rock"),
    "chilan_matching_c003": ("chilan_berry", "mew", "tackle", True, "normal"),
    "chilan_nonmatching_c003": ("chilan_berry", "mew", "surf", False, "normal"),
    "chople_matching_c003": ("chople_berry", "snorlax", "brick_break", True, "fighting"),
    "chople_nonmatching_c003": ("chople_berry", "snorlax", "tackle", False, "fighting"),
    "coba_matching_c003": ("coba_berry", "venusaur", "aerial_ace", True, "flying"),
    "coba_nonmatching_c003": ("coba_berry", "venusaur", "tackle", False, "flying"),
}

EXPECTED_03 = {
    "colbur_dark_c003": ("colbur_berry", "resist_type", "mew", "mew", "dark_pulse", "full", True, {"expected_type": "dark"}),
    "colbur_normal_c003": ("colbur_berry", "resist_type", "mew", "mew", "tackle", "full", False, {"expected_type": "dark"}),
    "custap_low_first_c003": ("custap_berry", "priority_order", "snorlax", "gengar", "reflect", "fifth", True, {"expected_first": True}),
    "custap_full_no_priority_c003": ("custap_berry", "priority_order", "snorlax", "gengar", "reflect", "full", False, {"expected_first": False}),
    "enigma_effective_c003": ("enigma_berry", "heal_super_effective", "gyarados", "mew", "thunder_shock", "full", True, {"expected_type": "electric", "heal_denominator": 4}),
    "enigma_neutral_c003": ("enigma_berry", "heal_super_effective", "gyarados", "mew", "tackle", "full", False, {"expected_type": "electric", "heal_denominator": 4}),
    "ganlon_low_boost_c003": ("ganlon_berry", "boost_def", "mew", "mew", "amnesia", "fifth", True, {"boost_stat": "def"}),
    "ganlon_high_no_boost_c003": ("ganlon_berry", "boost_def", "mew", "mew", "amnesia", "near_full", False, {"boost_stat": "def"}),
}

EXPECTED_04 = {
    "haban_dragon_hit_c003": ("haban_berry", "resist_type", "dragonite", "mew", "dragon_pulse", "full", True, "hardy", False, {"expected_type": "dragon"}),
    "haban_wrong_normal_c003": ("haban_berry", "resist_type", "dragonite", "mew", "tackle", "full", False, "hardy", False, {"expected_type": "dragon"}),
    "iapapa_lonely_low_c003": ("iapapa_berry", "heal_flavor", "mew", "mew", "amnesia", "fifth", True, "lonely", True, {}),
    "iapapa_hardy_low_c003": ("iapapa_berry", "heal_flavor", "mew", "mew", "amnesia", "fifth", True, "hardy", False, {}),
    "iapapa_lonely_high_c003": ("iapapa_berry", "heal_flavor", "mew", "mew", "amnesia", "near_full", False, "lonely", False, {}),
    "jaboca_physical_tackle_c003": ("jaboca_berry", "retaliate_physical", "mew", "mew", "tackle", "full", True, "hardy", False, {"expected_category": "physical", "retaliation_denominator": 8}),
    "jaboca_special_confusion_c003": ("jaboca_berry", "retaliate_physical", "mew", "mew", "confusion", "full", False, "hardy", False, {"expected_category": "special", "retaliation_denominator": 8}),
    "kasib_ghost_hit_c003": ("kasib_berry", "resist_type", "mew", "mew", "shadow_ball", "full", True, "hardy", False, {"expected_type": "ghost"}),
    "kasib_wrong_normal_c003": ("kasib_berry", "resist_type", "mew", "mew", "tackle", "full", False, "hardy", False, {"expected_type": "ghost"}),
}

EXPECTED_05 = {
    "kebia_poison_hit_c003": ("kebia_berry", "resist_type", "clefable", "mew", "sludge_bomb", "full", True, {"expected_type": "poison"}),
    "kebia_normal_reject_c003": ("kebia_berry", "resist_type", "clefable", "mew", "tackle", "full", False, {"expected_type": "poison"}),
    "kee_physical_trigger_c003": ("kee_berry", "reactive_def", "mew", "mew", "tackle", "full", True, {"boost_stat": "def"}),
    "kee_special_reject_c003": ("kee_berry", "reactive_def", "mew", "mew", "confusion", "full", False, {"boost_stat": "def"}),
    "lansat_pinch_focus_c003": ("lansat_berry", "critical_focus", "mew", "mew", "amnesia", "fifth", True, {"expected_volatile": "focusenergy"}),
    "lansat_high_reject_c003": ("lansat_berry", "critical_focus", "mew", "mew", "amnesia", "near_full", False, {"expected_volatile": "focusenergy"}),
    "liechi_pinch_attack_c003": ("liechi_berry", "boost_atk", "mew", "mew", "amnesia", "fifth", True, {"boost_stat": "atk"}),
    "liechi_high_reject_c003": ("liechi_berry", "boost_atk", "mew", "mew", "amnesia", "near_full", False, {"boost_stat": "atk"}),
}


EXPECTED_06 = {
    "mago_brave_disliked_c003": ("mago_berry", "heal_flavor", "mew", "snorlax", "endeavor", "full", True, "brave", True, "amnesia", {"foe_initial_hp": 1}),
    "mago_hardy_neutral_c003": ("mago_berry", "heal_flavor", "mew", "snorlax", "endeavor", "full", True, "hardy", False, "amnesia", {"foe_initial_hp": 1}),
    "mago_above_threshold_c003": ("mago_berry", "heal_flavor", "mew", "mew", "amnesia", "near_full", False, "brave", False, "amnesia", {}),
    "maranga_special_hit_c003": ("maranga_berry", "boost_spd", "mew", "mew", "confusion", "full", True, "hardy", False, "reflect", {"boost_stat": "spd"}),
    "maranga_physical_reject_c003": ("maranga_berry", "boost_spd", "mew", "mew", "tackle", "full", False, "hardy", False, "reflect", {"boost_stat": "spd"}),
    "micle_low_next_move_c003": ("micle_berry", "accuracy_next_move", "mew", "mew", "amnesia", "fifth", True, "hardy", False, "reflect", {"own_moves": ["reflect", "hydro_pump"], "next_move_slot": 2, "expected_volatile": "micleberry"}),
    "micle_high_reject_c003": ("micle_berry", "accuracy_next_move", "mew", "mew", "amnesia", "near_full", False, "hardy", False, "reflect", {"own_moves": ["reflect", "hydro_pump"], "next_move_slot": 2, "expected_volatile": "micleberry"}),
    "occa_fire_hit_c003": ("occa_berry", "resist_type", "scizor", "mew", "ember", "full", True, "hardy", False, "amnesia", {"expected_type": "fire"}),
    "occa_normal_reject_c003": ("occa_berry", "resist_type", "scizor", "mew", "tackle", "full", False, "hardy", False, "amnesia", {"expected_type": "fire"}),
}


EXPECTED_07 = {
    "passho_water_hit_c003": ("passho_berry", "resist_type", "charizard", "mew", "surf", "full", True, {"expected_type": "water"}),
    "passho_normal_reject_c003": ("passho_berry", "resist_type", "charizard", "mew", "tackle", "full", False, {"expected_type": "water"}),
    "payapa_psychic_hit_c003": ("payapa_berry", "resist_type", "gengar", "mew", "psychic", "full", True, {"expected_type": "psychic"}),
    "payapa_normal_reject_c003": ("payapa_berry", "resist_type", "gengar", "mew", "tackle", "full", False, {"expected_type": "psychic"}),
    "petaya_pinch_spa_c003": ("petaya_berry", "boost_spa", "mew", "mew", "amnesia", "fifth", True, {"boost_stat": "spa"}),
    "petaya_high_reject_c003": ("petaya_berry", "boost_spa", "mew", "mew", "amnesia", "near_full", False, {"boost_stat": "spa"}),
    "rindo_grass_hit_c003": ("rindo_berry", "resist_type", "blastoise", "mew", "energy_ball", "full", True, {"expected_type": "grass"}),
    "rindo_normal_reject_c003": ("rindo_berry", "resist_type", "blastoise", "mew", "tackle", "full", False, {"expected_type": "grass"}),
}


EXPECTED_08 = {
    "roseli_fairy_effective_c003": ("roseli_berry", "resist_type", "garchomp", "mew", "dazzling_gleam", "full", True, {"expected_type": "fairy"}),
    "roseli_normal_reject_c003": ("roseli_berry", "resist_type", "garchomp", "mew", "tackle", "full", False, {"expected_type": "fairy"}),
    "rowap_special_retaliation_c003": ("rowap_berry", "retaliate_special", "mew", "mew", "confusion", "full", True, {"expected_category": "special", "retaliation_denominator": 8}),
    "rowap_physical_reject_c003": ("rowap_berry", "retaliate_special", "mew", "mew", "tackle", "full", False, {"expected_category": "physical", "retaliation_denominator": 8}),
    "salac_pinch_speed_c003": ("salac_berry", "boost_spe", "mew", "mew", "amnesia", "fifth", True, {"boost_stat": "spe"}),
    "salac_high_reject_c003": ("salac_berry", "boost_spe", "mew", "mew", "amnesia", "near_full", False, {"boost_stat": "spe"}),
    "shuca_ground_effective_c003": ("shuca_berry", "resist_type", "pikachu", "mew", "bulldoze", "full", True, {"expected_type": "ground"}),
    "shuca_normal_reject_c003": ("shuca_berry", "resist_type", "pikachu", "mew", "tackle", "full", False, {"expected_type": "ground"}),
}


EXPECTED_09 = {
    "starf_low_two_random_c003": ("starf_berry", "boost_random_two", "mew", "mew", "amnesia", "fifth", True, "hardy", False, "reflect", {"expected_stage": 2}),
    "starf_high_no_boost_c003": ("starf_berry", "boost_random_two", "mew", "mew", "amnesia", "near_full", False, "hardy", False, "reflect", {"expected_stage": 2}),
    "tanga_bug_effective_c003": ("tanga_berry", "resist_type", "mew", "mew", "bug_buzz", "full", True, "hardy", False, "reflect", {"expected_type": "bug"}),
    "tanga_normal_reject_c003": ("tanga_berry", "resist_type", "mew", "mew", "tackle", "full", False, "hardy", False, "reflect", {"expected_type": "bug"}),
    "wacan_electric_effective_c003": ("wacan_berry", "resist_type", "gyarados", "mew", "thunder_shock", "full", True, "hardy", False, "reflect", {"expected_type": "electric"}),
    "wacan_normal_reject_c003": ("wacan_berry", "resist_type", "gyarados", "mew", "tackle", "full", False, "hardy", False, "reflect", {"expected_type": "electric"}),
    "wiki_adamant_disliked_c003": ("wiki_berry", "heal_flavor", "mew", "snorlax", "endeavor", "full", True, "adamant", True, "reflect", {"foe_initial_hp": 1}),
    "wiki_hardy_neutral_c003": ("wiki_berry", "heal_flavor", "mew", "snorlax", "endeavor", "full", True, "hardy", False, "reflect", {"foe_initial_hp": 1}),
    "wiki_high_no_trigger_c003": ("wiki_berry", "heal_flavor", "mew", "mew", "amnesia", "near_full", False, "adamant", False, "reflect", {}),
}


EXPECTED_10_BATTLE = {
    "yache_ice_shard_hit_c003": ("yache_berry", "ice_shard", True, "ice"),
    "yache_normal_reject_c003": ("yache_berry", "tackle", False, "ice"),
}
EXPECTED_10_FIELD = {
    "grepa_ev20_friend100_c003": ("grepa_berry", "special_defense", 20, 100, "full", True, 10, 5),
    "grepa_ev0_friend200_c003": ("grepa_berry", "special_defense", 0, 200, "full", True, 0, 2),
    "grepa_ev0_friend255_noop_c003": ("grepa_berry", "special_defense", 0, 255, "full", False, 0, 0),
    "hondew_ev20_friend100_c003": ("hondew_berry", "special_attack", 20, 100, "full", True, 10, 5),
    "hondew_ev0_friend200_c003": ("hondew_berry", "special_attack", 0, 200, "full", True, 0, 2),
    "hondew_ev0_friend255_noop_c003": ("hondew_berry", "special_attack", 0, 255, "full", False, 0, 0),
    "pomeg_ev252_hp1_c003": ("pomeg_berry", "hp", 252, 100, "one", True, 10, 5),
    "pomeg_ev0_friend200_c003": ("pomeg_berry", "hp", 0, 200, "full", True, 0, 2),
    "pomeg_ev0_friend255_noop_c003": ("pomeg_berry", "hp", 0, 255, "full", False, 0, 0),
}


class ContractError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.count = 0

    def demand(self, condition, reason):
        self.count += 1
        if not condition:
            raise ContractError(reason)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def validate(fixture, queue, progress, check):
    check.demand(isinstance(fixture, dict), "Fixture no es objeto")
    check.demand(set(fixture) == {"schema_version", "campaign", "worker",
        "completed_blocks", "format", "level", "seed", "modes",
        "field_scope", "blocks", "limitations"}, "Esquema fuera del permiso")
    check.demand(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_003"
                 and fixture["worker"] == "W02", "Identidad o campaña incorrectas")
    check.demand(fixture["format"] == "gen9calvounifiedv1"
                 and fixture["level"] == 100 and fixture["seed"] == [23, 19, 29, 43],
                 "Formato/RNG reproducible no coincide")
    check.demand(fixture["modes"] == list(MODES) and fixture["field_scope"] == "NOT_TESTED",
                 "Faltan controles o se declara uso de campo")
    tasks = [row for row in queue if row["trabajadora"] == "W02"]
    check.demand(len(tasks) == 10
                 and [r["bloque"] for r in tasks] == [f"{i:02d}" for i in range(1, 11)],
                 "Cola oficial W02 distinta de diez bloques")
    count = len(progress)
    check.demand(1 <= count <= 10, "Se exige progreso publicado en el CSV")
    check.demand(len(fixture["blocks"]) == count, "Fixture no coincide con bloques terminados")
    check.demand(fixture["completed_blocks"] == list(range(1, count + 1)),
                 "Microbloques no consecutivos")
    for i, entry in enumerate(fixture["blocks"]):
        authorized = tasks[i]
        ids = authorized["ids"].split(";")
        check.demand(entry["block"] == authorized["bloque"]
                     and entry["ids"] == ids, "IDs sin reserva oficial")
        check.demand(progress[i]["bloque"] == authorized["bloque"]
                     and progress[i]["ids"] == authorized["ids"],
                     "CSV publicado discrepa de encargo")
        check.demand(len(ids) == 4 and len(set(ids)) == 4, "Bloque W02 exige cuatro bayas")
        check.demand(type(entry["cases"]) is list and bool(entry["cases"]),
                     "Bloque sin escenarios, no puede dar PASS")
        if i == 0:
            check.demand(tuple(ids) == IDS_01 and len(entry["cases"]) == 9,
                         "ITER_01 exige exactamente nueve escenarios para cuatro IDs")
            seen = set()
            for case in entry["cases"]:
                check.demand(set(case) == {"scenario", "id", "kind", "nature", "start",
                    "status", "foe_species", "foe_move", "consumes", "confuses"}
                    or (set(case) == {"scenario", "id", "kind", "nature", "start",
                    "status", "foe_species", "foe_move", "consumes", "confuses",
                    "actor_species"} and case.get("actor_species") == "clefable"),
                    "Caso con campos extra o faltantes")
                scenario = case["scenario"]
                check.demand(scenario in EXPECTED_01 and scenario not in seen,
                             "Escenario desconocido o duplicado")
                seen.add(scenario)
                expected = EXPECTED_01[scenario]
                actual = (case["id"], case["kind"], case["nature"], case["start"],
                          case["status"], case["foe_move"], case["consumes"], case["confuses"])
                check.demand(actual == expected and case["foe_species"] == "mew",
                             "Contrato de naturaleza/umbral/tipo alterado: " + scenario)
                check.demand(case["id"] in ids, "Caso ajeno a la reserva")
            check.demand(seen == set(EXPECTED_01), "Cobertura positiva/negativa incompleta")
        elif i == 1:
            check.demand(len(entry["cases"]) == 8 and len(ids) == 4,
                         "ITER_02 exige ocho escenas nativas exactas")
            check.demand(entry["source_evidence"] == ["tools/item_audit/held_effect_sweep_v2.cjs"],
                         "Fuente histórica de resistencias incorrecta")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(set(case) == {"scenario", "id", "kind", "nature", "start",
                    "status", "actor_species", "foe_species", "foe_move",
                    "consumes", "confuses", "expected_type"},
                    "Esquema de resistencia con campos extra o ausentes")
                check.demand(name in EXPECTED_02 and name not in seen,
                             "Escenario repetido o inventado en ITER_02")
                seen.add(name)
                expected = EXPECTED_02[name]
                actual = (case["id"], case["actor_species"], case["foe_move"],
                          case["consumes"], case["expected_type"])
                check.demand(actual == expected, "Tipo/especie/consumo adulterado: " + name)
                check.demand(case["kind"] == "resist_type"
                             and case["nature"] == "hardy" and case["start"] == "full"
                             and case["status"] == "" and case["foe_species"] == "mew"
                             and case["confuses"] is False,
                             "Control común de testigo de resistencia alterado")
            check.demand(seen == set(EXPECTED_02), "Falta alguna escena positiva/negativa")
        elif i == 2:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Faltan contratos historicos de Colbur, Custap, Enigma y Ganlon")
            check.demand(len(entry["cases"]) == 8, "ITER_03 requiere ocho escenarios")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_03 and name not in seen,
                             "Escenario ITER_03 inesperado o duplicado")
                seen.add(name)
                item, kind, actor, foe, move, state, consumes, extra = EXPECTED_03[name]
                expected_keys = {"scenario", "id", "kind", "nature", "start",
                                 "status", "actor_species", "foe_species",
                                 "foe_move", "consumes", "confuses"} | set(extra)
                check.demand(set(case) == expected_keys,
                             "Campos inesperados en escenario de bloque 03")
                check.demand((case["id"], case["kind"], case["actor_species"],
                              case["foe_species"], case["foe_move"], case["start"],
                              case["consumes"]) == (item, kind, actor, foe,
                                                   move, state, consumes),
                             "Mecanica/tipo/especie/umbral o consumo alterados: " + name)
                check.demand(case["nature"] == "hardy" and case["status"] == ""
                             and case["confuses"] is False,
                             "Controles de naturaleza/estado adulterados")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Expectativa individual manipulada: " + name + "/" + key)
            check.demand(seen == set(EXPECTED_03),
                         "Cobertura positiva/negativa incompleta en bloque 03")
        elif i == 3:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Faltan precedentes exactos de Haban Iapapa Jaboca Kasib")
            check.demand(len(entry["cases"]) == 9 and len(ids) == 4,
                         "ITER_04 exige nueve escenarios para cuatro bayas")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_04 and name not in seen,
                             "Escenario ITER_04 duplicado o no autorizado")
                seen.add(name)
                item, kind, actor, foe, move, hp_state, spent, nature, confused, extra = EXPECTED_04[name]
                base_keys = {"scenario", "id", "kind", "nature", "start",
                             "status", "actor_species", "foe_species",
                             "foe_move", "consumes", "confuses"}
                check.demand(set(case) == base_keys | set(extra),
                             "Campos ausentes/extra de resistencia sabor o reaccion")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"], case["nature"], case["confuses"])
                check.demand(actual == (item, kind, actor, foe, move, hp_state,
                                        spent, nature, confused) and case["status"] == "",
                             "Contrato de tipo, disparador, naturaleza o HP manipulado: " + name)
                check.demand(case["id"] in ids,
                             "Item fuera de reserva oficial de bloque 04")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Contrato especial modificado: " + name + "/" + key)
            check.demand(seen == set(EXPECTED_04),
                         "Falta alguno de los nueve escenarios del bloque 04")
        elif i == 4:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Faltan fuentes V2/V3 para Kebia Kee Lansat Liechi")
            check.demand(len(entry["cases"]) == 8 and len(ids) == 4,
                         "ITER_05 exige ocho casos exactos en cuatro bayas")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_05 and name not in seen,
                             "Escenario ITER_05 ajeno a la reserva o repetido")
                seen.add(name)
                item, kind, actor, foe, move, hp_state, spent, extra = EXPECTED_05[name]
                base_keys = {"scenario", "id", "kind", "nature", "start",
                             "status", "actor_species", "foe_species",
                             "foe_move", "consumes", "confuses", "own_move"}
                check.demand(set(case) == base_keys | set(extra),
                             "Esquema distinto o campos no autorizados del bloque 05")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"])
                check.demand(actual == (item, kind, actor, foe, move, hp_state, spent),
                             "Tipo, categoria, movimiento, umbral o consumo adulterado")
                check.demand(case["nature"] == "hardy" and case["status"] == ""
                             and case["confuses"] is False and case["own_move"] == "amnesia",
                             "Condiciones del portador no coinciden con testigos neutrales")
                check.demand(case["id"] in ids, "ID fuera del bloque 05 autorizado")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Expectativa de efecto manipulada: " + name + "/" + key)
            check.demand(seen == set(EXPECTED_05), "Faltan casos de activacion/rechazo")
        elif i == 5:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Faltan contratos previos de Mago Maranga Micle Occa")
            check.demand(len(entry["cases"]) == 9 and len(ids) == 4,
                         "ITER_06 exige exactamente nueve casos y cuatro IDs")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_06 and name not in seen,
                             "Escenario bloque 06 ausente de contrato o repetido")
                seen.add(name)
                item, kind, actor, foe, move, start_hp, spent, nature, confused, own_move, extra = EXPECTED_06[name]
                schema = {"scenario", "id", "kind", "nature", "start",
                          "status", "actor_species", "foe_species",
                          "foe_move", "consumes", "confuses", "own_move"} | set(extra)
                check.demand(set(case) == schema, "Esquema ITER_06 con campos extra/faltantes")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"], case["nature"], case["confuses"],
                          case["own_move"])
                check.demand(actual == (item, kind, actor, foe, move, start_hp,
                                        spent, nature, confused, own_move),
                             "Mecanica, naturaleza, movimiento o umbral adulterado")
                check.demand(case["id"] in ids and case["status"] == "",
                             "Condicion de estado o ID no autorizado")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Doble turno/efecto de baya alterado: " + name + "/" + key)
            check.demand(seen == set(EXPECTED_06),
                         "Cobertura incompleta de los nueve escenarios del bloque 06")
        elif i == 6:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs"],
                "Falta fuente de resistencias y Pinch Petaya V2")
            check.demand(len(entry["cases"]) == 8 and len(ids) == 4,
                         "ITER_07 requiere ocho casos de cuatro bayas")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_07 and name not in seen,
                             "Escenario 07 inesperado o duplicado")
                seen.add(name)
                item, kind, actor, foe, move, hp_state, spent, extra = EXPECTED_07[name]
                base = {"scenario", "id", "kind", "nature", "start", "status",
                        "actor_species", "foe_species", "foe_move", "consumes",
                        "confuses", "own_move"}
                check.demand(set(case) == base | set(extra),
                             "Esquema del bloque 07 incompleto o manipulado")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"])
                check.demand(actual == (item, kind, actor, foe, move, hp_state, spent),
                             "Tipo, especie, disparo o umbral alterado en bloque 07")
                check.demand(case["nature"] == "hardy" and case["status"] == ""
                             and case["confuses"] is False
                             and case["own_move"] == "amnesia" and case["id"] in ids,
                             "Controles de naturaleza, estado o movimiento no neutrales")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Expectativa de resistencia o SpA cambiada: " + name)
            check.demand(seen == set(EXPECTED_07),
                         "Falta un caso positivo o negativo del bloque 07")
        elif i == 7:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Precedentes V2 y V3 imprescindibles para bloque 08")
            check.demand(len(entry["cases"]) == 8 and len(ids) == 4,
                         "Bloque 08 exige ocho escenas para cuatro IDs")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_08 and name not in seen,
                             "Escenario 08 no autorizado o repetido")
                seen.add(name)
                item, kind, actor, foe, move, start_hp, spent, extra = EXPECTED_08[name]
                base = {"scenario", "id", "kind", "nature", "start",
                        "status", "actor_species", "foe_species",
                        "foe_move", "consumes", "confuses", "own_move"}
                check.demand(set(case) == base | set(extra),
                             "Campos nuevos, perdidos o falsos en bloque 08")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"])
                check.demand(actual == (item, kind, actor, foe, move, start_hp, spent),
                             "Tipo, especie, disparo o naturaleza de uso alterados")
                check.demand(case["nature"] == "hardy" and case["status"] == ""
                             and case["confuses"] is False and case["own_move"] == "amnesia"
                             and case["id"] in ids,
                             "Testigos de categoría/umbral cambiados en bloque 08")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Expectativa de protección/devolución/Velocidad alterada: " + name)
            check.demand(seen == set(EXPECTED_08),
                         "Falta caso positivo o negativo del bloque 08")
        elif i == 8:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tools/item_audit/held_effect_sweep_v3.cjs"],
                "Faltan pruebas nativas V2/V3 Starf Tanga Wacan Wiki")
            check.demand(len(entry["cases"]) == 9 and len(ids) == 4,
                         "ITER_09 exige 9 escenarios para exactamente 4 bayas")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name in EXPECTED_09 and name not in seen,
                             "Escenario bloque 09 no autorizado o repetido")
                seen.add(name)
                item, kind, actor, foe, move, hp_state, spent, nature, confused, own_move, extra = EXPECTED_09[name]
                schema = {"scenario", "id", "kind", "nature", "start",
                          "status", "actor_species", "foe_species",
                          "foe_move", "consumes", "confuses", "own_move"} | set(extra)
                check.demand(set(case) == schema,
                             "Esquema incompleto o manipulado del bloque 09")
                actual = (case["id"], case["kind"], case["actor_species"],
                          case["foe_species"], case["foe_move"], case["start"],
                          case["consumes"], case["nature"], case["confuses"],
                          case["own_move"])
                check.demand(actual == (item, kind, actor, foe, move, hp_state,
                                        spent, nature, confused, own_move)
                             and case["status"] == "" and case["id"] in ids,
                             "Umbral, efecto, especie, naturaleza o consumo manipulado")
                for key, value in extra.items():
                    check.demand(case[key] == value,
                                 "Contrato individual alterado: " + name + "/" + key)
            check.demand(seen == set(EXPECTED_09),
                         "Falta un escenario positivo/negativo del bloque 09")
        elif i == 9:
            check.demand(entry["source_evidence"] == [
                "tools/item_audit/held_effect_sweep_v2.cjs",
                "tests/gameplay/item_field_effects_v4.gd",
                "modules/inventory/field_item_effects.gd"],
                "Bloque 10 no distingue Yache combate y EV bayas de campo")
            check.demand(len(entry["cases"]) == 11 and len(ids) == 4,
                         "ITER_10 exige dos Yache y nueve EV/amistad")
            seen = set()
            for case in entry["cases"]:
                name = case["scenario"]
                check.demand(name not in seen and
                             (name in EXPECTED_10_BATTLE or name in EXPECTED_10_FIELD),
                             "Escenario bloque 10 extra o duplicado")
                seen.add(name)
                check.demand(case["id"] in ids, "Item fuera de la fila 10")
                if name in EXPECTED_10_BATTLE:
                    item, move, consumes, expected_type = EXPECTED_10_BATTLE[name]
                    check.demand(set(case) == {
                        "scenario", "id", "kind", "nature", "start", "status",
                        "actor_species", "foe_species", "foe_move", "consumes",
                        "confuses", "own_move", "expected_type"},
                        "Esquema Yache combate distinto de contrato")
                    check.demand(
                        (case["id"], case["foe_move"], case["consumes"],
                         case["expected_type"]) == (item, move, consumes, expected_type)
                        and (case["kind"], case["actor_species"], case["foe_species"],
                             case["nature"], case["start"], case["status"],
                             case["own_move"], case["confuses"]) ==
                            ("resist_type", "dragonite", "mew", "hardy", "full", "",
                             "reflect", False),
                        "Yache falta tipo supereficaz/control o se altera fuerza del golpe")
                else:
                    expected = EXPECTED_10_FIELD[name]
                    check.demand(set(case) == {
                        "scenario", "id", "kind", "stat", "start_ev", "start_friendship",
                        "start_hp", "applies", "ev_removed", "friendship_gain"},
                        "Esquema EV de campo inventado/modificado")
                    actual = (case["id"], case["stat"], case["start_ev"],
                              case["start_friendship"], case["start_hp"],
                              case["applies"], case["ev_removed"], case["friendship_gain"])
                    check.demand(actual == expected and case["kind"] == "field_ev_training",
                                 "EV, amistad, aceptación, HP o naturaleza de uso alterada")
            check.demand(seen == set(EXPECTED_10_BATTLE) | set(EXPECTED_10_FIELD),
                         "Falta control de rechazo/SaveV2 de bloque 10")
        else:
            raise ContractError("Bloque futuro sin contrato específico implementado")
    return count


def verify_sources(check):
    v2 = NATIVE_V2.read_text(encoding="utf-8")
    v3 = NATIVE_V3.read_text(encoding="utf-8")
    for needle in ("['aguav_berry','naughty']", "heal_and_disliked_flavor",
                   "heal_without_confusion", "high_hp_no_trigger"):
        check.demand(needle in v3, "No se localizó precedente Aguav: " + needle)
    for needle in ("apicot_berry:'spd'", "aspear_berry:'freeze'",
                   "steel:['babiri_berry','clefable']", "flash_cannon",
                   "resist_nonmatching", "pinch_not_triggered",
                   "rock:['charti_berry','charizard']", "rock:'smack_down'",
                   "normal:['chilan_berry','mew']", "normal:'tackle'",
                   "fighting:['chople_berry','snorlax']", "fighting:'brick_break'",
                   "flying:['coba_berry','venusaur']", "flying:'aerial_ace'",
                   "dark:['colbur_berry','mew']", "dark:'dark_pulse'",
                   "ganlon_berry:'def'",
                   "dragon:['haban_berry','dragonite']",
                   "ghost:['kasib_berry','mew']", "dragon:'dragon_pulse'",
                   "ghost:'shadow_ball'",
                   "poison:['kebia_berry','clefable']",
                   "poison:'sludge_bomb'",
                   "add('kee_berry','reactive_stat_berry'",
                   "liechi_berry:'atk'",
                   "fire:['occa_berry','scizor']",
                   "fire:'flamethrower'",
                   "add('maranga_berry','reactive_stat_berry'",
                   "water:['passho_berry','charizard']",
                   "water:'surf'",
                   "psychic:['payapa_berry','gengar']",
                   "psychic:'psychic'",
                   "petaya_berry:'spa'",
                   "grass:['rindo_berry','blastoise']",
                   "grass:'energy_ball'",
                   "fairy:['roseli_berry','garchomp']",
                   "fairy:'dazzling_gleam'",
                   "salac_berry:'spe'",
                   "ground:['shuca_berry','pikachu']",
                   "bug:['tanga_berry','mew']",
                   "bug:'bug_buzz'",
                   "electric:['wacan_berry','gyarados']",
                   "electric:'thunderbolt'",
                   "ice:['yache_berry','dragonite']"):
        check.demand(needle in v2, "No se localizó precedente V2: " + needle)
    field_v4 = (ROOT / "tests/gameplay/item_field_effects_v4.gd").read_text(encoding="utf-8")
    field_runtime = (ROOT / "modules/inventory/field_item_effects.gd").read_text(encoding="utf-8")
    for needle in ('"grepa_berry": "special_defense"', '"hondew_berry": "special_attack"',
                   '"pomeg_berry": "hp"', "static func _ev_berry(",
                   'creature.evs[stat] = maxi(0, old_ev - 10)',
                   'Friendship.increase(creature, [10, 5, 2])',
                   'creature.current_hp = clampi('):
        check.demand(needle in field_runtime,
                     "Falta implementación canónica de baya de entrenamiento: " + needle)
    for needle in ('"pomeg_berry": "hp"', '"grepa_berry": "special_defense"',
                   '"hondew_berry": "special_attack"', "berry EV -10 lower bound",
                   "full health follows new maximum", "Pomeg HP deficit without KO"):
        check.demand(needle in field_v4,
                     "No localizada prueba histórica de entrenamiento: " + needle)
    for needle in ("'custap_berry','low_hp_order'", "'custap_berry','full_hp'",
                   "'enigma_berry','super_effective_heal'",
                   "'enigma_berry','neutral_no_trigger'",
                   "foeMoves:['thunder_shock']",
                   "['iapapa_berry','lonely']",
                   "['jaboca_berry','tackle','confusion']",
                   "'category_retaliation'", "'wrong_category'",
                   "add('lansat_berry','critical_focus'",
                   "add('lansat_berry','full_hp'",
                   "['mago_berry','brave']",
                   "add('micle_berry','next_move_accuracy'",
                   "add('micle_berry','full_hp'",
                   "moves:['reflect','hydro_pump']",
                   "['rowap_berry','confusion','tackle']",
                   "['wiki_berry','adamant']",
                   "add('starf_berry','one_random_stat'",
                   "add('starf_berry','full_hp'"):
        check.demand(needle in v3, "No se localizo precedente V3: " + needle)


def negative_controls(fixture, queue, progress, check):
    edits = [
        lambda f: f["completed_blocks"].append(2),
        lambda f: f["blocks"][0]["ids"].append("sitrus_berry"),
        lambda f: f["blocks"][0]["cases"].pop(),
        lambda f: f["blocks"][0]["cases"][0].update({"nature": "hardy"}),
        lambda f: f.update({"field_scope": "TESTED"}),
        lambda f: f["blocks"][0]["cases"][-2].update({"foe_move": "tackle"}),
        lambda f: f["blocks"][0]["cases"][-1].update({"consumes": True}),
        lambda f: f["blocks"][0]["cases"][5].update({"status": ""}),
    ]
    if len(fixture["blocks"]) >= 2:
        edits.extend([
            lambda f: f["blocks"][1]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][1]["cases"][2].update({"consumes": False}),
            lambda f: f["blocks"][1]["cases"][4].update({"actor_species": "mew"}),
            lambda f: f["blocks"][1]["cases"][-1].update({"expected_type": "fire"}),
            lambda f: f["blocks"][1]["cases"].pop(),
            lambda f: f["blocks"][1]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 3:
        edits.extend([
            lambda f: f["blocks"][2]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][2]["cases"][2].update({"expected_first": False}),
            lambda f: f["blocks"][2]["cases"][3].update({"consumes": True}),
            lambda f: f["blocks"][2]["cases"][4].update({"heal_denominator": 3}),
            lambda f: f["blocks"][2]["cases"][5].update({"foe_move": "thunder_shock"}),
            lambda f: f["blocks"][2]["cases"][6].update({"boost_stat": "spd"}),
            lambda f: f["blocks"][2]["cases"].pop(),
            lambda f: f["blocks"][2]["ids"].append("figy_berry"),
        ])
    if len(fixture["blocks"]) >= 4:
        edits.extend([
            lambda f: f["blocks"][3]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][3]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][3]["cases"][2].update({"nature": "hardy"}),
            lambda f: f["blocks"][3]["cases"][3].update({"confuses": True}),
            lambda f: f["blocks"][3]["cases"][4].update({"start": "fifth"}),
            lambda f: f["blocks"][3]["cases"][5].update({"retaliation_denominator": 4}),
            lambda f: f["blocks"][3]["cases"][6].update({"expected_category": "physical"}),
            lambda f: f["blocks"][3]["cases"][-1].update({"foe_move": "shadow_ball"}),
            lambda f: f["blocks"][3]["cases"].pop(),
            lambda f: f["blocks"][3]["ids"].append("lum_berry"),
        ])
    if len(fixture["blocks"]) >= 5:
        edits.extend([
            lambda f: f["blocks"][4]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][4]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][4]["cases"][2].update({"foe_move": "confusion"}),
            lambda f: f["blocks"][4]["cases"][3].update({"boost_stat": "spd"}),
            lambda f: f["blocks"][4]["cases"][4].update({"start": "full"}),
            lambda f: f["blocks"][4]["cases"][5].update({"consumes": True}),
            lambda f: f["blocks"][4]["cases"][6].update({"own_move": "swords_dance"}),
            lambda f: f["blocks"][4]["cases"][7].update({"boost_stat": "def"}),
            lambda f: f["blocks"][4]["cases"].pop(),
            lambda f: f["blocks"][4]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 6:
        edits.extend([
            lambda f: f["blocks"][5]["cases"][0].update({"nature": "hardy"}),
            lambda f: f["blocks"][5]["cases"][0].update({"foe_initial_hp": 2}),
            lambda f: f["blocks"][5]["cases"][1].update({"confuses": True}),
            lambda f: f["blocks"][5]["cases"][1].update({"foe_move": "amnesia"}),
            lambda f: f["blocks"][5]["cases"][2].update({"start": "fifth"}),
            lambda f: f["blocks"][5]["cases"][3].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][5]["cases"][4].update({"consumes": True}),
            lambda f: f["blocks"][5]["cases"][3].update({"own_move": "amnesia"}),
            lambda f: f["blocks"][5]["cases"][5].update({"next_move_slot": 1}),
            lambda f: f["blocks"][5]["cases"][6].update({"expected_volatile": "focusenergy"}),
            lambda f: f["blocks"][5]["cases"][7].update({"expected_type": "water"}),
            lambda f: f["blocks"][5]["cases"][8].update({"foe_move": "flamethrower"}),
            lambda f: f["blocks"][5]["cases"][7].update({"foe_move": "flamethrower"}),
            lambda f: f["blocks"][5]["cases"].pop(),
            lambda f: f["blocks"][5]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 7:
        edits.extend([
            lambda f: f["blocks"][6]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][6]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][6]["cases"][2].update({"actor_species": "mew"}),
            lambda f: f["blocks"][6]["cases"][3].update({"expected_type": "dark"}),
            lambda f: f["blocks"][6]["cases"][4].update({"start": "full"}),
            lambda f: f["blocks"][6]["cases"][5].update({"boost_stat": "spd"}),
            lambda f: f["blocks"][6]["cases"][6].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][6]["cases"][7].update({"expected_type": "fire"}),
            lambda f: f["blocks"][6]["cases"][4].update({"own_move": "swords_dance"}),
            lambda f: f["blocks"][6]["cases"].pop(),
            lambda f: f["blocks"][6]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 8:
        edits.extend([
            lambda f: f["blocks"][7]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][7]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][7]["cases"][2].update({"expected_category": "physical"}),
            lambda f: f["blocks"][7]["cases"][2].update({"retaliation_denominator": 4}),
            lambda f: f["blocks"][7]["cases"][3].update({"foe_move": "confusion"}),
            lambda f: f["blocks"][7]["cases"][4].update({"boost_stat": "atk"}),
            lambda f: f["blocks"][7]["cases"][5].update({"start": "fifth"}),
            lambda f: f["blocks"][7]["cases"][6].update({"foe_move": "earth_power"}),
            lambda f: f["blocks"][7]["cases"][6].update({"expected_type": "fire"}),
            lambda f: f["blocks"][7]["cases"][7].update({"consumes": True}),
            lambda f: f["blocks"][7]["cases"].pop(),
            lambda f: f["blocks"][7]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 9:
        edits.extend([
            lambda f: f["blocks"][8]["cases"][0].update({"expected_stage": 1}),
            lambda f: f["blocks"][8]["cases"][0].update({"own_move": "swords_dance"}),
            lambda f: f["blocks"][8]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][8]["cases"][1].update({"start": "fifth"}),
            lambda f: f["blocks"][8]["cases"][2].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][8]["cases"][3].update({"consumes": True}),
            lambda f: f["blocks"][8]["cases"][4].update({"actor_species": "mew"}),
            lambda f: f["blocks"][8]["cases"][4].update({"expected_type": "fairy"}),
            lambda f: f["blocks"][8]["cases"][5].update({"foe_move": "thunder_shock"}),
            lambda f: f["blocks"][8]["cases"][6].update({"foe_initial_hp": 2}),
            lambda f: f["blocks"][8]["cases"][6].update({"nature": "hardy"}),
            lambda f: f["blocks"][8]["cases"][7].update({"confuses": True}),
            lambda f: f["blocks"][8]["cases"][8].update({"start": "fifth"}),
            lambda f: f["blocks"][8]["cases"].pop(),
            lambda f: f["blocks"][8]["ids"].append("sitrus_berry"),
        ])
    if len(fixture["blocks"]) >= 10:
        edits.extend([
            lambda f: f["blocks"][9]["cases"][0].update({"foe_move": "tackle"}),
            lambda f: f["blocks"][9]["cases"][0].update({"actor_species": "mew"}),
            lambda f: f["blocks"][9]["cases"][1].update({"consumes": True}),
            lambda f: f["blocks"][9]["cases"][2].update({"start_ev": 0}),
            lambda f: f["blocks"][9]["cases"][2].update({"ev_removed": 9}),
            lambda f: f["blocks"][9]["cases"][3].update({"friendship_gain": 10}),
            lambda f: f["blocks"][9]["cases"][4].update({"applies": True}),
            lambda f: f["blocks"][9]["cases"][5].update({"stat": "speed"}),
            lambda f: f["blocks"][9]["cases"][6].update({"start_ev": 251}),
            lambda f: f["blocks"][9]["cases"][7].update({"start_friendship": 254}),
            lambda f: f["blocks"][9]["cases"][8].update({"friendship_gain": 10}),
            lambda f: f["blocks"][9]["cases"][9].update({"start_hp": "one"}),
            lambda f: f["blocks"][9]["cases"][9].update({"start_ev": 7}),
            lambda f: f["blocks"][9]["cases"][10].update({"applies": True}),
            lambda f: f["blocks"][9]["cases"].pop(),
            lambda f: f["blocks"][9]["ids"].append("sitrus_berry"),
        ])
    for i, edit in enumerate(edits):
        tampered = copy.deepcopy(fixture)
        edit(tampered)
        rejected = False
        try:
            validate(tampered, queue, progress, Checks())
        except (ContractError, KeyError, TypeError):
            rejected = True
        check.demand(rejected, f"Falso PASS no rechazado, adversarial {i}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()
    checks = Checks()
    fixture, queue, progress = read_json(FIXTURE), read_csv(QUEUE), read_csv(PROGRESS)
    blocks = validate(fixture, queue, progress, checks)
    verify_sources(checks)
    negative_controls(fixture, queue, progress, checks)
    if checks.count == 0:
        raise ContractError("Sin comprobaciones ejecutadas")
    if args.ci:
        print(f"CAMP003_W02_PY PASS blocks={blocks} checks={checks.count}")
    else:
        print(f"Contrato W02 verificado: blocks={blocks}, checks={checks.count}; no ejecuta Godot")


if __name__ == "__main__":
    main()
