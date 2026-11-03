#!/usr/bin/env python3
"""W02 CAMP004: contratos explícitos de los IDs reservados; Godot verifica ejecución real."""
from __future__ import annotations
import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W02_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W02/CAMP_004_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_004.json"
NATIVE = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
FIELD_EFFECTS = ROOT / "modules/inventory/field_item_effects.gd"
RECOVERY = ROOT / "modules/inventory/imported_recovery_v19.json"
HISTORIC = ROOT / "tests/gameplay/item_field_effects_v4.gd"


def held(scenario, item, foe_move, consumed, **kw):
    result = dict(scenario=scenario, id=item,
                  kind="heal_flavor" if item == "figy_berry" else "lum_held",
                  nature="hardy", start="full", status="", actor_species="mew",
                  foe_species="mew", foe_move=foe_move, consumes=consumed,
                  confuses=False, own_move="reflect")
    result.update(kw)
    return result


def ev(scenario, amount, friendship, accepted, removed, gain):
    return dict(scenario=scenario, id="kelpsy_berry", kind="field_ev_training",
                stat="attack", start_ev=amount, start_friendship=friendship,
                start_hp="full", applies=accepted, ev_removed=removed,
                friendship_gain=gain)


def pp(scenario, current, slot, accepted, gain):
    return dict(scenario=scenario, id="leppa_berry", kind="field_pp",
                pp_start=current, slot=slot, applies=accepted,
                expected_delta=gain)


def lum(scenario, status, confused, accepted):
    return dict(scenario=scenario, id="lum_berry", kind="field_lum",
                status=status, confused=confused, applies=accepted)


EXPECTED_01 = [
    held("figy_disliked_modest_c004", "figy_berry", "endeavor", True,
         nature="modest", foe_species="snorlax", foe_initial_hp=1, confuses=True),
    held("figy_neutral_hardy_c004", "figy_berry", "endeavor", True,
         foe_species="snorlax", foe_initial_hp=1),
    held("figy_high_no_trigger_c004", "figy_berry", "amnesia", False,
         nature="modest", start="near_full"),
    ev("kelpsy_ev20_friend100_c004", 20, 100, True, 10, 5),
    ev("kelpsy_ev0_friend200_c004", 0, 200, True, 0, 2),
    ev("kelpsy_ev0_friend255_noop_c004", 0, 255, False, 0, 0),
    pp("leppa_zero_pp_c004", 0, 0, True, 10),
    pp("leppa_low_pp_c004", 3, 0, True, 10),
    pp("leppa_full_pp_noop_c004", "full", 0, False, 0),
    pp("leppa_missing_slot_c004", 0, -1, False, 0),
    held("lum_poison_held_c004", "lum_berry", "amnesia", True, status="poison"),
    held("lum_healthy_held_c004", "lum_berry", "amnesia", False),
    lum("lum_poison_field_c004", "poison", False, True),
    lum("lum_confusion_field_c004", "", True, True),
    lum("lum_healthy_field_noop_c004", "", False, False),
]
EXPECTED_IDS_01 = ["figy_berry", "kelpsy_berry", "leppa_berry", "lum_berry"]
SOURCES_01 = [
    "tools/item_audit/held_effect_sweep_v3.cjs",
    "modules/inventory/field_item_effects.gd",
    "modules/inventory/imported_recovery_v19.json",
    "tests/gameplay/item_field_effects_v4.gd",
]

