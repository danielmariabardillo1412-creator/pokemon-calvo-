class_name BattleEventCollector
extends RefCounted

var received: Array[Dictionary] = []


func consume(events: Array[BattleEvent]) -> void:
	for event in events:
		received.append(event.to_dict())
