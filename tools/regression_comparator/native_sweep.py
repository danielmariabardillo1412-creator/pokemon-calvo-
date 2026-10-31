"""Fresh native/Godot move coverage gates, reusing pinned local fixtures only."""
from pathlib import Path
import json,subprocess,sys,os,time

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rows(p):return [json.loads(l) for l in p.read_text(encoding='utf-8-sig').splitlines() if l.strip()]
def main():
 project=Path(sys.argv[1]).resolve()
 assert project.parent.parent==Path('D:/Proyectos').resolve() and project.parent.name.startswith('Pokemon Calvo - Comparador General ') and project.name in ['original','organized']
 manifest=read(project.parent/'manifest.json');assert Path(manifest['snapshots'][project.name]['root']).resolve()==project
 started=time.time()
 startup=None
 if os.name=='nt':startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
 subprocess.run([sys.executable,str(project/'tools/showdown_engine_probe/run_unified_sweep.py'),'--sweep-only'],cwd=project,check=True,timeout=2400,startupinfo=startup)
 subprocess.run(['C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe','--headless','--path',str(project),'--script','tests/gameplay/unified_profile_test_runner.gd'],cwd=project,check=True,timeout=600,startupinfo=startup)
 out=project/'.godot/unified_profile_checks';checks=0
 def check(ok,reason):
  nonlocal checks
  checks+=1
  if not ok:raise AssertionError(reason)
 for name in ['general/native.json','general/godot.jsonl','contexts/native.json','contexts/godot.jsonl','z/native.json','doubles/native.json','special_projection.json']:
  check((out/name).stat().st_mtime>=started-2,'Stale/missing freshly generated evidence: '+name)
 policy=read(project/'config/randomlock_content_v1.json');data=read(project/'data/normalized/pokemon_api.json')
 excluded={id for g in policy['move_exclusions'] for id in g['ids']} & set(data['moves']);excluded.add('extreme_evoboost')
 allowed=set(data['moves'])-excluded
 native=read(out/'general/native.json')
 check({r['id'] for r in native['inventory']}==set(data['moves']),'Canonical inventory mismatch')
 for r in native['results']:check(r['status']=='NATIVE_EXECUTED','Native execution '+str(r))
 check(len(native['oracle'])==15,'Missing independent oracle cases')
 for r in native['oracle']:check(r['status']=='PASS','Oracle '+str(r))
 general=rows(out/'general/godot.jsonl');contexts=rows(out/'contexts/godot.jsonl')
 check(len(general)==len(native['results']),'Projection rows missing')
 check(len(contexts)==72,'Missing special context rows')
 for r in general+contexts:check(not r['issues'] and r['accepted_steps']==r['steps'],'Projection failure '+str(r.get('case_id')))
 z=read(out/'z/native.json')['results'];doubles=read(out/'doubles/native.json')['results']
 check(len(z)==200 and len(doubles)==44,'Z/doubles fixture scope mismatch')
 for r in z:check(r['status']=='NATIVE_Z_VERIFIED' and r['format']=='gen9calvounifiedv1','Z '+str(r))
 for r in doubles:check(r['status']=='PASS','Doubles '+str(r))
 special=read(out/'special_projection.json');check(len(special)==244,'Missing special projection')
 for r in special:check(r['ok'] and not r['unknown'],'Special projection '+str(r))
 positive={r['id'] for r in general+contexts if r['successful_actor_actions']>0}
 positive|={r['id'] for r in z+doubles}
 check(positive==allowed,'Uncovered/extra move IDs: '+str(sorted(allowed^positive)))
 check(len(data['moves'])==919 and len(allowed)==900,'Catalog/policy scope changed; review before certifying')
 summary={'status':'PASS','checks':checks,'canonical_moves':919,'allowed_moves_with_positive_scenario':900,'excluded_moves':sorted(excluded),'general_rows':len(general),'context_rows':len(contexts),'z_rows':len(z),'doubles_rows':len(doubles),'limitation':'Positive scenarios + fixed oracles, not exhaustive interactions or artistic approval.'}
 (out/'comparator_sweep.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('NATIVE_GENERAL_SWEEP PASS checks='+str(checks)+' moves=900',flush=True)
if __name__=='__main__':main()
