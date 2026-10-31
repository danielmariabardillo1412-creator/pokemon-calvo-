"""PP boosts: staged field effects, native persistence and post-cleanup scope."""
from pathlib import Path
import argparse, csv, hashlib, json, os, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[2]
BASE = '941dd297'
OUT = ROOT / '.godot/item_field_v8'
GODOT = 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
sys.path.insert(0, str(ROOT / 'tools/regression_comparator'))
from runner import classify_log
from run_lock import exclusive_lock

ALLOWED = {
    'AGENTS.md', 'docs/current/START_HERE.md', 'docs/current/PROJECT_STATE.md',
    'docs/current/NEXT_STEPS.md', 'docs/current/DEVELOPMENT_CURRENT.md',
    'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json', 'docs/current/ITEM_FIELD_V8.md',
    'docs/current/ITEM_FIELD_V8.json', 'docs/current/ITEM_FIELD_V8.csv.txt',
    'docs/current/ITEM_PENDING_V8.json', 'tests/fixtures/item_field_v8/reference_contract.json',
    'modules/inventory/field_pp_boost_effects.gd', 'modules/inventory/field_pp_boost_effects.gd.uid',
    'modules/inventory/field_friendship_effects.gd', 'modules/inventory/field_friendship_effects.gd.uid',
    'modules/inventory/field_training_effects.gd', 'modules/inventory/field_item_effects.gd',
    'modules/inventory/field_item_service.gd', 'scenes/visual/field_item_bag.gd',
    'tests/gameplay/item_field_pp_v8.gd', 'tests/gameplay/item_field_pp_v8.gd.uid',
    'tools/item_audit/run_field_pp_v8.py',
}

def read(path): return json.loads(path.read_text(encoding='utf-8'))
def write(path, value): path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''): h.update(block)
    return h.hexdigest()
def git(*args): return subprocess.check_output(['git', *args], cwd=ROOT).decode('utf-8')

def delta():
    assert ROOT == Path('D:/Proyectos/Pokemon Calvo - Arquitectura Kilo')
    assert not git('remote').strip()
    assert 'config/name="Pokemon Calvo - Arquitectura Kilo"' in (ROOT/'project.godot').read_text(encoding='utf-8')
    changed = set(git('diff', '--name-only', BASE).splitlines())
    new = set(git('ls-files', '--others', '--exclude-standard').splitlines())
    assert changed | new <= ALLOWED, sorted((changed | new)-ALLOWED)
    return sorted(changed | new)

def prepare():
    delta()
    assert git('rev-parse', 'HEAD').strip() == git('rev-parse', BASE).strip(), 'Prepare only from the declared checkpoint'
    path = OUT/'scope_base.json'
    assert not path.exists(), 'Existing baseline is immutable; do not reseal'
    files, absent = [], []
    for row in git('ls-files', '-v', '-z').split('\0'):
        if not row: continue
        flag, rel = row[0], row[2:]
        if rel in ALLOWED: continue
        p = ROOT/rel
        if not p.is_file():
            assert flag.upper() == 'S', rel+': unexpected missing tracked file'
            absent.append(rel); continue
        assert not p.is_symlink(), rel
        stat = p.stat()
        files.append({'path':rel, 'bytes':stat.st_size, 'mtime_ns':stat.st_mtime_ns, 'sha256':sha(p)})
    write(path, {'base':git('rev-parse', BASE).strip(), 'files':files, 'absent_skip_worktree':absent})
    print('V8_SCOPE_PREPARED', len(files), 'protected present;', len(absent), 'absent skip-worktree', flush=True)

def scope(full=False):
    changed = delta(); frozen = read(OUT/'scope_base.json')
    assert frozen['base'] == git('rev-parse', BASE).strip()
    for row in frozen['files']:
        p = ROOT/row['path']; assert p.is_file() and not p.is_symlink(), row['path']
        stat = p.stat()
        if full or stat.st_size != row['bytes'] or stat.st_mtime_ns != row['mtime_ns']:
            assert sha(p) == row['sha256'], row['path']
    for rel in frozen['absent_skip_worktree']: assert not (ROOT/rel).exists(), rel+': unexpectedly materialized'
    local = read(OUT/'local_assets_base.json')
    for row in local['files']:
        p = ROOT/row['path']; assert p.is_file() and not p.is_symlink(), row['path']
        stat = p.stat()
        if full or stat.st_size != row['bytes'] or stat.st_mtime_ns != row['mtime_ns']:
            assert sha(p) == row['sha256'], row['path']
    contract = read(ROOT/'tests/fixtures/item_field_v8/reference_contract.json')
    for rel, digest in contract['sources_sha256'].items(): assert sha(Path(contract['source_root'])/rel) == digest, rel
    return {'status':'PASS', 'base':frozen['base'], 'protected_present':len(frozen['files']),
            'preserved_absent_skip_worktree':len(frozen['absent_skip_worktree']),
            'protected_local_ignored_files':len(local['files']),
            'mode':'FULL_CONTENT_HASHES' if full else 'HASH_IF_METADATA_CHANGED', 'changed_allowed_files':changed}

