extends SceneTree

## IA3/W03 TANDA05 H09: preserve existing Quick/Timer/Level/Repeat and Net
## contexts while V5 promotes Net's native integration. Domain invariants only;
## the native Repeat/Net and repel/rope gates run separately in the workflow.
var checks := 0
var errors: Array[String] = []

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_NET_V5_CONTEXT: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	ck("canonical data available", raw is Dictionary)
	if not raw is Dictionary:
		_end()
		return
	var catalogs: DefinitionCatalog = GameData.from_dict(raw).to_definition_catalog()
	var species: CreatureSpecies = catalogs.species(&"mewtwo")
	ck("low capture-rate canonical species", species != null and species.capture_rate == 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53005
	var target := CreatureFactory.create(species, 5, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"w03v5_context_target", "moves": ["tackle"], "nature_id": &"hardy"})
	target.ability_id = &""
	var effects = CaptureRuleset.ContextBallEffects
	var ctx := CaptureBattleContext.new()
	ctx.completed_turns = 0
	ctx.catcher_level = 50
	ctx.previously_caught_base_species = false
	ck("Quick Ball first turn 5x", is_equal_approx(effects.multiplier(&"quick_ball", target, species, ctx), 5.0))
	ctx.completed_turns = 1
	ck("Quick Ball later turns neutral 1x", is_equal_approx(effects.multiplier(&"quick_ball", target, species, ctx), 1.0))
	ctx.completed_turns = 0
	ck("Timer Ball initial 1x", is_equal_approx(effects.multiplier(&"timer_ball", target, species, ctx), 1.0))
	ctx.completed_turns = 1
	ck("Timer Ball turn one 1.3x", is_equal_approx(effects.multiplier(&"timer_ball", target, species, ctx), 1.3))
	ctx.completed_turns = 10
	ck("Timer Ball cap 4x", is_equal_approx(effects.multiplier(&"timer_ball", target, species, ctx), 4.0))
	ck("Level Ball leader 50 vs level 5 is 8x", is_equal_approx(effects.multiplier(&"level_ball", target, species, ctx), 8.0))
	ctx.catcher_level = 5
	ck("Level Ball equal levels neutral", is_equal_approx(effects.multiplier(&"level_ball", target, species, ctx), 1.0))
	ctx.previously_caught_base_species = false
	ck("Repeat Ball no ledger neutral", is_equal_approx(effects.multiplier(&"repeat_ball", target, species, ctx), 1.0))
	ctx.previously_caught_base_species = true
	ck("Repeat Ball existing base is 3.5x", is_equal_approx(effects.multiplier(&"repeat_ball", target, species, ctx), 3.5))
	ck("Net Ball neutral non-water/bug 1x", is_equal_approx(CaptureRuleset.BallEffects.multiplier(&"net_ball", target, species), 1.0))
	var dual: CreatureSpecies = catalogs.species(&"surskit")
	ck("dual Water/Bug species from canonical catalog", dual.has_type(&"water") and dual.has_type(&"bug"))
	var dual_target := CreatureFactory.create(dual, 5, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"w03v5_context_dual", "moves": ["tackle"], "nature_id": &"hardy"})
	dual_target.ability_id = &""
	ck("Net Water/Bug only one multiplier", is_equal_approx(CaptureRuleset.BallEffects.multiplier(&"net_ball", dual_target, dual), 3.5))
	ck("all contextual balls remain selectable", CaptureRuleset.new().is_known_ball(&"repeat_ball")
		and CaptureRuleset.new().is_known_ball(&"quick_ball")
		and CaptureRuleset.new().is_known_ball(&"timer_ball")
		and CaptureRuleset.new().is_known_ball(&"level_ball")
		and CaptureRuleset.new().is_known_ball(&"net_ball"))
	_end()

func _end() -> void:
	if errors.is_empty():
		print("W03_NET_V5_CONTEXT PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_NET_V5_CONTEXT FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
