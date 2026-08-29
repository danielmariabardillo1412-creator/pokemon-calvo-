class_name CaptureRoutingResult
extends RefCounted

# Outcome of routing a captured creature after CaptureSystem.resolve().

var routed: bool = false        # a routing decision was applied
var stored: bool = false        # the creature ended up in storage
var reason: String = ""