EXPECTED_02 = json.loads(r'''[
  {
    "scenario": "qualot_ev20_friend100_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 20,
    "start_friendship": 100,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 10,
    "friendship_gain": 5
  },
  {
    "scenario": "qualot_ev0_friend200_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 0,
    "start_friendship": 200,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 0,
    "friendship_gain": 2
  },
  {
    "scenario": "qualot_ev0_friend255_noop_c004",
    "id": "qualot_berry",
    "kind": "field_ev_training",
    "stat": "defense",
    "start_ev": 0,
    "start_friendship": 255,
    "start_hp": "full",
    "applies": false,
    "ev_removed": 0,
    "friendship_gain": 0
  },
  {
    "scenario": "razz_field_missing_contract_c004",
    "id": "razz_berry",
    "kind": "field_unsupported",
    "status": "",
    "confused": false,
    "applies": false
  },
  {
    "scenario": "razz_held_inert_c004",
    "id": "razz_berry",
    "kind": "inert_held",
    "nature": "hardy",
    "start": "near_full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "mew",
    "foe_move": "amnesia",
    "consumes": false,
    "confuses": false,
    "own_move": "reflect"
  },
  {
    "scenario": "sitrus_held_low_hp_c004",
    "id": "sitrus_berry",
    "kind": "heal_quarter_held",
    "nature": "hardy",
    "start": "full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "snorlax",
    "foe_move": "endeavor",
    "consumes": true,
    "confuses": false,
    "own_move": "reflect",
    "foe_initial_hp": 1
  },
  {
    "scenario": "sitrus_held_high_hp_c004",
    "id": "sitrus_berry",
    "kind": "heal_quarter_held",
    "nature": "hardy",
    "start": "near_full",
    "status": "",
    "actor_species": "mew",
    "foe_species": "mew",
    "foe_move": "amnesia",
    "consumes": false,
    "confuses": false,
    "own_move": "reflect"
  },
  {
    "scenario": "sitrus_field_half_hp_c004",
    "id": "sitrus_berry",
    "kind": "field_heal",
    "start_hp": "half",
    "applies": true,
    "heal_denominator": 4
  },
  {
    "scenario": "sitrus_field_full_hp_noop_c004",
    "id": "sitrus_berry",
    "kind": "field_heal",
    "start_hp": "full",
    "applies": false,
    "heal_denominator": 4
  },
  {
    "scenario": "tamato_ev20_friend100_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 20,
    "start_friendship": 100,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 10,
    "friendship_gain": 5
  },
  {
    "scenario": "tamato_ev0_friend200_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 0,
    "start_friendship": 200,
    "start_hp": "full",
    "applies": true,
    "ev_removed": 0,
    "friendship_gain": 2
  },
  {
    "scenario": "tamato_ev0_friend255_noop_c004",
    "id": "tamato_berry",
    "kind": "field_ev_training",
    "stat": "speed",
    "start_ev": 0,
    "start_friendship": 255,
    "start_hp": "full",
    "applies": false,
    "ev_removed": 0,
    "friendship_gain": 0
  }
]''')
EXPECTED_IDS_02 = ["qualot_berry","razz_berry","sitrus_berry","tamato_berry"]
SOURCES_02 = ["modules/inventory/field_item_effects.gd","modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_service.gd","modules/inventory/item_connections_v1.json"]

EXPECTED_03 = json.loads(r'''[
  {
    "scenario": "antidote_poison_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_badly_poisoned_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "badly_poisoned",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_burn_reject_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "burn",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "antidote_healthy_reject_c004",
    "id": "antidote",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "awakening_sleep_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "sleep",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false,
    "expect_sleep_clock_clear": true
  },
  {
    "scenario": "awakening_poison_reject_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "awakening_healthy_reject_c004",
    "id": "awakening",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_half_hp_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "half",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_near_full_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "missing_7",
    "status": "",
    "confused": false,
    "applies": true,
    "heal_amount": 20,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "berry_juice_full_reject_c004",
    "id": "berry_juice",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_poison_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_freeze_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "freeze",
    "confused": false,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": false
  },
  {
    "scenario": "big_malasada_confusion_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": true
  },
  {
    "scenario": "big_malasada_poison_confusion_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "poison",
    "confused": true,
    "applies": true,
    "heal_amount": 0,
    "cures_status": true,
    "cures_confusion": true
  },
  {
    "scenario": "big_malasada_healthy_reject_c004",
    "id": "big_malasada",
    "kind": "field_medicine",
    "start_hp": "full",
    "status": "",
    "confused": false,
    "applies": false,
    "heal_amount": 0,
    "cures_status": false,
    "cures_confusion": false
  }
]''')
EXPECTED_IDS_03 = ["antidote","awakening","berry_juice","big_malasada"]
SOURCES_03 = ["modules/inventory/imported_recovery_v19.json","modules/inventory/field_item_effects.gd","modules/inventory/field_item_service.gd","tests/gameplay/item_field_effects_v4.gd"]


class ContractError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.count = 0

    def demand(self, assertion, error):
        self.count += 1
        if not assertion:
            raise ContractError(error)


