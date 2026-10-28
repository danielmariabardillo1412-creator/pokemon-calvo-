extends "res://modules/battle/backends/showdown/pipe_client.gd"

func start(node_path: String, worker_path: String = "res://tools/showdown_engine_probe/bridge.cjs") -> bool:
	return super.start(node_path, worker_path)