def prepare_local():
    # Add the physical ignored resources/runtime to this phase's explicit scope.
    # The already-created tracked baseline is left byte-for-byte intact.
    delta(); frozen = read(OUT/'scope_base.json'); path = OUT/'local_assets_base.json'
    assert not path.exists(), 'Existing local-resource manifest is immutable'
    known = {r['path'] for r in frozen['files']} | ALLOWED
    rows = []
    excluded = {'.git','.godot','__pycache__','POKEMON_DATA_LIBRARY','POKEMON_REFERENCIAS','Project-Uranium-Godot-v4','Project-Uranium-Godot-master'}
    roots = [ROOT, ROOT/'.godot/live_battle_catalog', ROOT/'.godot/move_batch_catalog', ROOT/'.godot/battle_reference/runtime']
    for base in roots:
        if not base.is_dir(): continue
        for parent, dirs, files in os.walk(base, followlinks=False):
            dirs[:] = [d for d in dirs if d not in excluded]
            for name in files:
                p = Path(parent)/name; rel = p.relative_to(ROOT).as_posix()
                if rel in known or name.endswith(('.log','.pyc','.tmp')): continue
                assert not p.is_symlink() and not p.is_junction(), rel
                stat = p.stat(); rows.append({'path':rel,'bytes':stat.st_size,'mtime_ns':stat.st_mtime_ns,'sha256':sha(p)}); known.add(rel)
    write(path, {'base':frozen['base'],'files':rows,'scope':'Physical local resources plus fixed compiled battle/move catalogs and native runtime; no resealing of tracked baseline'})
    print('V8_LOCAL_SCOPE_PREPARED', len(rows), 'protected local resources', flush=True)

def execute(name, script, directory, gpu=False):
    command = [GODOT, '--path', str(ROOT)]
    if not gpu: command.append('--headless')
    else: command += ['--resolution', '1280x720']
    if script == 'IMPORT': command += ['--editor', '--import', '--quit']
    else: command += ['--script', 'tests/gameplay/'+script]
    if gpu: command += ['--', '--capture']
    log = directory/(name+'.log'); start = time.monotonic()
    startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW; startup.wShowWindow = 0
    with log.open('w', encoding='utf-8') as output:
        proc = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, timeout=360, startupinfo=startup)
    result = classify_log(log.read_text(encoding='utf-8', errors='replace'), proc.returncode)
    if script == 'IMPORT' and result['status'] == 'INCONCLUSIVE_NO_ASSERTION_COUNT': result['status'] = 'PASS'
    result.update({'group':name, 'exit_code':proc.returncode, 'command':command, 'seconds':round(time.monotonic()-start, 2), 'log':str(log), 'log_sha256':sha(log)})
    print(name, result['status'], 'checks='+str(result['checks_reported']), flush=True)
    return result

