class_name PartyRuleset
extends RefCounted

# Central configuration for the persistent party roster. The roster limit lives ONLY here
# (no magic number 6 scattered through the codebase).

const ID := &"calvo_party_v1"
const SCHEMA_VERSION := 2
const MAX_PARTY := 6
