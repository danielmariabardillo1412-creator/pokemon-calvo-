"""Single-run lock checked against live process creation identity, not a stale file."""
from pathlib import Path
from contextlib import contextmanager
import ctypes,json,os,time
from ctypes import wintypes


def process_stamp(pid):
 if os.name!='nt':raise RuntimeError('This local comparator targets the Windows project environment')
 api=ctypes.WinDLL('kernel32',use_last_error=True)
 api.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD];api.OpenProcess.restype=wintypes.HANDLE
 api.GetExitCodeProcess.argtypes=[wintypes.HANDLE,ctypes.POINTER(wintypes.DWORD)]
 api.GetProcessTimes.argtypes=[wintypes.HANDLE]+[ctypes.POINTER(wintypes.FILETIME)]*4
 api.CloseHandle.argtypes=[wintypes.HANDLE]
 handle=api.OpenProcess(0x1000,False,int(pid))
 if not handle:return None
 try:
  code=wintypes.DWORD()
  if not api.GetExitCodeProcess(handle,ctypes.byref(code)) or code.value!=259:return None
  created=wintypes.FILETIME();exited=wintypes.FILETIME();kernel=wintypes.FILETIME();user=wintypes.FILETIME()
  if not api.GetProcessTimes(handle,ctypes.byref(created),ctypes.byref(exited),ctypes.byref(kernel),ctypes.byref(user)):return None
  return (created.dwHighDateTime<<32)|created.dwLowDateTime
 finally:api.CloseHandle(handle)


@contextmanager
def exclusive_lock(root,destination):
 directory=root/'.godot/regression_comparator';directory.mkdir(exist_ok=True)
 path=directory/'runner.lock.json'
 if path.exists():
  previous=json.loads(path.read_text(encoding='utf-8'))
  if process_stamp(previous['pid'])==previous['creation_stamp']:
   raise RuntimeError('Comparator runner is still alive; wait for that process instead of starting another')
  path.replace(directory/('stale_lock_'+str(time.time_ns())+'.json'))
 # Also recognize an older runner version which has no parent lock yet.
 live=destination/'live_process.json'
 if live.exists():
  child=json.loads(live.read_text(encoding='utf-8'));stamp=process_stamp(child['pid'])
  if stamp is not None and abs((stamp-116444736000000000)/10000000-child['started_at'])<5:
   raise RuntimeError('A recorded comparator child is still alive; do not resume concurrently')
 owner={'pid':os.getpid(),'creation_stamp':process_stamp(os.getpid()),'destination':str(destination)}
 assert owner['creation_stamp'] is not None
 with path.open('x',encoding='utf-8',newline='\n') as f:json.dump(owner,f,indent=2)
 try:yield
 finally:
  if path.exists() and json.loads(path.read_text(encoding='utf-8'))==owner:path.unlink()
