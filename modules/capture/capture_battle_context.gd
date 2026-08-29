class_name CaptureBattleContext
extends RefCounted

# Battle-side contract for a capture attempt. Built by the integration layer from the live
# battle (NOT by redesigning Battle). Explicitly distinguishes wild vs trainer battle and
# carries the ownership/side facts CaptureSystem needs to reject invalid attempts.
#
# The client may only supply `ball_id` + `target_id`; the server reconstructs the real
# target creature + this context, so the result can never be forged client-side.

var is_wild: bool = true
var battle_finished: bool = false
var caller_trainer_id: StringName = &""        # empty for the local player in a wild battle
var target_owner_trainer_id: StringName = &""  # empty for a wild (unowned) creature
var target_side_id: StringName = &""
