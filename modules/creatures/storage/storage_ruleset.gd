class_name StorageRuleset
extends RefCounted

# Centralized storage configuration for calvo_storage_v1.
# Pure domain config: no UI, no Nodes, no autoload.

const ID := &"calvo_storage_v1"
const SCHEMA_VERSION := 2

# Capacity of a single box. V1 policy: boxes are created dynamically as needed,
# so there is NO fixed MAX_BOXES cap in V1.
const BOX_CAPACITY := 30
