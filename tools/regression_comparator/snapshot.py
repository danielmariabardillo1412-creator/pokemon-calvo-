"""Read source trees; create independent, non-linked test snapshots on D:."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
SOURCES={'original':Path('D:/Proyectos/Pokemon Calvo'),'organized':ROOT}
DEST=Path('D:/Proyectos/Pokemon Calvo - Comparador General V1')
ROOT_EXCLUDES={'.git','.kilocode','.vscode','POKEMON_DATA_LIBRARY','POKEMON_REFERENCIAS','Project-Uranium-Godot-v4','Project-Uranium-Godot-master'}
CACHE_EXCLUDES={'editor','shader_cache','regression_comparator'}

def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def eligible(src,support):
 for parent,dirs,files in os.walk(src,followlinks=False):
  rel=Path(parent).relative_to(src)
  if rel.parts[:2]==('tools','regression_comparator'):
   dirs[:]=[];continue
  if str(rel)=='.':dirs[:]=[d for d in dirs if d not in ROOT_EXCLUDES]
  for d in dirs:
   child=Path(parent)/d
   if child.is_symlink() or child.is_junction():raise RuntimeError('Linked source directory requires explicit review: '+str(child))
  dirs[:]=[d for d in dirs if d!='__pycache__']
  if rel.parts and rel.parts[0]=='.godot':
   if len(rel.parts)==1:dirs[:]=[d for d in dirs if d not in CACHE_EXCLUDES]
   if len(rel.parts)>1 and rel.parts[1] in CACHE_EXCLUDES:continue
  for name in files:
   p=Path(parent)/name;r=p.relative_to(src)
   if p.is_symlink():raise RuntimeError('Linked source file requires explicit review: '+str(p))
   if r.parts[0]=='.godot' and r.as_posix() not in support:continue
   if name.endswith(('.tmp','.log','.pyc')):continue
   yield p,r

def prepare():
 assert ROOT.resolve()==Path('D:/Proyectos/Pokemon Calvo - Arquitectura Kilo').resolve()
 assert not DEST.exists(),'Snapshot destination already exists; use existing manifest or choose a reviewed new run. Never overwrite it.'
 assert shutil.disk_usage(DEST.parent).free>8*1024**3,'Insufficient free space for isolated copies'
 support={p.relative_to(ROOT).as_posix() for p in (ROOT/'.godot').rglob('*') if p.is_file()}
 DEST.mkdir();(DEST/'reports').mkdir()
 report={'status':'PREPARING','policy':'Full physical working-tree source excluding Git/editor helpers. .godot uses the support-file inventory present in the organized project; historical bulk capture caches absent there are omitted. No links, no execution in sources.','source_roots':{k:str(v) for k,v in SOURCES.items()},'snapshots':{}}
 write(DEST/'manifest.json',report)
 for label,src in SOURCES.items():
  dst=DEST/label;dst.mkdir();rows=[]
  for p,r in eligible(src,support):
   before=p.stat();target=dst/r;target.parent.mkdir(parents=True,exist_ok=True)
   shutil.copy2(p,target)
   digest=sha(target);after=p.stat()
   assert before.st_size==after.st_size and before.st_mtime_ns==after.st_mtime_ns,'Source changed during copy: '+str(p)
   assert digest==sha(p),'Copied bytes do not match source: '+str(p)
   rows.append({'path':r.as_posix(),'sha256':digest,'bytes':after.st_size})
   if len(rows)%4000==0:print('SNAPSHOT',label,len(rows),flush=True)
  project=dst/'project.godot';text=project.read_text(encoding='utf-8')
  run_tag=hashlib.sha256(str(DEST).encode('utf-8')).hexdigest()[:10]
  isolated='Pokemon Calvo Comparator '+run_tag+' '+label
  text,n=re.subn(r'(?m)^config/name="[^"\r\n]*"$',f'config/name="{isolated}"',text);assert n==1
  assert 'config/use_custom_user_dir=true' not in text,'Custom save path must be reviewed'
  project.write_text(text,encoding='utf-8',newline='\n')
  # Userdata isolation is the only mutation of the copied game configuration.
  info={'root':str(dst),'user_data_name':isolated,'files':len(rows),'bytes':sum(r['bytes'] for r in rows),'source_manifest':label+'_source_files.json','isolated_project_sha256':sha(project),'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=src,text=True).strip(),'source_status':subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=src,text=True).splitlines()}
  write(DEST/(label+'_source_files.json'),rows);report['snapshots'][label]=info;write(DEST/'manifest.json',report)
  print('SNAPSHOT_READY',label,len(rows),info['bytes'],flush=True)
 report['status']='READY';write(DEST/'manifest.json',report)
 return report

def verify_sources():
 report=read(DEST/'manifest.json');assert report['status']=='READY'
 totals={}
 for label,src in SOURCES.items():
  rows=read(DEST/report['snapshots'][label]['source_manifest'])
  for row in rows:
   p=src/row['path'];assert p.is_file() and not p.is_symlink() and sha(p)==row['sha256'],'Source changed: '+str(p)
  totals[label]=len(rows)
 return {'status':'PASS','source_files_verified':totals}

if __name__=='__main__':prepare()
