"""Shared local verification: bounded changes, immutable baseline and real processes."""
from pathlib import Path
import hashlib, json, os, subprocess, sys, time

EXPECTED_ROOT = Path('D:/Proyectos/Pokemon Calvo - Arquitectura Kilo')
sys.path.insert(0, str(EXPECTED_ROOT/'tools/regression_comparator'))
from runner import classify_log, expected_negative_diagnostic
from run_lock import exclusive_lock
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'

def read(path): return json.loads(path.read_text(encoding='utf-8'))
def write(path, value): path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''): h.update(block)
    return h.hexdigest()

class LocalPhase:
    def __init__(self, root, base, output, allowed):
        self.root, self.base, self.output, self.allowed = Path(root).resolve(), base, Path(output).resolve(), set(allowed)
        assert self.root == EXPECTED_ROOT.resolve()
        assert self.output.is_relative_to(self.root/'.godot')
        self.output.mkdir(parents=True, exist_ok=True)
        self.manifest = self.output/'scope_base.json'

    def git(self, *args): return subprocess.check_output(['git', *args], cwd=self.root).decode('utf-8')

    def delta(self):
        assert not self.git('remote').strip()
        assert 'config/name="Pokemon Calvo - Arquitectura Kilo"' in (self.root/'project.godot').read_text(encoding='utf-8')
        changed = set(self.git('diff','--name-only',self.base).splitlines()) | set(self.git('ls-files','--others','--exclude-standard').splitlines())
        assert changed <= self.allowed, sorted(changed-self.allowed)
        return sorted(changed)

    def prepare(self):
        self.delta()
        assert not self.manifest.exists(), 'Existing baseline is immutable; never reseal'
        assert self.git('rev-parse','HEAD') == self.git('rev-parse',self.base)
        files, absent, seen = [], [], set()
        def add(p):
            rel = p.relative_to(self.root).as_posix()
            if rel in seen or rel in self.allowed: return
            assert p.resolve().is_relative_to(self.root) and not p.is_symlink(), rel
            seen.add(rel); stat = p.stat()
            files.append({'path':rel,'bytes':stat.st_size,'mtime_ns':stat.st_mtime_ns,'sha256':sha(p)})
        for row in self.git('ls-files','-v','-z').split('\0'):
            if not row: continue
            rel = row[2:]
            if rel in self.allowed: continue
            p = self.root/rel
            if not p.is_file():
                assert row[0].upper() == 'S', rel+': unexpected missing file'
                absent.append(rel)
            else: add(p)
        excluded = {'.git','.godot','__pycache__','POKEMON_DATA_LIBRARY','POKEMON_REFERENCIAS','Project-Uranium-Godot-v4','Project-Uranium-Godot-master'}
        roots = [self.root, self.root/'.godot/live_battle_catalog',self.root/'.godot/move_batch_catalog',self.root/'.godot/battle_reference/runtime']
        for base in roots:
            if not base.is_dir(): continue
            for parent, dirs, names in os.walk(base, followlinks=False):
                assert Path(parent).resolve().is_relative_to(base.resolve()), 'Linked directory leaves protected root'
                dirs[:] = [d for d in dirs if d not in excluded]
                for name in names:
                    if not name.endswith(('.pyc','.log','.tmp')): add(Path(parent)/name)
        write(self.manifest, {'base':self.git('rev-parse',self.base).strip(),'files':files,'absent_skip_worktree':absent})
        return {'status':'PREPARED','protected_files':len(files),'absent_skip_worktree':len(absent)}

    def verify(self, full=False):
        delta = self.delta(); frozen = read(self.manifest)
        assert frozen['base'] == self.git('rev-parse',self.base).strip()
        for row in frozen['files']:
            p = self.root/row['path']; assert p.is_file() and not p.is_symlink(), row['path']
            stat = p.stat()
            if full or stat.st_size != row['bytes'] or stat.st_mtime_ns != row['mtime_ns']:
                assert sha(p) == row['sha256'], row['path']
        for rel in frozen['absent_skip_worktree']: assert not (self.root/rel).exists(), rel+': materialized outside scope'
        return {'status':'PASS','base':frozen['base'],'protected_files':len(frozen['files']),
                'preserved_absent_skip_worktree':len(frozen['absent_skip_worktree']),
                'mode':'FULL_CONTENT_HASHES' if full else 'HASH_IF_METADATA_CHANGED','allowed_changes':delta}

    def run_godot(self, name, script, directory, gpu=False, args=(), timeout=360):
        directory = Path(directory); directory.mkdir(parents=True, exist_ok=True)
        log = directory/(name+'.log'); assert not log.exists(), 'Never overwrite execution evidence'
        command = [GODOT,'--path',str(self.root)]
        if not gpu: command.append('--headless')
        else: command += ['--resolution','1280x720']
        command += ['--editor','--import','--quit'] if script == 'IMPORT' else ['--script',script]
        if args: command += ['--',*args]
        startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW; startup.wShowWindow = 0
        start = time.monotonic(); timed_out = False; aborted = False
        with log.open('w',encoding='utf-8') as output:
            process = subprocess.Popen(command,cwd=self.root,stdout=output,stderr=subprocess.STDOUT,startupinfo=startup)
            while True:
                try: code = process.wait(timeout=2); break
                except subprocess.TimeoutExpired:
                    aborted = b'SCRIPT ERROR' in log.read_bytes()[-65536:]
                    timed_out = time.monotonic()-start >= timeout
                    if aborted or timed_out:
                        subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                        code = process.wait(); break
        text, expected = expected_negative_diagnostic(log.read_text(encoding='utf-8',errors='replace'),{'script':script})
        result = classify_log(text,code,timed_out)
        if script == 'IMPORT' and result['status'] == 'INCONCLUSIVE_NO_ASSERTION_COUNT': result['status'] = 'PASS'
        result.update({'group':name,'command':command,'exit_code':code,'seconds':round(time.monotonic()-start,2),
                       'terminated_after_script_error':aborted,'expected_negative_diagnostics':expected,'log':str(log),'log_sha256':sha(log)})
        print(name,result['status'],'checks='+str(result['checks_reported']),flush=True)
        return result