def publish(report):
    head, gpu = read(OUT/'godot.json'), read(OUT/'gpu.json')
    for r in [head, gpu]:
        assert r['status'] == 'PASS' and not r['errors'] and len(r['rows']) == 336
        assert r['catalog_move_ids'] and r['catalog_cases'] > 15000
    assert gpu['gpu'] and not head['gpu'] and head['catalog_move_ids'] == gpu['catalog_move_ids']
    last = read(ROOT/'docs/current/ITEM_FIELD_V7.json')
    for rel, digest in last['protected_data_policy_art'].items(): assert sha(ROOT/rel) == digest, rel
    with (ROOT/'docs/current/ITEM_FIELD_V7.csv.txt').open(encoding='utf-8', newline='') as f: rows = list(csv.DictReader(f))
    for row in rows:
        if row['id'] in ['pp_up', 'pp_max']: row['field_use_status'] = 'PP_BOOST_SELECTED_MOVE_CAP_BASE_FRIENDSHIP_SAVE_NATIVE_VERIFIED_ORIGIN_BONUS_PENDING'
    with (ROOT/'docs/current/ITEM_FIELD_V8.csv.txt').open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator='\n'); w.writeheader(); w.writerows(rows)
    pending = read(ROOT/'docs/current/ITEM_PENDING_V7.json')
    for row in pending['other_system_groups']:
        if row['group'] == 'training_items': row['reason'] = 'EV berries/vitamins/wings and PP Up/Max connected. XP, IV, nature and ability routes remain pending; origin friendship bonuses require capture metadata.'
    origin = pending['field_friendship_origin_context_pending']; origin['items'] = sorted(set(origin['items']) | {'pp_up', 'pp_max'})
    origin['reason'] = 'Capture ball/map absent from CreatureInstance. Base gains and live Soothe Bell verified; origin bonuses not inferred. Includes 18 EV/berry IDs and 2 PP boosters.'
    write(ROOT/'docs/current/ITEM_PENDING_V8.json', pending)
    result = {'phase':'ITEM_FIELD_V8', 'date':'2026-10-29', 'status':'PP_BOOST_BASE_ROUTE_PASS_ORIGIN_CONTEXT_PENDING',
              'all_item_effects_certified':False, 'new_ids':['pp_up','pp_max'], 'total_connected_field_effect_ids':61,
              'field_recovery_ids_verified':41, 'field_training_ids_verified':20,
              'headless_checks':head['checks'], 'gpu_checks':gpu['checks'], 'positive_owned_contexts':len(head['rows']),
              'catalog_move_ids':head['catalog_move_ids'], 'catalog_cases':head['catalog_cases'],
              'reference':read(ROOT/'tests/fixtures/item_field_v8/reference_contract.json'), 'verification':report,
              'sources_sha256':{p:sha(ROOT/p) for p in sorted(ALLOWED) if (ROOT/p).is_file() and p.startswith(('modules/','scenes/','tests/','tools/'))},
              'protected_data_policy_art':last['protected_data_policy_art'], 'previous_report':'docs/current/ITEM_FIELD_V7.json',
              'full_item_matrix':'docs/current/ITEM_FIELD_V8.csv.txt', 'limitations':pending['field_friendship_origin_context_pending']}
    write(ROOT/'docs/current/ITEM_FIELD_V8.json', result)
    status = read(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json')
    status.update({k:result[k] for k in ['total_connected_field_effect_ids','field_recovery_ids_verified','field_training_ids_verified','headless_checks','gpu_checks']})
    status.update({'latest_report':'docs/current/ITEM_FIELD_V8.json','notes':'docs/current/ITEM_FIELD_V8.md','full_item_matrix':'docs/current/ITEM_FIELD_V8.csv.txt','latest_verification':'ITEM_FIELD_V8','latest_phase_checks_headless':head['checks'],'latest_phase_checks_gpu':gpu['checks']})
    status['next'][0] = 'PP boosts complete for the declared profile; XP/IV/nature/ability routes remain separate pending families'
    write(ROOT/'docs/current/ITEM_SYSTEM_CURRENT_STATUS.json', status)

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--prepare', action='store_true'); parser.add_argument('--prepare-local', action='store_true'); parser.add_argument('--piece', action='store_true'); args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    with exclusive_lock(ROOT, OUT):
        if args.prepare: prepare(); return 0
        if args.prepare_local: prepare_local(); return 0
        directory = OUT/'runs'/str(time.time_ns()); directory.mkdir(parents=True)
        report = {'status':'RUNNING','scope':'ITEM_FIELD_V8','base':BASE,'groups':[],'evidence_root':str(directory)}
        try:
            report['integrity_before'] = scope()
            tests = [('pp_v8','item_field_pp_v8.gd')]
            if not args.piece: tests = [('import','IMPORT')] + tests + [('training_v7','item_field_training_v7.gd'),('herbs_v6','item_field_herbs_v6.gd'),('recovery_v5','item_field_recovery_v5.gd'),('field_v4','item_field_effects_v4.gd'),('connections','item_connections_test_runner.gd'),('api','field_api_integration_test_runner.gd'),('restore','field_restore_integration_test_runner.gd'),('medicine','showdown_medicine_test_runner.gd'),('policy','item_selection_policy_test_runner.gd')]
            for name, script in tests:
                r = execute(name, script, directory); report['groups'].append(r); write(directory/'results.json', report)
                assert r['status'] == 'PASS', name
            if not args.piece:
                r = execute('gpu', 'item_field_pp_v8.gd', directory, True); report['groups'].append(r)
                assert r['status'] == 'PASS', 'GPU'
            report['integrity_after'] = scope(not args.piece); report['status'] = 'PASS'
            if not args.piece: publish(report)
        except Exception as error: report['status'] = 'FAIL'; report['error'] = str(error)
        write(directory/'results.json', report)
        write(OUT/('piece_latest.json' if args.piece else 'results.json'), report)
        print('ITEM_FIELD_V8', report['status'], report.get('error',''), flush=True)
        return 0 if report['status'] == 'PASS' else 1

if __name__ == '__main__': sys.exit(main())
