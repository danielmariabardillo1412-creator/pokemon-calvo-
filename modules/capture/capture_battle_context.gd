class_name CaptureBattleContext
extends RefCounted

# Battle-side contract for a capture attempt. Built by the integration layer from the live
# battle (NOT by redesigning Battle). Explicitly distinguishes wild vs trainer battle and
# carries the ownership/side facts CaptureSystem needs to reject invalid attempts.
#
# NOTE: this context is constructed by the integration layer. CaptureSystem is pure logic and does
# not verify who built it; the client/server trust boundary (if any) is enforced by a higher layer.

var is_wild: bool = true
var battle_finished: bool = false
var caller_trainer_id: StringName = &""        # empty for the local player in a wild battle
var target_owner_trainer_id: StringName = &""  # empty for a wild (unowned) creature
var target_side_id: StringName = &""
