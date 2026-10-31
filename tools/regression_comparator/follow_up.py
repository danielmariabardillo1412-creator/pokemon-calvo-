"""Review completed raw evidence, preserve history, and append bounded follow-up gates."""
from pathlib import Path
import argparse,hashlib,json,shutil,time
import runner,snapshot,fixtures
from run_lock import exclusive_lock


def prepare_follow_ups():
 root=runner.DEST;out=root/'reports/results.json'
 report=snapshot.read(out);assert report['status']!='RUNNING','Wait for the active full runner'
 received_sha=snapshot.sha(out)
 shutil.copyfile(out,root/('reports/results_before_followups_'+received_sha[:12]+'.json'))
 cases=snapshot.read(root/'cases.json');old_sha=snapshot.sha(root/'cases.json')
 shutil.copyfile(root/'cases.json',root/('cases_'+old_sha[:12]+'.json'))
 by_id={c['id']:c for c in cases['cases']}
 # Reclassify authentic existing logs with the stricter current parser. No game rerun.
 for key,row in report['cases'].items():
  case=by_id.get(key,{'id':'state_trace','script':'tests/comparator_state_trace.gd','labels':['original','organized'],'same_test_bytes':True})
  old_comparison=row['comparison']
  for label,result in row['results'].items():
   log=Path(result['log']);assert snapshot.sha(log)==result['log_sha256'],'Raw execution log changed'
   raw=log.read_text(encoding='utf-8',errors='replace');cleaned,expected=runner.expected_negative_diagnostic(raw,case)
   parsed=runner.classify_log(cleaned,result['exit_code'],result['status']=='TIMEOUT')
   if parsed['status']!=result['status']:result['classification_before_review']=result['status']
   result.update(parsed);result['expected_negative_test_diagnostics']=expected
  row['comparison']=runner.compare(case,row['results'])
  if row['comparison']!=old_comparison:row['comparison_before_review']=old_comparison
 # Recover only seven exact Git-archived evidence JSONs into isolated projects.
 staged=root/'reports/source_fixture_candidates';references=snapshot.read(staged/'manifest.json');recovered=[]
 for ref in references['files']:
  source=staged/ref['path'];assert snapshot.sha(source)==ref['sha256']
  for label in snapshot.SOURCES:
   target=root/label/ref['path'];assert target.resolve().is_relative_to((root/label/'data/api').resolve())
   if target.exists():assert snapshot.sha(target)==ref['sha256'],'Do not overwrite differing source evidence'
   else:target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
   recovered.append({'label':label,'path':ref['path'],'sha256':ref['sha256'],'git_blob':ref['git_blob']})
 snapshot.write(root/'reports/ARCHIVED_SOURCE_EVIDENCE_APPLIED.json',{'status':'EXACT_GIT_BYTES_IN_ISOLATED_TEST_COPIES_ONLY','files':recovered,'source_projects_modified':False})
 queued=snapshot.read(root/'reports/FOLLOW_UP_CASES.json')['cases']
 for script in ['tests/data/data_foundation_v3_domain_test_runner.gd','tests/data/spanish_types_foundation_test_runner.gd']:
  queued.append({'script':script,'args':[],'id_suffix':'__archived_source_evidence','evidence':'Seven missing immutable source records recovered from identical Git blobs. Historical report mismatches remain visible; reports are not regenerated.'})
 added=[]
 for requested in queued:
  base=next(c for c in cases['cases'] if c['script']==requested['script'])
  case=base.copy();case['id']=base['id']+requested['id_suffix'];case['args']=requested['args'];case['follow_up_reason']=requested['evidence']
  if requested.get('mode'):case['mode']=requested['mode']
  if case['id'] in by_id:continue
  cases['cases'].append(case);by_id[case['id']]=case;added.append(case['id'])
 probe=runner.ROOT/'tools/regression_comparator/entrypoint_probe.gd';digest=snapshot.sha(probe)
 for label in snapshot.SOURCES:shutil.copyfile(probe,root/label/'tests/comparator_entrypoint_probe.gd')
 case={'id':'configured_entrypoint_contract','script':'tests/comparator_entrypoint_probe.gd','labels':list(snapshot.SOURCES),'same_test_bytes':True,'test_sha256':{label:digest for label in snapshot.SOURCES},'mode':'headless','args':[],'group':'entrypoint','timeout_seconds':180}
 if case['id'] not in by_id:cases['cases'].append(case);added.append(case['id'])
 cases.setdefault('reviewed_extensions',[]).append({'previous_manifest_sha256':old_sha,'added_cases':added,'reason':'Correct intended legacy test context; complete workspace inputs; independent actual-main contract. Initial failed gates are retained.'})
 snapshot.write(root/'cases.json',cases)
 report['case_manifest_sha256']=snapshot.sha(root/'cases.json')
 report.setdefault('plan_revisions',[]).append({'previous_sha256':old_sha,'new_sha256':report['case_manifest_sha256'],'added_cases':added,'reason':'Bounded reviewed follow-ups after first full run; no initial result removed.'})
 report['classifier_review']={'source_sha256':snapshot.sha(runner.ROOT/'tools/regression_comparator/runner.py'),'raw_logs_verified':True,'previous_results_sha256':received_sha}
 snapshot.write(out,report)
 return report


def main():
 parser=argparse.ArgumentParser();parser.add_argument('--output');args=parser.parse_args();runner.configure_destination(args.output)
 with exclusive_lock(runner.ROOT,runner.DEST):
  prepare_follow_ups()
  return runner.main(argparse.Namespace(prepare=False,pilot=False,resume=True,refresh_additive=False,output=None))
if __name__=='__main__':raise SystemExit(main())
