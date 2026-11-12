extends RefCounted

# Development-only IPC experiment. No sockets, servers or production imports.
var pid := -1
var _stdio: FileAccess
var _stderr: FileAccess
var _pending := PackedByteArray()
var _sequence := 0
var stderr_text := ""
var timings: Array[float] = []


func start(node_path: String, worker_path: String = "res://modules/battle/backends/showdown/worker.cjs") -> bool:
	var process := OS.execute_with_pipe(node_path,
		[ProjectSettings.globalize_path(worker_path)], false)
	if process.is_empty(): return false
	pid = int(process.pid)
	_stdio = process.stdio
	_stderr = process.stderr
	return true


func exchange(tree: SceneTree, message: Dictionary, timeout_ms: int = 8000) -> Dictionary:
	if _stdio == null or not _stdio.is_open(): return {"ok": false, "error": "closed pipe"}
	_sequence += 1
	var request := message.duplicate(true)
	request["rpc_id"] = _sequence
	var bytes := (JSON.stringify(request) + "\n").to_utf8_buffer()
	if bytes.size() > 256 * 1024: return {"ok": false, "error": "oversized request"}
	var started := Time.get_ticks_usec()
	# Windows nonblocking pipes can refuse a snapshot larger than their buffer.
	# Bounded writes plus yielding let Node drain it without freezing the game.
	for offset in range(0, bytes.size(), 1024):
		_stdio.store_buffer(bytes.slice(offset, mini(offset + 1024, bytes.size())))
		if _stdio.get_error() != OK: return _transport_failure("pipe write failed")
		if Time.get_ticks_usec() - started >= timeout_ms * 1000: return _transport_failure("pipe write timeout")
		if offset + 1024 < bytes.size(): await tree.process_frame
	while Time.get_ticks_usec() - started < timeout_ms * 1000:
		if _stdio == null or not _stdio.is_open(): return {"ok": false, "error": "closed pipe"}
		var chunk := _stdio.get_buffer(65536)
		if not chunk.is_empty(): _pending.append_array(chunk)
		var diagnostics := _stderr.get_buffer(16384)
		if not diagnostics.is_empty(): stderr_text += diagnostics.get_string_from_utf8()
		var newline := _pending.find(10)
		if newline >= 0:
			var line := _pending.slice(0, newline).get_string_from_utf8()
			_pending = _pending.slice(newline + 1)
			var value: Variant = JSON.parse_string(line)
			if not value is Dictionary or int(value.get("rpc_id", -1)) != _sequence:
				return _transport_failure("invalid RPC envelope")
			timings.append((Time.get_ticks_usec() - started) / 1000.0)
			return value
		if _pending.size() > 8 * 1024 * 1024: return _transport_failure("oversized response")
		if not OS.is_process_running(pid): return {"ok": false, "error": "worker exited", "stderr": stderr_text}
		await tree.process_frame
	return _transport_failure("worker timeout")


func _transport_failure(reason: String) -> Dictionary:
	print("W04_V7_PIPE_STEP before_stdio_close")
	if _stdio != null and _stdio.is_open(): _stdio.close()
	print("W04_V7_PIPE_STEP after_stdio_close")
	if pid >= 0 and OS.is_process_running(pid): OS.kill(pid)
	return {"ok": false, "error": reason, "stderr": stderr_text}


# W04 V7: bounded native worker close. exchange() reads a duplex pipe and
# may block on get_buffer while the shutdown RPC is in progress. Never await
# that read in teardown. Send the ordinary shutdown RPC, give the worker a
# bounded grace period to exit normally, then kill and report escalation.
# Active battle RPCs and exchange() semantics remain unchanged.
func close(tree: SceneTree) -> bool:
	print("W04_V7_PIPE_STEP entry")
	var worker_pid := pid
	var shutdown_sent := false
	if _stdio != null and _stdio.is_open() and worker_pid >= 0 and OS.is_process_running(worker_pid):
		_sequence += 1
		var payload := (JSON.stringify({"op": "shutdown", "rpc_id": _sequence}) + "\n").to_utf8_buffer()
		print("W04_V7_PIPE_STEP before_write")
		_stdio.store_buffer(payload)
		print("W04_V7_PIPE_STEP after_write")
		shutdown_sent = _stdio.get_error() == OK
	print("W04_V7_PIPE_STEP before_poll")
	var graceful := false
	var deadline := Time.get_ticks_msec() + 1200
	while worker_pid >= 0 and OS.is_process_running(worker_pid) and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	if worker_pid < 0 or not OS.is_process_running(worker_pid):
		graceful = shutdown_sent
	var forced := worker_pid >= 0 and OS.is_process_running(worker_pid)
	if forced:
		var error := OS.kill(worker_pid)
		if error != OK: push_warning("W04_V7_PIPE_CLOSE kill_error=" + str(error))
	if _stdio != null and _stdio.is_open(): _stdio.close()
	print("W04_V7_PIPE_STEP before_stderr_close")
	if _stderr != null and _stderr.is_open(): _stderr.close()
	print("W04_V7_PIPE_STEP after_stderr_close")
	if worker_pid >= 0:
		await tree.create_timer(0.03).timeout
	var stopped := worker_pid < 0 or not OS.is_process_running(worker_pid)
	print("W04_V7_PIPE_CLOSE shutdown_sent=", shutdown_sent,
		" graceful=", graceful, " forced=", forced, " stopped=", stopped)
	pid = -1
	_stdio = null
	_stderr = null
	return stopped


func stop_now() -> void:
	_transport_failure("session_closed")
	if _stderr != null and _stderr.is_open(): _stderr.close()
	pid = -1
