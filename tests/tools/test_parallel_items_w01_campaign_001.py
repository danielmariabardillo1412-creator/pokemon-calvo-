"""Contrato y evidencias W01/CAMP_001. No implementa efectos de combate.

--contracts comprueba fixture; --self-test prueba que el validador rechaza
manipulaciones del contrato. Sin informe nativo no existe PASS funcional.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_001.json"
REPORT = ROOT / ".godot/parallel_items/w01_campaign_001/report.json"
VARIANTS = ("active", "none", "reserve")
# Casos y parámetros cerrados por IA6 para el microbloque 01.
CASES = {
    "sludge_poison_heal": ("black_sludge", "poison_heal", "gengar", "mew", "reflect", "amnesia", "half", (19, 23)),
    "sludge_poison_full": ("black_sludge", "poison_full", "gengar", "mew", "reflect", "amnesia", "full", (23,)),
    "sludge_nonpoison_damage": ("black_sludge", "nonpoison_damage", "mew", "mew", "reflect", "amnesia", "half", (19, 23)),
    "bell_attack_heal": ("shell_bell", "damage_heal", "mew", "mew", "tackle", "amnesia", "half", (19, 23)),
    "bell_status_control": ("shell_bell", "no_hit", "mew", "mew", "reflect", "amnesia", "half", (23,)),
    "bell_immune_control": ("shell_bell", "immune_no_heal", "mew", "gengar", "tackle", "amnesia", "half", (23,)),
    "root_absorb_boost": ("big_root", "drain_boost", "mew", "mew", "absorb", "amnesia", "half", (19, 23)),
    "root_plain_attack_control": ("big_root", "no_drain", "mew", "mew", "tackle", "amnesia", "half", (23,)),
}
STAGE_01 = frozenset(CASES)
CASES.update({
    "eviolite_pre_physical": ("eviolite", "eviolite_resist", "pidgeotto", "mew", "growl", "tackle", "full", (19, 23)),
    "eviolite_pre_special": ("eviolite", "eviolite_resist", "pidgeotto", "mew", "growl", "psychic", "full", (19, 23)),
    "eviolite_final_physical": ("eviolite", "eviolite_final", "pidgeot", "mew", "growl", "tackle", "full", (23,)),
    "eviolite_final_special": ("eviolite", "eviolite_final", "pidgeot", "mew", "growl", "psychic", "full", (23,)),
    "belt_supereffective": ("expert_belt", "super_effective", "mew", "arcanine", "water_gun", "reflect", "full", (19, 23)),
    "belt_neutral": ("expert_belt", "neutral_control", "mew", "mew", "water_gun", "reflect", "full", (23,)),
    "goggles_spore": ("safety_goggles", "powder_immunity", "mew", "breloom", "reflect", "spore", "full", (19,)),
    "goggles_sandstorm": ("safety_goggles", "weather_immunity", "mew", "mew", "reflect", "sandstorm", "full", (23,)),
    "goggles_normal": ("safety_goggles", "irrelevant_control", "mew", "mew", "reflect", "amnesia", "full", (23,)),
})
STAGE_02 = frozenset(CASES) - STAGE_01
FIELDS = {"stage", "id", "item_id", "op", "actor_species", "level",
          "foe_species", "own_move", "foe_move", "hp", "seeds"}
SAMPLE_FIELDS = {"valid", "restored", "evidence", "sha256", "hp_before",
                 "hp_after", "foe_hp_before", "foe_hp_after", "own_has_item",
                 "reserve_has_item", "own_consumed", "reserve_consumed",
                 "physical_units", "owner_unchanged", "own_status_before", "own_status_after"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_json(path: Path) -> dict:
    content = json.loads(path.read_text(encoding="utf-8-sig"))
    require(type(content) is dict, f"Se esperaba objeto JSON: {path}")
    return content


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_fixture(fixture: dict) -> set[tuple[str, int]]:
    require(set(fixture) == {"schema_version", "family", "format", "variants", "cases"},
            "Cabecera contiene campos inesperados")
    require(fixture["schema_version"] == 1 and fixture["family"] == "held_campaign_w01"
            and fixture["format"] == "gen9calvounifiedv1", "Familia/formato inválidos")
    require(fixture["variants"] == list(VARIANTS), "Se requieren activo, ninguno y reserva")
    require(type(fixture["cases"]) is list, "Casos no son lista")
    found: set[str] = set()
    executions: set[tuple[str, int]] = set()
    for row in fixture["cases"]:
        require(type(row) is dict and set(row) == FIELDS, "Campos de escenario desconocidos")
        case_id = row["id"]
        require(type(case_id) is str and case_id in CASES and case_id not in found,
                f"Caso ajeno/duplicado: {case_id}")
        found.add(case_id)
        require(row["stage"] == ("01" if case_id in STAGE_01 else "02") and type(row["level"]) is int and row["level"] == 100,
                f"Etapa/nivel no autorizados: {case_id}")
        expected = CASES[case_id]
        actual = (row["item_id"], row["op"], row["actor_species"], row["foe_species"],
                  row["own_move"], row["foe_move"], row["hp"], tuple(row["seeds"])
                  if type(row["seeds"]) is list else ())
        require(actual == expected, f"Escenario o semilla alterados: {case_id}")
        require(all(type(seed) is int and 0 <= seed <= 65535 for seed in row["seeds"]),
                f"Semilla inválida: {case_id}")
        for seed in row["seeds"]:
            require((case_id, seed) not in executions, f"Ejecución duplicada: {case_id}/{seed}")
            executions.add((case_id, seed))
    require(found == set(CASES), "Escenarios obligatorios ausentes")
    require(len(executions) == 24, "La matriz autorizada contiene 24 ejecuciones")
    return executions


def check_effect(op: str, obs: dict) -> None:
    require(type(obs) is dict and set(obs) == set(VARIANTS), "Variante ausente o inventada")
    for mode in VARIANTS:
        s = obs[mode]
        require(type(s) is dict and set(s) == SAMPLE_FIELDS,
                f"Campos de observación incompletos: {mode}")
        for flag in ("valid", "restored", "own_has_item", "reserve_has_item",
                     "own_consumed", "reserve_consumed", "owner_unchanged"):
            require(type(s[flag]) is bool, f"Bandera no booleana: {flag}")
        for field in ("own_status_before", "own_status_after"):
            require(type(s[field]) is str, f"Estado no es string: {field}")
        for metric in ("hp_before", "hp_after", "foe_hp_before", "foe_hp_after", "physical_units"):
            require(type(s[metric]) is int, f"Métrica no entera: {metric}")
        require(s["valid"] and s["restored"] and s["owner_unchanged"],
                f"Sesión, restauración o propietario falló: {mode}")
        require(s["own_has_item"] is (mode == "active") and s["reserve_has_item"] is (mode == "reserve"),
                f"Equipo en propietario incorrecto: {mode}")
        require(not s["own_consumed"] and not s["reserve_consumed"]
                and s["physical_units"] == 2, f"Consumo/duplicación: {mode}")
        require(s["hp_before"] > 0 and s["foe_hp_before"] > 0
                and s["hp_after"] >= 0 and s["foe_hp_after"] >= 0,
                f"PS imposibles: {mode}")
    a, n, r = (obs[k] for k in VARIANTS)
    delta = lambda x: x["hp_after"] - x["hp_before"]
    loss = lambda x: x["foe_hp_before"] - x["foe_hp_after"]
    require(a["hp_before"] == n["hp_before"] == r["hp_before"],
            "Controles comienzan con distintos PS")
    require(delta(r) == delta(n), "Objeto en reserva modificó al activo")
    require(loss(n) == loss(r), "Daño enemigo en control y reserva distinto")
    if op != "super_effective":
        require(loss(a) == loss(n), "El objeto alteró daño enemigo sin corresponder")
    require(a["own_status_before"] == n["own_status_before"] == r["own_status_before"],
            "Estado inicial de control diferente")
    if op == "poison_heal":
        passed = delta(a) > 0 and delta(n) == 0
    elif op == "poison_full":
        passed = delta(a) == delta(n) == 0
    elif op == "nonpoison_damage":
        passed = delta(a) < 0 and delta(n) == 0
    elif op == "damage_heal":
        passed = loss(n) > 0 and delta(a) > delta(n) == 0
    elif op in ("no_hit", "immune_no_heal"):
        passed = loss(n) == 0 and delta(a) == delta(n) == 0
    elif op == "drain_boost":
        passed = loss(n) > 0 and delta(a) > delta(n) > 0
    elif op == "no_drain":
        passed = delta(a) == delta(n) == 0
    elif op == "eviolite_resist":
        passed = delta(n) < 0 and delta(a) > delta(n) and delta(a) <= 0
    elif op == "eviolite_final":
        passed = delta(n) < 0 and delta(a) == delta(n)
    elif op == "super_effective":
        passed = loss(n) > 0 and loss(a) > loss(n) and loss(a) < a["foe_hp_before"] and delta(a) == delta(n)
    elif op == "neutral_control":
        passed = loss(n) > 0 and loss(a) == loss(n)
    elif op == "powder_immunity":
        passed = a["own_status_after"] == "" and n["own_status_after"] == r["own_status_after"] == "sleep" and delta(a) == delta(n) == 0
    elif op == "weather_immunity":
        passed = delta(n) < 0 and delta(a) == 0
    elif op == "irrelevant_control":
        passed = delta(a) == delta(n) == 0 and a["own_status_after"] == n["own_status_after"] == ""
    else:
        raise ValueError(f"Operación no autorizada: {op}")
    require(passed, f"Contrato causal incumplido: {op}")


def validate_report(report: dict, fixture: dict, report_path: Path) -> int:
    require(set(report) == {"schema_version", "family", "execution_mode", "descriptor_sha256",
                            "status", "checks", "errors", "rows", "limits"},
            "Campos de informe no esperados")
    require(report["schema_version"] == 1 and report["family"] == "held_campaign_w01"
            and report["execution_mode"] == "godot_4_7_native", "Identidad del runner incorrecta")
    require(report["descriptor_sha256"] == digest(FIXTURE), "Fixture no coincide con ejecución")
    require(report["status"] == "PASS" and report["errors"] == [],
            "Godot no reportó PASS limpio")
    wanted = validate_fixture(fixture)
    require(type(report["checks"]) is int and report["checks"] >= len(wanted) * 15,
            "Insuficientes aserciones reales")
    require(type(report["rows"]) is list and len(report["rows"]) == len(wanted),
            "Número de ejecuciones no coincide")
    require(type(report["limits"]) is list and len(report["limits"]) >= 2,
            "Limitaciones de ejecución ausentes")
    seen: set[tuple[str, int]] = set()
    for row in report["rows"]:
        require(type(row) is dict
                and set(row) == {"id", "stage", "item_id", "op", "seed", "checks", "status", "observed"},
                "Fila incompatible")
        case_id, seed = row["id"], row["seed"]
        require((case_id, seed) in wanted and (case_id, seed) not in seen, "Fila extra o duplicada")
        seen.add((case_id, seed))
        item_id, op = CASES[case_id][:2]
        require(row["stage"] == ("01" if case_id in STAGE_01 else "02") and row["item_id"] == item_id and row["op"] == op,
                "Fila incompatible con la orden")
        require(row["status"] == "PASS" and type(row["checks"]) is int and row["checks"] >= 15,
                "Escenario no verificado")
        check_effect(op, row["observed"])
        for mode in VARIANTS:
            s = row["observed"][mode]
            name = f"{case_id}_{seed}_{mode}.json"
            require(s["evidence"] == name, "Ruta de evidencia declarada inesperada")
            path = report_path.parent / name
            require(path.is_file(), f"Falta evidencia: {name}")
            require(type(s["sha256"]) is str and len(s["sha256"]) == 64
                    and digest(path) == s["sha256"], f"Hash de evidencia inválido: {name}")
            evidence = read_json(path)
            expected_metadata = {"id": case_id, "seed": seed, "mode": mode}
            require(all(evidence.get(k) == v for k, v in expected_metadata.items()),
                    "Evidencia de otra sesión")
            require(type(evidence.get("before")) is dict and type(evidence.get("after")) is dict
                    and bool(evidence["before"]) and bool(evidence["after"]), "Faltan snapshots nativos")
            for field in SAMPLE_FIELDS - {"valid", "restored", "evidence", "sha256"}:
                require(evidence.get(field) == s[field], f"Reporte no coincide con evidencia: {field}")
    require(seen == wanted, "Faltan pares caso/semilla")
    return len(seen)


def self_test() -> None:
    fixture = read_json(FIXTURE)
    validate_fixture(fixture)
    for action in (
        lambda f: f["cases"].pop(),
        lambda f: f["cases"][0].update({"item_id": "wrong"}),
        lambda f: f["cases"][0].update({"seeds": [19, 19]}),
        lambda f: f["cases"][0].update({"actor_species": "mew"}),
        lambda f: f["cases"][-1].update({"stage": "01"}),
        lambda f: f["cases"][-2].update({"foe_move": "spore"}),
    ):
        tampered = copy.deepcopy(fixture)
        action(tampered)
        try:
            validate_fixture(tampered)
        except ValueError:
            continue
        raise AssertionError("Contrato aceptó manipulación deliberada")
    print("W01_CAMPAIGN_CONTRACT_NEGATIVES_PASS count=6")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contracts", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--report", type=Path, default=REPORT)
    args = parser.parse_args()
    try:
        fixture = read_json(FIXTURE)
        executions = validate_fixture(fixture)
        if args.self_test:
            self_test()
        if args.contracts or args.self_test:
            print(f"W01_CAMPAIGN_CONTRACT_PASS cases={len(CASES)} runs={len(executions)} variants={len(executions)*3}")
            return 0
        require(args.report.is_file(), f"SIN_EJECUTAR: falta informe Godot {args.report}")
        count = validate_report(read_json(args.report), fixture, args.report)
        print(f"W01_CAMPAIGN_NATIVE_EVIDENCE_PASS runs={count} variants={count*3}")
        return 0
    except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"W01_CAMPAIGN_FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