def rows(path):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def verify(fixture, queue, progress, chk):
    chk.demand(type(fixture) is dict, "Fixture debe ser Dictionary")
    chk.demand(set(fixture) == {
        "schema_version", "campaign", "worker", "active_policy", "purpose",
        "format", "level", "seed", "modes", "completed_blocks", "blocks",
        "limitations"}, "Esquema de fixture alterado")
    chk.demand(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004_W02"
               and fixture["worker"] == "W02", "Identidad distinta")
    chk.demand(fixture["active_policy"] == "RANDOMLOCK_ITEMS_BUILD_SCOPE_V2"
               and fixture["format"] == "gen9calvounifiedv1"
               and fixture["seed"] == [23, 19, 29, 43]
               and fixture["level"] == 100, "Motor, política, nivel o semilla alterados")
    chk.demand(fixture["modes"] == ["active", "none", "reserve"], "Propietarios incompletos")
    chk.demand(type(fixture["limitations"]) is list and len(fixture["limitations"]) >= 2,
               "Limitaciones retiradas")
    chk.demand(len(queue) == 10 and all(
        r["trabajadora"] == "W02" and r["bloque"] == f"{i+1:02d}"
        for i, r in enumerate(queue)), "Cola oficial modificada")
    chk.demand(1 <= len(progress) <= 10 and len(progress) == len(fixture["blocks"]),
               "Progreso no corresponde con número de bloques")
    chk.demand(fixture["completed_blocks"] == list(range(1, len(progress)+1)),
               "Bloques discontinuos")
    for i, block in enumerate(fixture["blocks"]):
        allowed = queue[i]
        chk.demand(block["block"] == allowed["bloque"]
                   and block["ids"] == allowed["ids"].split(";")
                   and progress[i]["bloque"] == allowed["bloque"]
                   and progress[i]["ids"] == allowed["ids"], "IDs/orden no autorizados")
        chk.demand(block["family"] == allowed["familia"], "Familia distinta de la cola")
        chk.demand(progress[i]["estado"] in {
            "EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA",
            "CI_PASS_VERIFICADO"}, "Estado de progreso inválido")
        chk.demand(type(block["cases"]) is list and len(block["cases"]) >= 1,
                   "Bloque sin casos reales")
        if i == 0:
            chk.demand(block["ids"] == EXPECTED_IDS_01 and block["family"] == "BERRY",
                       "Cuatro bayas del bloque 01 no coinciden")
            chk.demand(block["source_evidence"] == SOURCES_01, "Fuentes no trazables")
            chk.demand(len(block["cases"]) == len(EXPECTED_01), "No hay 15 escenarios")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_01):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Escenario duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {case["scenario"] for case in EXPECTED_01},
                       "Falta alguno de los escenarios Figy Kelpsy Leppa Lum")
        elif i == 1:
            chk.demand(block["ids"] == EXPECTED_IDS_02 and block["family"] == "BERRY",
                       "IDs bayas 02 distintos de cola")
            chk.demand(block["source_evidence"] == SOURCES_02, "Fuentes bloque 02 alteradas")
            chk.demand(len(block["cases"]) == len(EXPECTED_02), "Faltan escenarios bloque 02")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_02):
                chk.demand(type(actual) is dict and actual == expected,
                           "Escenario bloque 02 alterado: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Escenario bloque 02 duplicado")
                names.add(actual["scenario"])
            chk.demand(names == {case["scenario"] for case in EXPECTED_02},
                       "Escenarios bloque 02 incompletos")
        elif i == 2:
            chk.demand(block["ids"] == EXPECTED_IDS_03 and block["family"] == "MEDICINE",
                       "IDs o familia de medicinas 03 incorrectos")
            chk.demand(block["source_evidence"] == SOURCES_03,
                       "Fuentes del bloque de medicinas cambiadas")
            chk.demand(len(block["cases"]) == len(EXPECTED_03),
                       "No hay 15 escenarios de medicina")
            names = set()
            for actual, expected in zip(block["cases"], EXPECTED_03):
                chk.demand(type(actual) is dict and actual == expected,
                           "Medicina alterada: " + str(expected["scenario"]))
                chk.demand(actual["scenario"] not in names, "Medicina duplicada")
                names.add(actual["scenario"])
            chk.demand(names == {x["scenario"] for x in EXPECTED_03},
                       "Escenarios MEDICINE 03 incompletos")
        else:
            raise ContractError("No hay contrato específico de bloque futuro")
    return len(progress)


