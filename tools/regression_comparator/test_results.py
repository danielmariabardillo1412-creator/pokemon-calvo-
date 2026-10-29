import unittest
import os,tempfile
from pathlib import Path
from run_lock import process_stamp,exclusive_lock
from runner import classify_log,compare,expected_negative_diagnostic
class ResultContracts(unittest.TestCase):
 def test_script_error_with_zero_exit_is_failure(self):
  self.assertEqual(classify_log('checks=20\nSCRIPT ERROR: example',0)['status'],'FAIL')
 def test_nonzero_exit_is_failure(self):
  self.assertEqual(classify_log('checks=20',1)['status'],'FAIL')
 def test_zero_assertions_not_green(self):
  self.assertEqual(classify_log('export completed',0)['status'],'INCONCLUSIVE_NO_ASSERTION_COUNT')
 def test_counted_suites(self):
  r=classify_log('=== TEST RESULT: 40 PASS / 0 FAIL ===',0)
  self.assertEqual((r['status'],r['checks_reported']),('PASS',40))
 def test_assertion_failure_not_green(self):
  self.assertEqual(classify_log('39 PASS / 1 FAIL',0)['status'],'FAIL')
 def test_failed_summary_with_zero_exit_not_green(self):
  self.assertEqual(classify_log('CHECKS FAIL checks=20',0)['status'],'FAIL')
  self.assertEqual(classify_log('{"status":"FAIL","checks":20}',0)['status'],'FAIL')
 def test_count_before_checks_and_nonzero_failures(self):
  result=classify_log('RANDOMLOCK CONTENT: 2065 checks; 0 failures',0)
  self.assertEqual((result['status'],result['checks_reported']),('PASS',2065))
  self.assertEqual(classify_log('CONTENT: 2065 checks; 1 failure',0)['status'],'FAIL')
 def test_json_passed_counter_is_assertion_evidence(self):
  result=classify_log('RESULT {"status":"PASS","passed":542,"failures":[]}',0)
  self.assertEqual((result['status'],result['checks_reported']),('PASS',542))
 def test_zero_failure_counter_after_checks_is_not_a_failure_count(self):
  for line,count in [('MOVE_CAMERA_REPAIR PASS checks=4630 failures=0',4630), ('SELF_SCREEN_LAYER PASS passed=8025 failures=0',8025)]:
   result=classify_log(line,0)
   self.assertEqual(result['errors'],[])
   self.assertEqual((result['status'],result['checks_reported']),('PASS',count))
  self.assertEqual(classify_log('AUDIT checks=4630 failures=2',0)['status'],'FAIL')
  self.assertEqual(classify_log('AUDIT 4630 checks; 2 failures',0)['status'],'FAIL')
  self.assertEqual(classify_log('PASS AUDIT checks=4630 failures=2',0)['status'],'FAIL')
 def test_timeout_not_green(self):
  self.assertEqual(classify_log('checks=20',0,True)['status'],'TIMEOUT')
 def test_paired_failure_not_hidden_by_equivalence(self):
  c={'labels':['original','organized'],'same_test_bytes':True}
  self.assertEqual(compare(c,{'original':{'status':'FAIL'},'organized':{'status':'FAIL'}}),'SHARED_FAILURE')
 def test_removed_current_test_is_coverage_gap(self):
  self.assertEqual(compare({'labels':['original']},{'original':{'status':'PASS'}}),'ORIGINAL_ONLY_COVERAGE_GAP')
 def test_new_regression_visible(self):
  c={'labels':['original','organized'],'same_test_bytes':True}
  self.assertEqual(compare(c,{'original':{'status':'PASS'},'organized':{'status':'FAIL'}}),'POSSIBLE_REGRESSION')
class NegativeJsonDiagnostic(unittest.TestCase):
 def test_known_negative_test_requires_assertion_and_single_error(self):
  line='ERROR: Parse JSON failed. Error at line 0: Expected key'
  body='PASS  sg_corrupt_rejected\n'+line+'\n40 PASS / 0 FAIL'
  cleaned,expected=expected_negative_diagnostic(body,{'script':'tests/test_runner.gd'})
  self.assertEqual(len(expected),1)
  self.assertEqual(classify_log(cleaned,0)['status'],'PASS')
  for text in [line,body+'\n'+line,body+'\nSCRIPT ERROR: broken']:
   cleaned,_=expected_negative_diagnostic(text,{'script':'tests/test_runner.gd'})
   self.assertEqual(classify_log(cleaned,0)['status'],'FAIL')
class LiveRunLock(unittest.TestCase):
 def test_live_process_identity_and_duplicate_runner_rejection(self):
  if os.name!='nt':self.skipTest('Local Windows comparator')
  self.assertIsNotNone(process_stamp(os.getpid()))
  cache=Path(__file__).resolve().parents[2]/'.godot/regression_comparator'
  cache.mkdir(exist_ok=True)
  with tempfile.TemporaryDirectory(prefix='lock_contract_',dir=cache) as tmp:
   root=Path(tmp).resolve();self.assertTrue(root.is_relative_to(cache.resolve()))
   (root/'.godot').mkdir()
   with exclusive_lock(root,root/'unused_destination'):
    with self.assertRaises(RuntimeError):
     with exclusive_lock(root,root/'unused_destination'):self.fail('Duplicate lock acquired')
   self.assertFalse((root/'.godot/regression_comparator/runner.lock.json').exists())

class OutputDirectories(unittest.TestCase):
 def test_only_declared_local_output_dirs_created(self):
  from fixtures import prepare_output_dirs
  cache=Path(__file__).resolve().parents[2]/'.godot/regression_comparator';cache.mkdir(exist_ok=True)
  with tempfile.TemporaryDirectory(prefix='output_contract_',dir=cache) as tmp:
   root=Path(tmp).resolve();self.assertTrue(root.is_relative_to(cache.resolve()))
   (root/'tests').mkdir()
   (root/'tests/probe.gd').write_text('extends SceneTree\nconst OUT := "res://.godot/report/"\nconst OUTPUT_FILE := "res://.godot/result.json"\n',encoding='utf-8')
   self.assertEqual(prepare_output_dirs(root,'tests/probe.gd'),['.godot/report/'])
   self.assertTrue((root/'.godot/report').is_dir());self.assertFalse((root/'.godot/result.json').exists())
   (root/'tests/probe.gd').write_text('extends SceneTree\nconst OUT := "res://.godot/../../escape/"\n',encoding='utf-8')
   with self.assertRaises(AssertionError):prepare_output_dirs(root,'tests/probe.gd')

class OutputRunConfiguration(unittest.TestCase):
 def test_dedicated_new_destination_updates_all_components(self):
  import runner
  old=runner.DEST
  try:
   with self.assertRaises(AssertionError):runner.configure_destination('D:/Proyectos/Pokemon Calvo')
   runner.configure_destination('D:/Proyectos/Pokemon Calvo - Comparador General UnitTest')
   self.assertEqual(runner.DEST,runner.snapshot.DEST)
   self.assertEqual(runner.DEST,runner.inventory.DEST)
   self.assertEqual(runner.DEST,runner.fixtures.DEST)
  finally:runner.configure_destination(str(old))

if __name__=='__main__':unittest.main()
