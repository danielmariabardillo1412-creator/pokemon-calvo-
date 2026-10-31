"""Sequential broad regression comparison in isolated projects. Never runs source games."""
from pathlib import Path
from collections import Counter
import argparse,hashlib,json,os,re,shutil,subprocess,time,sys
import snapshot,inventory,fixtures
from run_lock import exclusive_lock
ROOT=snapshot.ROOT;DEST=snapshot.DEST
GODOT='C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
ANSI=re.compile(r'\x1b\[[0-9;]*m')

def classify_log(text,code,timed_out=False):
 text=ANSI.sub('',text)
 errors=[l for l in text.splitlines() if 'SCRIPT ERROR' in l or re.match(r'^ERROR:',l) or re.match(r'^FAIL\s',l) or re.search(r'(?<![0-9])[1-9][0-9]* FAIL',l)]
 for line in text.splitlines():
  # In "checks=4630 failures=0", 4630 counts checks, not failures. Do not
  # reinterpret a value assigned to another key as a prefix failure count.
  numeric_failure=re.search(r'(?<![=\w])[1-9][0-9]* failures?\b',line) or re.search(r'\bfailures?[=:]\s*[1-9][0-9]*\b',line)
  if numeric_failure or not line.startswith('PASS ') and re.search(r'\bFAIL\b',line) and not re.search(r'\b0 FAIL\b',line):
   if line not in errors:errors.append(line)
 counts=[int(x) for x in re.findall(r'checks[=:]\s*(\d+)',text)]
 counts += [int(x) for x in re.findall(r'(\d+) PASS / \d+ FAIL',text)]
 counts += [int(x) for x in re.findall(r'\bPASS\s+(\d+)(?:\s|$)',text)]
 counts += [int(x) for x in re.findall(r'"checks"\s*:\s*(\d+)',text)]
 counts += [int(x) for x in re.findall(r'"passed"\s*:\s*(\d+)',text)]
 counts += [int(x) for x in re.findall(r'\bpassed[=:]\s*(\d+)',text)]
 counts += [int(x) for x in re.findall(r'(\d+)\s+checks\b',text)]
 count=max(counts,default=0)
 status='TIMEOUT' if timed_out else 'FAIL' if code!=0 or errors else 'PASS' if count>0 else 'INCONCLUSIVE_NO_ASSERTION_COUNT'
 return {'status':status,'checks_reported':count,'errors':errors[:30],'last_line':text.strip().splitlines()[-1] if text.strip() else ''}

def expected_negative_diagnostic(text,case):
 text=ANSI.sub('',text)
 prefix='ERROR: Parse JSON failed. Error at line 0: Expected key'
 matching=[l for l in text.splitlines() if l.startswith(prefix)]
 if case.get('script')=='tests/test_runner.gd' and len(matching)==1 and 'PASS  sg_corrupt_rejected' in text:
  return '\n'.join(l for l in text.splitlines() if l!=matching[0]),matching
 return text,[]

