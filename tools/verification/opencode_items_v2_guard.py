"""Read-only scope gate for the new OpenCode mission. Does not certify mechanics."""
from pathlib import Path
import argparse,hashlib,json,subprocess,re
from local_phase import LocalPhase,exclusive_lock

ROOT=Path(__file__).resolve().parents[2]
CONTRACT=ROOT/'docs/opencode/ITEM_CLOSURE_V2/CONTRACT.json'
OUT=ROOT/'.godot/opencode_items_v2'

def mask_source(text,windows):
    # Narrow edit windows prevent an allowed adapter path becoming permission
    # to rewrite turn resolution, damage, RPC transactions, RNG or the map owner.
    spans=[]
    for entry in windows:
        start,end=entry['start'],entry['end']
        if text.count(start)!=1 or text.count(end)!=1:raise ValueError('Missing/ambiguous protected code-window marker')
        a=text.index(start);b=text.index(end,a)
        fragment=text[a:b]
        token='func ' if start.startswith('func ') else 'function '
        if len(re.findall('^'+re.escape(token),fragment,re.M))!=1:raise ValueError('Additional top-level declaration inside code window')
        spans.append((a,b))
    spans.sort()
    if any(spans[i][1]>spans[i+1][0] for i in range(len(spans)-1)):raise ValueError('Overlapping code windows')
    for a,b in reversed(spans):text=text[:a]+'<AUTHORIZED_FUNCTION_BODY>\n'+text[b:]
    return text

def digest(text):return hashlib.sha256(text.encode('utf-8')).hexdigest()

def config_and_base():
    value=json.loads(CONTRACT.read_text(encoding='utf-8'))
    assert ROOT.resolve()==Path(value['root']).resolve()
    branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()
    assert branch==value['branch'],'Wrong work branch'
    anchor=subprocess.check_output(['git','log','-1','--format=%H','--',value['anchor_file']],cwd=ROOT,text=True).strip()
    assert len(anchor)==40,'Handoff must be committed before preparing the seal'
    subprocess.run(['git','merge-base','--is-ancestor',anchor,'HEAD'],cwd=ROOT,check=True)
    for rel in value['allowed_files']:
        p=Path(rel);assert not p.is_absolute() and '..' not in p.parts
    return value,anchor

def check_windows(config,base):
    for rel,windows in config['code_windows'].items():
        original=subprocess.check_output(['git','show',base+':'+rel],cwd=ROOT).decode('utf-8')
        current=(ROOT/rel).read_text(encoding='utf-8')
        assert digest(mask_source(original,windows))==digest(mask_source(current,windows)),'Change outside allowed functions: '+rel

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--prepare',action='store_true');p.add_argument('--full',action='store_true')
    p.add_argument('--family',choices=['O100','O110','O120','O190']);p.add_argument('--since');args=p.parse_args()
    config,base=config_and_base();phase=LocalPhase(ROOT,base,OUT,config['allowed_files'])
    with exclusive_lock(ROOT,OUT):
        if args.prepare:
            assert not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(),'Prepare requires clean handoff commit'
            result=phase.prepare()
        else:
            check_windows(config,base);result=phase.verify(args.full)
            assert bool(args.family)==bool(args.since),'--family and --since must be supplied together'
            if args.family:
                subprocess.run(['git','merge-base','--is-ancestor',base,args.since],cwd=ROOT,check=True)
                subprocess.run(['git','merge-base','--is-ancestor',args.since,'HEAD'],cwd=ROOT,check=True)
                changes=set(subprocess.check_output(['git','diff','--name-only',args.since],cwd=ROOT,text=True).splitlines())
                changes.update(subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines())
                assert changes<=set(config['families'][args.family]),'Outside active family: '+str(sorted(changes-set(config['families'][args.family])))
                result['family']=args.family;result['family_base']=args.since
        print(json.dumps(result,ensure_ascii=False))
        print('SCOPE_ONLY: independent effect tests and later Codex review are still required.')
    return 0

if __name__=='__main__':raise SystemExit(main())
