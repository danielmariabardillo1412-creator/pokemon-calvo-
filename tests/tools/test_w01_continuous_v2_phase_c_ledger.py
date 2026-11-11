#!/usr/bin/env python3
"""W01 CONTINUOUS_V2 Phase C ledger integrity, not runtime certification."""
import csv,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
A=["leftovers","life_orb","choice_band","choice_specs","choice_scarf","shell_bell","eviolite","safety_goggles","black_sludge","sitrus_berry"]
B=["ability_shield","absorb_bulb","adrenaline_orb","big_root","expert_belt","amulet_coin","pure_incense","luck_incense","cleanse_tag","draco_plate","dread_plate","earth_plate","fist_plate","flame_plate","icicle_plate","insect_plate","iron_plate","meadow_plate","mind_plate","pixie_plate","sky_plate","splash_plate","spooky_plate","stone_plate","toxic_plate","zap_plate"]
EXTERNAL={"amulet_coin","pure_incense","luck_incense","cleanse_tag"}
SHA=re.compile(r"^[0-9a-f]{40}$")
RUN=re.compile(r"^[0-9]{8,}$")
def read(path):
 with (ROOT/path).open(encoding="utf-8-sig",newline="") as f:return list(csv.DictReader(f))
def verify():
 a=read("docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V4_PROGRESS.csv")
 b=read("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
 scope={r["id"]:r for r in read("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
 inv={r["id"]:r for r in read("docs/current/ITEM_INVENTORY.csv")}
 held=set(json.loads((ROOT/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"])
 assert len(a)==10 and [r["id"] for r in a]==A
 assert len(b)==26 and [r["id"] for r in b]==B
 assert len(set(A+B))==36
 for i,r in enumerate(a,1):
  assert r["fila"]==f"{i:02d}" and r["estado"]=="CERTIFICADO",r
  assert SHA.fullmatch(r["sha_pruebas"]) and RUN.fullmatch(r["ci_run"]),r
  assert r["objetos_nuevos"]=="0" and r["qa_funcional"]=="si",r
 counts={"CERTIFICADO":0,"EN_CI_AUTOMATICA":0,"DEPENDENCIA_FUERA_W01":0}
 for i,r in enumerate(b,1):
  iid=r["id"]
  assert r["bloque"]==("01" if i<=10 else "02" if i<=20 else "03"),r
  assert r["orden"]==f"{i:02d}" and iid in held,r
  assert r["objetos_nuevos"]=="0",r
  assert r["estado"] in counts,r
  counts[r["estado"]]+=1
  if iid in EXTERNAL:
   assert r["estado"]=="DEPENDENCIA_FUERA_W01",r
   assert r["qa_funcional"]=="no" and not r["sha_pruebas"] and not r["ci_run"],r
   assert inv[iid]["native_entry"]=="False",r
   assert scope.get(iid,{}).get("estado_contenido")!="SELECCIONADO",r
  else:
   assert scope[iid]["estado_contenido"]=="SELECCIONADO",r
   assert inv[iid]["native_entry"]=="True",r
   assert SHA.fullmatch(r["sha_pruebas"]) and RUN.fullmatch(r["ci_run"]),r
   assert r["qa_funcional"]==("si" if r["estado"]=="CERTIFICADO" else "no"),r
 assert counts["DEPENDENCIA_FUERA_W01"]==4
 assert counts["CERTIFICADO"]+counts["EN_CI_AUTOMATICA"]==22
 assert counts["CERTIFICADO"]>=6
 for r in b[10:]:
  iid=r["id"];prefix="b02" if int(r["orden"])<=20 else "b03"
  node=(ROOT/f"tests/tools/repro_w01_continuous_{prefix}_{iid}_native.cjs").read_text(encoding="utf-8")
  gd=(ROOT/f"tests/gameplay/parallel_items_w01_continuous_{prefix}_{iid}.gd").read_text(encoding="utf-8")
  assert f"id={iid}" in node and "restore" in node and "assert(" in node,iid
  for marker in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip("):
   assert marker in gd,(iid,marker)
 print("W01_PHASE_C_LEDGER PASS A=10 B_cert="+str(counts["CERTIFICADO"])+
       " B_pilots_pending="+str(counts["EN_CI_AUTOMATICA"])+
       " external=4 candidate_total=36 implemented_new=0")
 if counts["CERTIFICADO"]==22:
  print("W01_PHASE_C_LEDGER_READY total_certified=32 external=4")
 else:
  print("W01_PHASE_C_LEDGER_PRECHECK cumulative_gate_required=1")
if __name__=="__main__":verify()