def execute(label,case):
 project=DEST/label
 assert project.resolve().parent==DEST.resolve() and project.resolve() not in [p.resolve() for p in snapshot.SOURCES.values()]
 manifest=snapshot.read(DEST/'manifest.json')['snapshots'][label]
 settings=(project/'project.godot').read_text(encoding='utf-8')
 assert f'config/name="{manifest["user_data_name"]}"' in settings
 command=[GODOT,'--path',str(project),'--resolution','1280x720']
 if case['mode']=='headless':command.append('--headless')
 if case['id']=='editor_import':command+=['--editor','--import','--quit']
 else:command+=['--script',case['script']]
 if case.get('args'):command+=['--']+case['args']
 if case['mode']=='node':command=['D:/Herramientas/NodeJS/node.exe',case['script']]
 if case['mode']=='native_sweep':command=[sys.executable,str(ROOT/'tools/regression_comparator/native_sweep.py'),str(project)]
 out=DEST/'reports'/label;out.mkdir(exist_ok=True)
 log=out/(case['id']+'.log')
 prepared_dirs=fixtures.prepare_output_dirs(project,case.get('script',''))
 startup=None
 if os.name=='nt':
  startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
 start=time.monotonic();timed_out=False
 with log.open('w',encoding='utf-8') as f:
  process=subprocess.Popen(command,cwd=project,stdout=f,stderr=subprocess.STDOUT,startupinfo=startup)
  snapshot.write(DEST/'live_process.json',{'pid':process.pid,'label':label,'case':case['id'],'command':command,'started_at':time.time()})
  deadline=start+case.get('timeout_seconds',600);fatal_abort=False
  while True:
   try:
    code=process.wait(timeout=min(2,max(0.01,deadline-time.monotonic())));break
   except subprocess.TimeoutExpired:
    fatal_abort=b'SCRIPT ERROR' in log.read_bytes()[-65536:]
    timed_out=time.monotonic()>=deadline
    if not fatal_abort and not timed_out:continue
    if os.name=='nt':subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    else:process.kill()
    code=process.wait();break
 text=log.read_text(encoding='utf-8',errors='replace')
 classified_text,expected=expected_negative_diagnostic(text,case)
 result=classify_log(classified_text,code,timed_out)
 result['expected_negative_test_diagnostics']=expected
 result['terminated_after_script_error']=fatal_abort
 result['prepared_output_dirs']=prepared_dirs
 if case['id']=='editor_import' and result['status']=='INCONCLUSIVE_NO_ASSERTION_COUNT':result['status']='PASS' # Import gate has no assertion count.
 result.update({'exit_code':code,'seconds':round(time.monotonic()-start,2),'command':command,'log':str(log),'log_sha256':snapshot.sha(log),'test_source_sha256':snapshot.sha((ROOT if case['mode']=='native_sweep' else project)/case['script']) if case.get('script') else None})
 return result

def compare(case,results):
 if case['labels']==['original']:return 'ORIGINAL_ONLY_COVERAGE_GAP'
 if len(case['labels'])!=2:return 'CURRENT_ONLY_PASS' if all(r['status']=='PASS' for r in results.values()) else 'CURRENT_ONLY_FAILURE'
 if not case['same_test_bytes']:return 'TEST_BYTES_DIFFER_REVIEW_REQUIRED'
 a,b=results['original'],results['organized']
 if a['status']=='PASS' and b['status']=='PASS':return 'COMMON_GATES_PASS' if a['checks_reported']==b['checks_reported'] else 'PASS_BOTH_COUNTS_DIFFER_REVIEW_REQUIRED'
 if a['status']=='PASS':return 'POSSIBLE_REGRESSION'
 if b['status']=='PASS':return 'BASELINE_FAILURE_OR_FIX_REVIEW_REQUIRED'
 return 'SHARED_FAILURE' if a['status']=='FAIL' and b['status']=='FAIL' else 'INCONCLUSIVE_OR_SHARED_TIMEOUT'

def trace_compare():
 a=snapshot.read(DEST/'original/.godot/comparator_trace/trace.json')
 b=snapshot.read(DEST/'organized/.godot/comparator_trace/trace.json')
 left={row['label']:row['state'] for row in a['trace']};right={row['label']:row['state'] for row in b['trace']}
 different=[label for label in sorted(set(left)|set(right)) if left.get(label)!=right.get(label)]
 return {'status':'MATCH' if not different and a['status']==b['status']=='PASS' else 'DIFFERENCES_OR_FAILED_ORACLE','states':len(left),'different_states':different,'checks':{'original':a['checks'],'organized':b['checks']},'trace_sha256':{label:snapshot.sha(DEST/label/'.godot/comparator_trace/trace.json') for label in ['original','organized']}}

