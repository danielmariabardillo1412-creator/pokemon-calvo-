"""Prepare only existing, versioned-by-hash local test inputs; never game datasets."""
import json,shutil,time,re,os
from snapshot import ROOT,DEST,SOURCES,sha,read,write


def prepare_cached_inputs():
 source=SOURCES['original']/'.godot/native_doubles_checks'
 before=read(source/'before.json')
 for label in SOURCES:
  assert sha(DEST/label/'data/normalized/pokemon_api.json')==before['data/normalized/pokemon_api.json'],'Reference fixtures do not match the snapshot data'
 rows=[]
 for name in ['cases.json','prototypes.json','native.json']:
  src=source/name;read(src);digest=sha(src)
  for label in SOURCES:
   target=DEST/label/'.godot/native_doubles_checks'/name
   if target.exists():assert sha(target)==digest,'Existing test input differs; refusing overwrite: '+str(target)
   else:target.parent.mkdir(exist_ok=True);shutil.copy2(src,target)
  rows.append({'source':str(src),'relative_test_input':'.godot/native_doubles_checks/'+name,'sha256':digest,'bytes':src.stat().st_size,'labels':list(SOURCES)})
 out=DEST/'reports/SUPPLEMENTAL_TEST_INPUTS.json'
 if out.exists():
  report=read(out)
  assert report['files']==rows,'Do not replace previously declared references silently'
  report.setdefault('verified_preparations',[]).append({'time':time.time(),'action':'Verified existing fixtures unchanged'})
 else:
  report={'status':'PREPARED_BEFORE_TESTS','purpose':'Existing local cached double-test references in isolated copies only. No canonical dataset or source project edits.','normalized_sha256':before['data/normalized/pokemon_api.json'],'files':rows}
 write(out,report)
 return report


def verify_cached_inputs():
 report=read(DEST/'reports/SUPPLEMENTAL_TEST_INPUTS.json')
 for row in report['files']:
  assert sha(__import__('pathlib').Path(row['source']))==row['sha256'],'Source reference changed'
  for label in row['labels']:assert sha(DEST/label/row['relative_test_input'])==row['sha256'],'Input reference changed in test snapshot'
 return {'status':'PASS','reference_files':len(report['files'])}


def prepare_output_dirs(project,script,seen=None):
 seen=set() if seen is None else seen
 path=project/script
 if path in seen or not path.is_file() or path.suffix!='.gd':return []
 seen.add(path);text=path.read_text(encoding='utf-8-sig')
 patterns=[r'const\s+\w*(?:OUT|OUTPUT|DEST)\w*\s*(?::=|=)\s*"res://(\.godot/[^"\n]+)"',r'make_dir_recursive_absolute\(\s*"res://(\.godot/[^"\n]+)"']
 prepared=[]
 for pattern in patterns:
  for relative in re.findall(pattern,text):
   if pattern==patterns[0] and not relative.endswith('/') and __import__('pathlib').Path(relative).suffix:continue
   target=(project/relative).resolve()
   assert target.is_relative_to(project.resolve()/'.godot'),'Output directory leaves snapshot cache'
   target.mkdir(parents=True,exist_ok=True);prepared.append(relative)
 parent=re.search(r'^extends\s+"res://([^"\n]+)"',text,re.M)
 if parent:prepared+=prepare_output_dirs(project,parent[1],seen)
 return sorted(set(prepared))


def prepare_missing_json_references():
 source=SOURCES['original']/'.godot'
 out=DEST/'reports/CACHED_REFERENCE_INPUTS.json'
 report=read(out) if out.exists() else {'status':'MISSING_CACHE_REFERENCES_SUPPLIED_WITHOUT_OVERWRITE','purpose':'Existing local cached JSON references only; source projects, canonical datasets and bulk PNG captures remain untouched. Cached reports are not fresh test evidence.','files':[]}
 known={r['source']:r for r in report['files']}
 added=0
 for src in source.rglob('*.json'):
  relative=src.relative_to(source)
  if relative.parts[0] in ['editor','shader_cache','regression_comparator'] or 'node_modules' in relative.parts:continue
  missing=[label for label in SOURCES if not (DEST/label/'.godot'/relative).exists()]
  if not missing:continue
  digest=sha(src);copied=[]
  for label in missing:
   target=DEST/label/'.godot'/relative
   assert target.resolve().is_relative_to((DEST/label/'.godot').resolve())
   target.parent.mkdir(parents=True,exist_ok=True)
   temporary=target.with_name(target.name+'.comparator_input.tmp')
   assert not temporary.exists();shutil.copy2(src,temporary);assert sha(temporary)==digest
   try:
    # Windows rename refuses an existing target, preserving concurrent outputs.
    assert os.name=='nt';os.rename(temporary,target);copied.append(label)
   except FileExistsError:temporary.unlink()
  if copied:
   row={'source':str(src),'relative_test_input':'.godot/'+relative.as_posix(),'sha256':digest,'bytes':src.stat().st_size,'labels':copied}
   if str(src) in known:
    assert known[str(src)]['sha256']==digest,'Reference changed since prior preparation'
    known[str(src)]['labels']=sorted(set(known[str(src)]['labels'])|set(copied))
   else:report['files'].append(row);known[str(src)]=row
   added+=1
 report.setdefault('preparations',[]).append({'time':time.time(),'newly_supplied_files':added})
 write(out,report);return {'newly_supplied_files':added,'declared_reference_files':len(report['files'])}


def verify_reference_sources():
 report=read(DEST/'reports/CACHED_REFERENCE_INPUTS.json')
 for row in report['files']:
  assert sha(__import__('pathlib').Path(row['source']))==row['sha256'],'Cached reference source changed'
 # Snapshot report paths may be overwritten by new genuine test output. The
 # original reference provenance is retained; only fresh logs/assertions certify.
 return {'status':'PASS','source_reference_files':len(report['files'])}
