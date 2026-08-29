class_name CaptureDisposition
extends RefCounted

# Where a successfully captured creature should be routed.

const PARTY := &"PARTY"
const STORAGE_REQUIRED := &"STORAGE_REQUIRED"
# Captured and resolved, but no party was provided to route into (caller preview / no roster).
const UNROUTED := &"UNROUTED"