def verify_sources(chk):
    native = NATIVE.read_text(encoding="utf-8")
    effects = FIELD_EFFECTS.read_text(encoding="utf-8")
    old = HISTORIC.read_text(encoding="utf-8")
    profile = json.loads(RECOVERY.read_text(encoding="utf-8"))
    for fragment in ("heal_and_disliked_flavor", "heal_without_confusion",
                     "foeMoves:['endeavor']", "add('leppa_berry','empty_pp'",
                     "add('leppa_berry','nonempty_pp'"):
        chk.demand(fragment in native, "Precedente Showdown ausente: " + fragment)
    for fragment in ('"kelpsy_berry": "attack"', "static func _ev_berry(",
                     "Friendship.increase(creature, [10, 5, 2])",
                     "creature.evs[stat] = maxi(0, old_ev - 10)"):
        chk.demand(fragment in effects, "Implementación canónica EV ausente: " + fragment)
    for fragment in ('"kelpsy_berry": "attack"', "berry EV -10 lower bound",
                     "full health follows new maximum"):
        chk.demand(fragment in old, "Regresión EV histórica ausente: " + fragment)
    for item, expected in {
        "leppa_berry": {"pp": 10, "scope": "one"},
        "lum_berry": {"confusion": True, "cure": "all"},
    }.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Perfil recuperación nativo alterado: " + item)
    chk.demand(profile["items"]["sitrus_berry"]["effect"] == {"heal": "quarter"}
               and profile["items"]["sitrus_berry"]["consume"] is True,
               "Sitrus no conserva curación de cuarto de PS")
    chk.demand('"qualot_berry": "defense"' in effects and
               '"tamato_berry": "speed"' in effects,
               "Qualot y Tamato no tienen ruta canónica EV")
    chk.demand('"razz_berry"' not in effects and "razz_berry" not in profile["items"],
               "Razz ya tiene ruta de campo: reevaluar dependencia, no inventar")
    connections = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    chk.demand(all(x in connections["holdable_ids"] for x in EXPECTED_IDS_02),
               "Las 4 bayas deben conservar el contrato equipado permitido")
    expected_medicines = {
        "antidote": {"cure": ["psn", "tox"]},
        "awakening": {"cure": ["slp"]},
        "berry_juice": {"heal": 20},
        "big_malasada": {"confusion": True, "cure": "all"},
    }
    for item, expected in expected_medicines.items():
        chk.demand(profile["items"][item]["effect"] == expected
                   and profile["items"][item]["consume"] is True,
                   "Contrato nativo medicina no coincide: " + item)
    chk.demand("static func apply(" in effects and
               "static func _recovery_spec(" in effects and
               "creature.status_state.clear_persistent()" in effects,
               "Motor de medicina/cura no conectado")
    chk.demand("confusion-only effect" in old and
               '"antidote": "badly_poisoned"' in old and
               '"awakening": "sleep"' in old,
               "Regresiones históricas de estado no disponibles")


def negative_controls(fixture, queue, progress, chk):
    edits = [
        lambda f: f.update({"worker": "W03"}),
        lambda f: f.update({"campaign": "CAMP_003"}),
        lambda f: f.update({"format": "gen8ou"}),
        lambda f: f["blocks"][0]["ids"].append("sitrus_berry"),
        lambda f: f["blocks"][0]["cases"].pop(),
        lambda f: f["blocks"][0]["cases"].append(copy.deepcopy(f["blocks"][0]["cases"][0])),
        lambda f: f["blocks"][0]["source_evidence"].pop(),
    ]
    for j, expected in enumerate(EXPECTED_01):
        key = next(k for k in ("nature", "stat", "slot", "status", "pp_start",
                               "applies", "start_ev", "consumes", "confused",
                               "expected_delta", "friendship_gain") if k in expected)
        value = expected[key]
        if type(value) is bool:
            other = not value
        elif type(value) is int:
            other = value + 1
        elif type(value) is str:
            other = value + "_BAD"
        else:
            raise ContractError("No hay mutación de test definida")
        edits.append(lambda f, j=j, key=key, other=other:
                     f["blocks"][0]["cases"][j].update({key: other}))
    if len(fixture["blocks"]) >= 2:
        edits.extend([
            lambda f: f["blocks"][1]["ids"].append("figy_berry"),
            lambda f: f["blocks"][1]["cases"].pop(),
            lambda f: f["blocks"][1]["cases"][3].update({"applies": True}),
            lambda f: f["blocks"][1]["cases"][5].update({"consumes": False}),
            lambda f: f["blocks"][1]["cases"][7].update({"heal_denominator": 3}),
            lambda f: f["blocks"][1]["cases"][9].update({"stat": "defense"}),
        ])
    if len(fixture["blocks"]) >= 3:
        edits.extend([
            lambda f: f["blocks"][2]["ids"].append("potion"),
            lambda f: f["blocks"][2]["cases"].pop(),
            lambda f: f["blocks"][2]["cases"][0].update({"applies": False}),
            lambda f: f["blocks"][2]["cases"][4].update({"cures_status": False}),
            lambda f: f["blocks"][2]["cases"][8].update({"heal_amount": 7}),
            lambda f: f["blocks"][2]["cases"][12].update({"cures_confusion": False}),
            lambda f: f["blocks"][2]["cases"][14].update({"applies": True}),
        ])
    for i, edit in enumerate(edits):
        altered = copy.deepcopy(fixture)
        edit(altered)
        rejected = False
        try:
            verify(altered, queue, progress, Checks())
        except (ContractError, KeyError, TypeError):
            rejected = True
        chk.demand(rejected, f"Mutación adversarial {i} aceptada sin error")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    queue = rows(QUEUE)
    progress = rows(PROGRESS)
    c = Checks()
    count = verify(fixture, queue, progress, c)
    verify_sources(c)
    negative_controls(fixture, queue, progress, c)
    print(f"CAMP004_W02_PY PASS blocks={count} checks={c.count}"
          if args.ci else f"W02 CAMP004 static check: blocks={count} checks={c.count}; NO equivale a Godot")


if __name__ == "__main__":
    main()