def report_markdown(report,cases):
 counts=Counter(row['comparison'] for row in report['cases'].values())
 lines=['# Comparador general V1','',f'Status: {report["status"]}', '', 'Dos copias fisicas aisladas, con nombres de userdata distintos. Se compara el trabajo local real de la version antigua, no solo su antiguo commit Git.','',f'Casos terminados: {len(report["cases"])}/{len(cases["cases"])+1} (incluida sonda de estados)','', '| Clasificacion | Casos |','| --- | ---: |']
 lines += [f'| {k} | {v} |' for k,v in sorted(counts.items())]
 lines += ['','## Hallazgos','']
 findings=[(key,row) for key,row in report['cases'].items() if row['comparison'] not in ['COMMON_GATES_PASS','CURRENT_ONLY_PASS']]
 lines += [f'- {key}: {row["comparison"]}. Logs en reports/original y reports/organized.' for key,row in findings] or ['Sin discrepancias en los casos ejecutados.']
 lines += ['','## Limites','']+[f'- {s}' for s in cases['coverage_limits']]
 lines += ['',f'Collectors/probes excluidos explicitamente: {len(cases["excluded"])}; detalles en cases.json.','Una coincidencia no prueba que ambas versiones esten libres de errores compartidos. Los asserts independientes se mantienen y sus fallos no se convierten en verdes por coincidir.','']
 (DEST/'reports/REPORT.md').write_text('\n'.join(lines),encoding='utf-8',newline='\n')

def refresh_additive():
 old_path=DEST/'cases.json';old=snapshot.read(old_path);old_sha=snapshot.sha(old_path)
 out=DEST/'reports/results.json';report=snapshot.read(out)
 assert report['case_manifest_sha256']==old_sha
 # Preserve exact prior manifest and pilot report before review or extension.
 shutil.copyfile(old_path,DEST/('cases_'+old_sha[:12]+'.json'))
 if not (DEST/'reports/results_pilot_received.json').exists():shutil.copyfile(out,DEST/'reports/results_pilot_received.json')
 new=inventory.inventory();indexed={c['id']:c for c in new['cases']}
 try:
  assert all(indexed.get(c['id'])==c for c in old['cases']),'An existing case changed: additive refresh rejected'
 except Exception:
  snapshot.write(old_path,old);raise
 new_sha=snapshot.sha(old_path)
 report.setdefault('plan_revisions',[]).append({'previous_sha256':old_sha,'new_sha256':new_sha,'added_cases':sorted(set(indexed)-{c['id'] for c in old['cases']}),'reason':'Add native transaction contracts and fresh allowed-move native/Godot sweep; existing cases unchanged.'})
 report['case_manifest_sha256']=new_sha
 for key,row in report['cases'].items():
  case=indexed.get(key)
  if not case:continue
  previous=row['comparison']
  for label,result in row['results'].items():
   text=Path(result['log']).read_text(encoding='utf-8',errors='replace')
   cleaned,expected=expected_negative_diagnostic(text,case)
   updated=classify_log(cleaned,result['exit_code'],result['status']=='TIMEOUT')
   if expected:
    result['prior_status_before_expected_diagnostic_review']=result['status']
    result.update(updated);result['expected_negative_test_diagnostics']=expected
  row['comparison']=compare(case,row['results'])
  if previous!=row['comparison']:row['diagnostic_review']={'previous_comparison':previous,'reason':'Exactly one expected corrupt-JSON diagnostic plus successful sg_corrupt_rejected assertion; raw logs and received pilot report retained.'}
 snapshot.write(out,report)

def parse_args():
 parser=argparse.ArgumentParser()
 parser.add_argument('--prepare',action='store_true');parser.add_argument('--pilot',action='store_true')
 parser.add_argument('--resume',action='store_true');parser.add_argument('--refresh-additive',action='store_true')
 parser.add_argument('--output',help='New isolated run folder under D:/Proyectos, named Pokemon Calvo - Comparador General ...; never overwrites a prior run.')
 return parser.parse_args()


def configure_destination(value):
 global DEST
 if value is None:return
 destination=Path(value).resolve()
 assert destination.parent==Path('D:/Proyectos').resolve() and destination.name.startswith('Pokemon Calvo - Comparador General '),'Output must be a dedicated comparison run folder on D:'
 assert all(destination!=p.resolve() and not destination.is_relative_to(p.resolve()) and not p.resolve().is_relative_to(destination) for p in snapshot.SOURCES.values()),'Do not use either source project as output'
 DEST=destination;snapshot.DEST=destination;inventory.DEST=destination;fixtures.DEST=destination


