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
