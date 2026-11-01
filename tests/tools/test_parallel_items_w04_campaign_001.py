#!/usr/bin/env python3
"""Contrato local y lanzador Godot de W04 CAMP_001 (iteración 01).

Modo normal: evidencia ESTATICA, no pretende simular EvolutionSystem.
--godot [BINARIO]: ejecuta el SceneTree real de Godot 4.7 y exige PASS por ID.
El mismo runner se extenderá únicamente al activarse los microbloques 02/03.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNNER = "res://tests/gameplay/parallel_items_w04_campaign_001.gd"
MARKER = "PARALLEL_ITEMS_W04_CAMPAIGN_001 "
CASOS_01 = (
    ("fire_stone", "eevee", "water_stone"),
    ("fire_stone", "growlithe", "water_stone"),
    ("water_stone", "eevee", "thunder_stone"),
    ("water_stone", "shellder", "thunder_stone"),
    ("thunder_stone", "eevee", "fire_stone"),
    ("thunder_stone", "pikachu", "fire_stone"),
)


def exigir(condicion: bool, mensaje: str) -> None:
    if not condicion:
        raise AssertionError(mensaje)


def contenido(ruta: str) -> str:
    return (ROOT / ruta).read_text(encoding="utf-8-sig")


def verificar_contrato() -> int:
    cadena = json.loads(contenido("data/api/v2/evolution-chain/67/index.json"))["chain"]
    seleccion = list(csv.DictReader(contenido(
        "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv").splitlines()))
    historico = json.loads(contenido("docs/current/ITEM_CONNECTIONS_V1.json"))["rows"]
    script = contenido(RUNNER.removeprefix("res://"))
    checks = 0
    exigir(cadena["species"]["name"] == "eevee", "la cadena 67 dejó de ser Eevee")
    checks += 1
    for objeto in ("fire_stone", "water_stone", "thunder_stone"):
        fila = [r for r in seleccion if r["id"] == objeto]
        exigir(len(fila) == 1 and fila[0]["estado_contenido"] == "SELECCIONADO",
               f"{objeto}: fuera de la selección o duplicado")
        checks += 1
        registros = [r for r in historico if r["id"] == objeto]
        exigir(len(registros) == 1 and registros[0]["supported_evolution_routes_tested"] > 0,
               f"{objeto}: falta evidencia histórica (NO sustituir por prueba de hoy)")
        checks += 1
        rutas = [
            (rama["species"]["name"], detalle)
            for rama in cadena["evolves_to"]
            for detalle in rama["evolution_details"]
            if detalle["trigger"]["name"] == "use-item"
            and detalle.get("item") is not None
            and detalle["item"]["name"] == objeto.replace("_", "-")
            and detalle.get("is_default") is True
        ]
        exigir(len(rutas) == 1, f"{objeto}: Eevee no tiene exactamente una ruta original")
        checks += 1
        destino, detalle = rutas[0]
        exigir(destino and detalle.get("base_form", {}).get("name") == "eevee"
               and detalle["held_item"] is None and detalle["min_level"] is None,
               f"{objeto}: se alteraron las condiciones canónicas")
        checks += 1
    for obj, origen, alternativa in CASOS_01:
        firma = f'{{"objeto": "{obj}", "origen": "{origen}", "alternativo": "{alternativa}"}}'
        exigir(firma in script, f"falta caso parametrizado {obj}/{origen}")
        checks += 1
    for caso in (
        "opcion_derivada_de_regla_valida", "rechazo_sin_stock",
        "no_propietario", "destino_inventado", "piedra_equivocada",
        "campo_bloqueado", "especie_incorrecta_sin_gasto",
        "consumo_unico", "identidad_y_equipo", "datos_persistentes",
        "no_doble_uso",
    ):
        exigir(caso in script, f"falta aserción: {caso}")
        checks += 1
    print(f"PARALLEL_ITEMS_W04_CAMP_001_STATIC PASS iteration=1 "
          f"checks={checks} cases=6 scope=DATOS_SIN_RUNTIME")
    return checks


def ejecutar(binario: str, timeout: int) -> dict:
    cmd = [binario, "--headless", "--path", str(ROOT), "--script", RUNNER]
    proceso = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                             errors="replace", timeout=timeout, check=False)
    salida = proceso.stdout + "\n" + proceso.stderr
    print(salida.rstrip(), flush=True)
    exigir(proceso.returncode == 0, f"Godot salió con {proceso.returncode}")
    exigir(not re.search(r"SCRIPT ERROR|Parse Error|Failed to load script", salida, re.I),
           "Godot informa error de carga/parseo")
    lineas = [line[len(MARKER):] for line in salida.splitlines()
              if line.startswith(MARKER)]
    exigir(len(lineas) == 1, "falta resultado único de Godot")
    resultado = json.loads(lineas[0])
    exigir(resultado.get("status") == "PASS"
           and resultado.get("iteration") == 1 and resultado.get("checks", 0) >= 100
           and resultado.get("cases") == len(CASOS_01)
           and resultado.get("errors") == []
           and resultado.get("scope") == "W04_CAMP_001_STONES_01",
           "Godot no superó las aserciones de la iteración 01")
    filas = resultado.get("results", [])
    exigir(isinstance(filas, list) and len(filas) == len(CASOS_01),
           "falta resultado por especie e ID")
    esperados = {(obj, origen) for obj, origen, _ in CASOS_01}
    actuales = {(row["item_id"], row["source"]) for row in filas}
    exigir(actuales == esperados and all(
        row.get("status") == "ASSERTED" and row.get("target_from_catalog") for row in filas
    ), "algún ID carece de ruta positiva validada")
    print(f"PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=1 "
          f"checks={resultado['checks']} cases=6")
    return resultado


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", nargs="?", const="", default=None)
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()
    try:
        verificar_contrato()
        if args.godot is not None:
            binario = args.godot or os.getenv("GODOT_BIN") or shutil.which("godot")
            exigir(bool(binario), "SIN_EJECUTAR: Godot no disponible; indique --godot BINARIO")
            ejecutar(str(binario), args.timeout)
        return 0
    except (AssertionError, KeyError, OSError, ValueError, subprocess.TimeoutExpired) as e:
        print(f"PARALLEL_ITEMS_W04_CAMP_001 FAIL {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