def main(args=None):
 args=parse_args() if args is None else args
 if args.prepare:snapshot.prepare();inventory.inventory()
 fixtures.prepare_cached_inputs()
 fixtures.prepare_missing_json_references()
 if args.refresh_additive:refresh_additive()
 manifest=snapshot.read(DEST/'manifest.json');assert manifest['status']=='READY'
 cases=snapshot.read(DEST/'cases.json')
 probe=ROOT/'tools/regression_comparator/state_trace.gd'
 for label in snapshot.SOURCES:
  target=DEST/label/'tests/comparator_state_trace.gd'
  shutil.copyfile(probe,target)
 out=DEST/'reports/results.json'
 assert args.resume or not out.exists(),'Existing result history: use --resume, or --prepare --output with a new run folder'
 report=snapshot.read(out) if args.resume and out.exists() else {'schema':1,'status':'RUNNING','snapshot_manifest_sha256':snapshot.sha(DEST/'manifest.json'),'case_manifest_sha256':snapshot.sha(DEST/'cases.json'),'cases':{},'imports':{},'scope':'Broad paired regression gates plus identical state trace and current-only capability gates; no universal correctness claim.'}
 assert report['snapshot_manifest_sha256']==snapshot.sha(DEST/'manifest.json') and report['case_manifest_sha256']==snapshot.sha(DEST/'cases.json')
 report['status']='RUNNING';report['phase']='PILOT' if args.pilot else 'FULL';snapshot.write(out,report)
 for label in snapshot.SOURCES:
  if label not in report['imports']:
   result=execute(label,{'id':'editor_import','mode':'headless','timeout_seconds':600})
   report['imports'][label]=result;snapshot.write(out,report);print('IMPORT',label,result['status'],flush=True)
   if result['status']!='PASS':report['status']='IMPORT_FAILURE';snapshot.write(out,report);return 1
 trace_case={'id':'state_trace','script':'tests/comparator_state_trace.gd','labels':['original','organized'],'same_test_bytes':True,'mode':'headless','args':[],'timeout_seconds':240}
 selected=[trace_case]+cases['cases']
 if args.pilot:
  pilot_names={'tests/test_runner.gd','tests/gameplay/inventory_test_runner.gd','tests/gameplay/field_native_test_runner.gd','tests/gameplay/savegame_v2_test_runner.gd'}
  selected=[trace_case]+[c for c in cases['cases'] if c['script'] in pilot_names]
 for case in selected:
  if case['id'] in report['cases']:continue
  results=report.setdefault('partial_cases',{}).get(case['id'],{})
  for label in case['labels']:
   if label in results:continue
   print('CASE',case['id'],label,flush=True)
   results[label]=execute(label,case)
   report['partial_cases'][case['id']]=results;snapshot.write(out,report)
   print('RESULT',label,results[label]['status'],'checks='+str(results[label]['checks_reported']),flush=True)
  row={'comparison':compare(case,results),'results':results}
  report['cases'][case['id']]=row;report['partial_cases'].pop(case['id'],None);snapshot.write(out,report);report_markdown(report,cases)
 if 'state_trace' in report['cases']:
  try:report['state_trace']=trace_compare()
  except Exception as e:report['state_trace']={'status':'UNAVAILABLE','error':str(e)}
 if args.pilot:report['status']='PILOT_FINISHED_REVIEW_REQUIRED'
 else:
  try:
   report['source_integrity']=snapshot.verify_sources()
   report['supplemental_input_integrity']=fixtures.verify_cached_inputs()
   report['cached_reference_source_integrity']=fixtures.verify_reference_sources()
  except Exception as error:
   report['status']='SOURCE_OR_INPUT_INTEGRITY_FAILURE';report['integrity_error']=str(error)
   snapshot.write(out,report);report_markdown(report,cases);return 1
  green=all(row['comparison'] in ['COMMON_GATES_PASS','CURRENT_ONLY_PASS'] for row in report['cases'].values())
  report['status']='COVERED_SCENARIOS_PASS' if green and report['state_trace']['status']=='MATCH' else 'FINDINGS_REVIEW_REQUIRED'
 snapshot.write(out,report);report_markdown(report,cases)
 print('COMPARATOR',report['status'],flush=True)
 return 0 if args.pilot or report['status']=='COVERED_SCENARIOS_PASS' else 1
if __name__=='__main__':
 arguments=parse_args();configure_destination(arguments.output)
 with exclusive_lock(ROOT,DEST):sys.exit(main(arguments))
