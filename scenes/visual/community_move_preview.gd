extends Control

# Silent resource renderer. Full preview is isolated; effects_only is the narrow
# battle adapter and omits native body cells AND full-screen BG/FG plates.
# Data-format reference: Pokemon Essentials (Maruno17), CC-BY-NC-SA-4.0.
# This bounded adapter changes the camera to our catalog layout. Not a complete
# Essentials implementation; no downloaded Ruby/Showdown code is executed.
const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
const BattleArt = preload("res://scenes/visual/battle_art.gd")
const TintShader = preload("res://scenes/visual/community_move_tint.gdshader")
const DEFAULT_PACK := "res://.godot/move_resource_pilot/manifest.json"
const SOURCE_BACK := Vector2(128, 224)
const SOURCE_FRONT := Vector2(384, 96)
# Audited native OppMove target-local particles authored around SOURCE_BACK.
# Bind to complete immutable exported frames; do not infer focus from position
# or apply this to trajectories, body cels or every opposing-side animation.
const NATIVE_TARGET_EXPORTS := {
	"crush_grip/front": "6f47c22878a82b15431056db4d423285b5dd52a72487e02dcf4343ef9652f689",
	"drill_run/front": "ebd005fdeb0a7f0d97651c2fa4bc133563b9defde7acbbda2b31d2af36e3ed7c",
	"dual_wingbeat/front": "26f4ca9c630224855945f04fbb316433e7f79665a5cff983083ee2bcc41c2d35",
	"force_palm/front": "c9f2bb42cd17b8d9e00e36bca2ae116d614eb9b21a7cbf4b58334d41d75375e0",
	"poison_sting/front": "9a6589ad9dab37ae601259136e76897788add97a645cdf907bc2e02a648694c2",
	"poison_tail/front": "57cf7dc5d29a5a7e6c8b2deb71569de6db4f2554ef868663c0dbc81ea2c43af5",
	"pollen_puff/front": "04766ca4fb97cc96c99fd8863afe06ee4ac476610b454f613d9f5224d731f755",
	"power_whip/front": "5082f6ea77ec2e93da321beb100aae074096f7d9fe05b2793b40838e0280f83f",
	"scary_face/front": "649dc59aed64b1575b33b0a445f51fba9267e40e7556c82bfa26fe1adf16cf42",
	"sludge/front": "02c31e7be1e40ddec375f220f93a49d1966e252728f63017f1e7ec0bc7bb7b43",
	"thunderclap/front": "ab1ab32b91f53f539b7e77193fdeee82bce15265e7b6baf821ef118f9caea016",
	"wing_attack/front": "30a39ea53575093feef607237a543d3170feecb396e559d72828251b967f9b27",
	"worry_seed/front": "d0245c2d4f3504b4f0ca4c58ce31d4a0842386bd4c6e34e1660abac5661a4e43",
}
const NATIVE_PROJECTION_EXPORTS := {
	"light_screen/front": "575af24b4e2f2023e4ed72044a8d90abf9ac405d9d364bf330ee746c90d1f3a1",
	"mat_block/front": "d40d0f70b26504439e3aea57e54eb5668331d6ab6a403f0b4eea38a0b8104c52",
	"quick_guard/front": "423cea32d99ab240f2dd8aaae27988f1bb70b85ac3fb3503ab3cc1d41951258f",
	"reflect/front": "575af24b4e2f2023e4ed72044a8d90abf9ac405d9d364bf330ee746c90d1f3a1",
	"shadow_sneak/front": "95fa414ed0a4fca15d1573af280c4b345abae42d2a40654a58be029757c122c4",
}
const TWIN_BEAM_ENDPOINT_SHA := "1b3b97e1378e8077c5f9db391937c8690f056b9fb768dc2f754b6de39f5e25e6"
# This composite Opp sheet contains the primary crest at rows 0..139 and a
# disconnected water strip at 524..1150. Only the audited HYDROVORTEX timeline
# exposes that second strip before the real crest. Surf needs its later fill.
const HYDRO_PRIMARY_IDS := ["hydro_vortex_physical/front", "hydro_vortex_special/front", "max_geyser/front"]
const HYDRO_FRAMES_SHA := "0ec2a1e281c22e0cca403466a6041b4dc3e3a66bf85c7e759e44e23307396a56"
const HYDRO_LAYERS_SHA := "2eb7a2a414b5f659d5ca158240a2a05a462417f05fe65c99c286e015ee8770bf"
const HYDRO_FOREGROUND := "09da26c53034515f626d168e7c304c0cdd7656e1f37b840b0994462b0a0da6c4.png"
const LOCAL_EFFECT_EXPORTS := {
	"acupressure": ["73936003acd758d38aff94effc54ba66432865f7185bd2f1c73628f153a28041", "205e3072c12216dde8962cae362a202e044d6b9befa8ae1ff8a41f5828f15f50", "63b74fdbb7910c65a0f14a85f7ce9b19c909ff87d97a32a8ce4a5cf51ae60dca.png"],
	"entrainment": ["73ea35fb13956822d992164d372b9c59864dae5e032abdacb2840a21653dcbdd", "6da099972753ddd38c8366fef39917a0b23ef824ef87b02194f76265a0568ead", ""],
	"flatter": ["790754259e806099d288edf2859e71f13f15806a7f5298f24ca007c85b382ddf", "b4b3d9e4f9e393e5ad44c31e16b42c2e8d34826af0bcb15b611c9e314f73a9a0", "8a3a844354cff07cf75a470ea743d5e034434a8488e8e15f1a687f0751fdee49.png"],
}
const DASH_PATH_EXPORTS := {
	"rock_climb/back": "a7e8533ad00b297688b5206e60746423233f709beea8b3a73f68d909afbbd4be",
	"rock_climb/front": "021b614fd532d2def27a26b78e5abfcfd5935e95a30b0b5c4821696f37fdf025",
	"take_down/back": "353bcb4f4e62bba8511aa44609ea8d55fe11fea127261aa6f167afcd786d036e",
	"take_down/front": "1df8456b2d79bc7f116794ba43878b23f54b05377434d5b4ae1c0eefedf029ae",
}
const MOTIF_ART_EXPORTS := {
	"behemoth_bash": ["06d1e8a312c5cc34ebce23b7e469130099333e8adac303aec1bee42da418d526", "c2b486a81ede63cf646df21bf74ff42852dc6e613f0da00b13f76572f8232813", "0358ed475071f6b278eecf7ea8f76ee1389172deacfca061f46a9449ec116f85.png"],
	"catastropika": ["ae4af81eee61abcdee8d24f6d0f96453379b3ea79a1bf737cddfc201bc7226a3", "f9375949e498b4217627cffbd20f9a489a268bb3dc3123ce949b1607607c972b", "06d5c56c0bf6101af4678080a411d28baf15b85ff727c8a06717995abc048339.png"],
}
const Z_VISUAL_EXPORTS := {
	"extreme_evoboost": {"frames": ["37593a20f52a856b16911c9e8bd7825cf57cbb68a8d2bbef5a3a16dc0126a3ac", "37593a20f52a856b16911c9e8bd7825cf57cbb68a8d2bbef5a3a16dc0126a3ac"], "layers": "c65f35c21bfd6ed946e4835677206a4591505749528a97baeafbe9f50aeed84f", "sheet": "0e61a6cb1ad5e7ec1a9f162faa6ba05a164343c703d58757f7bc98c2aacd4bbc.png"},
	"genesis_supernova": {"frames": ["ba19a81e239662a13b79cb8a773fb4122e8af42eb403276520908af4406d4d33", "ba19a81e239662a13b79cb8a773fb4122e8af42eb403276520908af4406d4d33"], "layers": "574b54047f69275020cf0a4d1a0580bef7c0f1e78890ff10236660bbf778f773", "sheet": "fa016c6aaf0a5edd0c4f04b928adf6f60024ab95c20da950b2916ae6ab7aadcf.png"},
	"guardian_of_alola": {"frames": ["2ba938116f2f9b7ba5eeb3aa37c7c2d94c63a43e99f7d7933a149e0fa58a7948", "2ba938116f2f9b7ba5eeb3aa37c7c2d94c63a43e99f7d7933a149e0fa58a7948"], "layers": "d2a68c6947099da8be05a0bcd13d5c7967cfb34001abdbb2001010100574ad36", "sheet": "172bfa40c8d64aa75f057d269d663cffbab8df65c9c6c407d5cea0b21e1b7c7a.png"},
	"lets_snuggle_forever": {"frames": ["3c89ad289f417f16c5f4038c0280b4c1e974b134067102557db4135f85fd7653", "5418f7703049c488fa6573b362240780e7bd9d1982bed8f69c21eacc81a87df9"], "layers": "c1c5f2b5d23088b1c8bbf0ffa8785bca77e1eecdd88273e06748739b142f2bf0", "sheet": "f212e296f08d20307ad4c91ea0c7cfd39e3513c989fc99f020b040776a3fefff.png"},
	"savage_spin_out_physical": {"frames": ["b662b144400ff39d484d49e735a7d890601c4a1b458d8454b1c9258c77ad382a", "a6a2f0552ce67a24c8839f717a0ff07dee6233f09b7e92e6cc8ba66ee3bcc31b"], "layers": "39d2b4b8ea8c55152573ea2b72c6b57761b8783884e1cb7a056dff7ad8dee825", "sheet": "bc197b01a26f133c8454412fc156ed88b77215866cbedf295c7023e7bf4a1e5c.png"},
	"savage_spin_out_special": {"frames": ["b662b144400ff39d484d49e735a7d890601c4a1b458d8454b1c9258c77ad382a", "a6a2f0552ce67a24c8839f717a0ff07dee6233f09b7e92e6cc8ba66ee3bcc31b"], "layers": "39d2b4b8ea8c55152573ea2b72c6b57761b8783884e1cb7a056dff7ad8dee825", "sheet": "bc197b01a26f133c8454412fc156ed88b77215866cbedf295c7023e7bf4a1e5c.png"},
	"soul_stealing_7_star_strike": {"frames": ["ebf100b93582e4ba0788804fc6b36ea76e4aed65003b732dcd299327c534ff9b", "ebf100b93582e4ba0788804fc6b36ea76e4aed65003b732dcd299327c534ff9b"], "layers": "51c991eb1cb817e2a15f86e7560bc2aa1a0ebb392f3fa47e73ea8aea15e5f964", "sheet": "9d5936d9eb8f6654c18593cef8223768beae30e63787cf198ff42a77a74186c0.png"},
}
const GENERAL_POSE_EXPORTS := {
	"clanging_scales": ["1e83490aa1270a1161135cda9ef70c864fd43aad053e109af92ca4a262b386a4", "fb60641527c6688c6362f84076804afd457e394c552d567c8c62540d2bab9f89", "e7fbd615b8c892636cde38c0303b70fc7ba9f83ad443e0b4ddc809471ea3c97d.png"],
	"court_change": ["cf882945a59b669d577d60983b45d3b1d67b60cbed2ba55ead8b5a0de8830c20", "489ac687b6ee002a724b9c9f8dfef407a4a5d08698747cc3a78d7e4c9dea42f7", ""],
}
var pack: Dictionary = {}
var textures: Dictionary = {}
var clip: Dictionary = {}
var last_error := ""
var current_frame := -1
var effects_only := false
var affine_particle_path := false
var external_actor_layout := {} # Optional real doubles positions, keyed by clip slot.
var external_layer_names: Array[String] = [] # Explicit environmental layers for that camera.
var external_bystanders: Array[Dictionary] = []
var _bystander_sprites: Array[Sprite2D] = []
var back_species: StringName = &"ogerpon"
var front_species: StringName = &"charizard"
var _sprites: Array[Sprite2D] = []
var _layers: Dictionary = {}
var _arena: Control
var _actors: Dictionary = {}
var _blend_shaders: Dictionary = {}
var _white: ImageTexture
var _water_primary_shader: Shader


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and current_frame >= 0:
		call_deferred("_refresh_resized_frame")


func _refresh_resized_frame() -> void:
	if is_inside_tree() and not is_queued_for_deletion() and current_frame >= 0 and _sprites.size() == 60:
		show_frame(current_frame)


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_blend_shaders[0] = TintShader
	_water_primary_shader = Shader.new()
	_water_primary_shader.code = TintShader.code.replace("vec4 pixel = texture(TEXTURE, UV);", "if (fract(UV.y) >= 524.0 / 1151.0) { discard; }\n\tvec4 pixel = texture(TEXTURE, UV);")
	for blend in [1, 2]:
		var shader := Shader.new()
		shader.code = TintShader.code.replace("render_mode unshaded;", "render_mode unshaded, %s;" % ("blend_add" if blend == 1 else "blend_sub"))
		_blend_shaders[blend] = shader
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	_white = ImageTexture.create_from_image(white)
	_arena = BattleArt.new()
	add_child(_arena)
	_arena.set_process(false)
	for layer: String in ["back", "front"]:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.z_index = 5 if layer == "back" else 85
		sprite.material = _material()
		add_child(sprite)
		_layers[layer] = sprite
	for index in 60:
		var sprite := Sprite2D.new()
		sprite.region_enabled = true
		sprite.visible = false
		sprite.material = _material()
		add_child(sprite)
		_sprites.append(sprite)


func _material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TintShader
	return material


func load_pack(path: String = DEFAULT_PACK) -> bool:
	clear_preview()
	pack = {}
	textures.clear()
	last_error = ""
	if not FileAccess.file_exists(path):
		return _invalid("Falta el pack local de prueba: " + path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version") != 1 or not parsed.get("clips") is Array or not parsed.get("sheets") is Dictionary:
		return _invalid("Manifiesto de prueba inválido")
	var batch: bool = parsed.get("selection") == "automated_batch_v1" and parsed.get("scope") == "LAB_ONLY_NOT_BATTLE_APPROVAL"
	if (batch and (parsed.clips.is_empty() or parsed.clips.size() > 64)) or (not batch and not parsed.clips.size() in [2, 4, 10, 40, 62, 70]):
		return _invalid("Este laboratorio solo admite sus selecciones acotadas")
	var pixel_budget := 0
	for key: String in parsed.sheets:
		var row: Dictionary = parsed.sheets[key]
		if key != String(row.get("sha256", "")) + ".png" or key.contains("/") or key.contains("\\") or key.contains(".."):
			return _invalid("Ruta de hoja inválida")
		var sheet_path := path.get_base_dir().path_join(key)
		if not FileAccess.file_exists(sheet_path) or FileAccess.get_sha256(sheet_path) != row.sha256:
			return _invalid("Hoja ausente o modificada: " + key)
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(sheet_path)) != OK:
			return _invalid("PNG inválido")
		var dimensions: Array = row.get("dimensions", [])
		pixel_budget += image.get_width() * image.get_height()
		if batch and pixel_budget > 32000000:
			return _invalid("Lote supera el presupuesto de texturas")
		if dimensions.size() != 2 or float(dimensions[0]) != image.get_width() or float(dimensions[1]) != image.get_height():
			return _invalid("Dimensiones de hoja incorrectas")
		textures[key] = ImageTexture.create_from_image(image)
	var ids: Dictionary = {}
	for row: Dictionary in parsed.clips:
		if not row.get("actor_side") in ["back", "front"] or not row.get("opponent_export") is bool or not row.get("mapped_opponent") is bool:
			return _invalid("Metadatos de lado inválidos")
		var id := String(row.get("id", ""))
		var context := String(row.get("context_key", ""))
		var variant := String(row.get("variant_key", ""))
		if not context.is_empty() and not context in ["neutral", "electric", "grassy", "misty", "psychic"]:
			return _invalid("Referencia de contexto inválida")
		if (not variant.is_empty() and (not variant in ["fire", "rock", "water"] or row.get("move_id") != "ivy_cudgel")) or (not context.is_empty() and not variant.is_empty()):
			return _invalid("Variante de efecto inválida")
		var suffix := context if not context.is_empty() else variant
		if id != String(row.get("move_id", "")) + ("/" + suffix if not suffix.is_empty() else "") + "/" + String(row.actor_side) or ids.has(id):
			return _invalid("ID duplicado o inválido")
		ids[id] = true
		if (not String(row.get("sheet", "")).is_empty() and not textures.has(row.sheet)) or row.get("fps") != 20 or not row.get("frames") is Array or not row.get("layers") is Array:
			return _invalid("Clip inválido")
		var sides: Array = [String(row.actor_side), String(row.actor_side)] if row.get("target_scope") == "user" else ["front", "back"] if row.mapped_opponent else ["back", "front"]
		if row.frames.size() < 2 or row.frames.size() > 200 or row.frames.size() != row.layers.size() or row.get("slot_sides") != sides:
			return _invalid("Cadencia o lados inválidos")
		var dimensions := Vector2.ZERO if String(row.sheet).is_empty() else Vector2(textures[row.sheet].get_size())
		if not row.get("uniform_screen_patterns", []) is Array:
			return _invalid("Geometría de pantalla inválida")
		var uniform_patterns: Array[int] = []
		for pattern: Variant in row.get("uniform_screen_patterns", []):
			if not (pattern is float or pattern is int) or float(pattern) != int(pattern) or int(pattern) < 0:
				return _invalid("Patrón de geometría inválido")
			uniform_patterns.append(int(pattern))
		# JSON numbers are floats; Array.has() distinguishes int from float.
		# Normalize once so pattern 0 actually receives its declared geometry.
		row.uniform_screen_patterns = uniform_patterns
		if not row.get("affine_particle_patterns", []) is Array:
			return _invalid("Geometría afín inválida")
		var affine_patterns: Array[int] = []
		for pattern: Variant in row.get("affine_particle_patterns", []):
			if not (pattern is float or pattern is int) or float(pattern) != int(pattern) or int(pattern) < 0 or row.mapped_opponent:
				return _invalid("Geometría afín requiere export nativo y patrón válido")
			affine_patterns.append(int(pattern))
		row.affine_particle_patterns = affine_patterns
		for frame: Variant in row.frames:
			if not frame is Array or frame.size() > 60:
				return _invalid("Fotograma inválido")
			for cel: Variant in frame:
				if cel == null:
					continue
				if not cel is Array or cel.size() != 27:
					return _invalid("Celda inválida")
				for field in 27:
					if field in [9, 10]:
						continue
					if not (cel[field] is float or cel[field] is int) or not is_finite(float(cel[field])):
						return _invalid("Valor de celda inválido")
				if not int(cel[5]) in [0, 1, 2] or not int(cel[26]) in [1, 2, 3, 4] or not int(cel[25]) in [0, 1, 2, 3]:
					return _invalid("Modo no incluido en este piloto")
				var pattern := int(cel[7])
				if pattern in affine_patterns and int(cel[26]) != 3:
					return _invalid("Geometría afín requiere foco de línea")
				if pattern < -2 or float(pattern) != float(cel[7]):
					return _invalid("Patrón inválido")
				if pattern >= 0 and ((pattern % 5) * 192 >= dimensions.x or (pattern / 5) * 192 >= dimensions.y):
					return _invalid("Patrón fuera de la hoja")
		if not row.get("layer_sheets") is Dictionary:
			return _invalid("Fondos inválidos")
		for layers: Dictionary in row.layers:
			for layer: String in ["back", "front"]:
				var data: Dictionary = layers.get(layer, {})
				if not data.get("name") is String:
					return _invalid("Capa inválida")
				if not data.name.is_empty() and not textures.has(row.layer_sheets.get(data.name, "")):
					return _invalid("Falta una hoja de fondo")
				for field: String in ["bgX", "bgY", "opacity", "colorRed", "colorGreen", "colorBlue", "colorAlpha"]:
					if not (data.get(field) is float or data.get(field) is int) or not is_finite(float(data[field])):
						return _invalid("Valor de capa inválido")
		row["_native_target_anchor"] = false
		if NATIVE_TARGET_EXPORTS.has(id):
			if not row.opponent_export or row.mapped_opponent or row.name != "OppMove:" + String(row.move_id).replace("_", "").to_upper() or JSON.stringify(row.frames).sha256_text() != NATIVE_TARGET_EXPORTS[id]:
				return _invalid("Export distinto del anclaje auditado: " + id)
			row["_native_target_anchor"] = true
		row["_native_projection"] = ""
		if NATIVE_PROJECTION_EXPORTS.has(id):
			if not row.opponent_export or row.mapped_opponent or row.name != "OppMove:" + String(row.move_id).replace("_", "").to_upper() or JSON.stringify(row.frames).sha256_text() != NATIVE_PROJECTION_EXPORTS[id]:
				return _invalid("Export distinto de la proyección auditada: " + id)
			row["_native_projection"] = "shadow_path" if row.move_id == "shadow_sneak" else "field_body"
		row["_beam_target_source_x"] = 0.0
		if id == "twin_beam/front":
			if not row.opponent_export or row.mapped_opponent or row.name != "OppMove:TWINBEAM" or JSON.stringify(row.frames).sha256_text() != TWIN_BEAM_ENDPOINT_SHA:
				return _invalid("Export distinto del extremo de haz auditado: " + id)
			# The terminal lower strand is x176, upper strand x178. Preserve
			# their small separation; map x176 to the target instead of x128.
			row["_beam_target_source_x"] = 176.0
		row["_hydro_primary_only"] = false
		if id in HYDRO_PRIMARY_IDS:
			if not row.opponent_export or row.mapped_opponent or row.name != "OppMove:HYDROVORTEX" or row.layer_sheets.get("PRAS- Surf FG Opp.png") != HYDRO_FOREGROUND or JSON.stringify(row.frames).sha256_text() != HYDRO_FRAMES_SHA or JSON.stringify(row.layers).sha256_text() != HYDRO_LAYERS_SHA:
				return _invalid("Export distinto del frente de agua auditado: " + id)
			row["_hydro_primary_only"] = true
		row["_local_effect"] = ""
		var local_id := String(row.move_id)
		if LOCAL_EFFECT_EXPORTS.has(local_id) and (local_id != "entrainment" or row.actor_side == "front"):
			var proof: Array = LOCAL_EFFECT_EXPORTS[local_id]
			if row.opponent_export or row.mapped_opponent != (row.actor_side == "front") or row.name != "Move:" + local_id.replace("_", "").to_upper() or row.sheet != proof[2] or JSON.stringify(row.frames).sha256_text() != proof[0] or JSON.stringify(row.layers).sha256_text() != proof[1]:
				return _invalid("Export distinto del efecto local auditado: " + id)
			row["_local_effect"] = local_id
		row["_dash_user_path"] = false
		if DASH_PATH_EXPORTS.has(id):
			var expected_sheet := "3d4acab1e7ea383b2ea0a1afb3a85335d5707d7942b80064b14e9ee8a7beaf12.png" if row.move_id == "rock_climb" else "40a83e5ae4fa930779b388a7c1b7191474a367a488f370212301438a6bee5f62.png"
			if row.mapped_opponent or row.opponent_export != (row.actor_side == "front") or row.name != ("OppMove:" if row.opponent_export else "Move:") + String(row.move_id).replace("_", "").to_upper() or row.sheet != expected_sheet or JSON.stringify(row.frames).sha256_text() != DASH_PATH_EXPORTS[id]:
				return _invalid("Export distinto del recorrido de carga auditado: " + id)
			row["_dash_user_path"] = true
		row["_motif_policy"] = ""
		if MOTIF_ART_EXPORTS.has(local_id):
			var motif_proof: Array = MOTIF_ART_EXPORTS[local_id]
			if row.opponent_export or row.mapped_opponent != (row.actor_side == "front") or row.name != "Move:" + local_id.replace("_", "").to_upper() or row.sheet != motif_proof[2] or JSON.stringify(row.frames).sha256_text() != motif_proof[0] or JSON.stringify(row.layers).sha256_text() != motif_proof[1]:
				return _invalid("Export distinto del motivo artístico auditado: " + id)
			row["_motif_policy"] = "steel_impact" if local_id == "behemoth_bash" else "electric_without_badge"
			row["visual_art_choice"] = {"policy": "pinned_partial_motif_choice_v1", "kind": "partial_motif_only", "source_name": "BEHEMOTHBASH · motivo PARCIAL 8→9, impacto metálico neutro" if local_id == "behemoth_bash" else "CATASTROPIKA · fase eléctrica PARCIAL sin insignia de Pikachu", "replaced_source_status": "renderable_but_art_rejected", "native_source_repaired": false, "mechanics_enabled": false, "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL"}
		row["_z_particle_choice"] = ""
		row["_z_fit_leap"] = false
		if Z_VISUAL_EXPORTS.has(local_id):
			var z_proof: Dictionary = Z_VISUAL_EXPORTS[local_id]
			var native: bool = row.actor_side == "front" and (local_id == "lets_snuggle_forever" or local_id.begins_with("savage_spin_out_"))
			var z_label := "SAVAGESPINOUT" if local_id.begins_with("savage_spin_out_") else local_id.replace("_", "").to_upper()
			if row.name != ("OppMove:" if native else "Move:") + z_label or row.opponent_export != native or row.mapped_opponent != (row.actor_side == "front" and not native) or row.sheet != z_proof.sheet or JSON.stringify(row.frames).sha256_text() != z_proof.frames[0 if row.actor_side == "back" else 1] or JSON.stringify(row.layers).sha256_text() != z_proof.layers:
				return _invalid("Export distinto de la referencia Z auditada: " + id)
			row["_z_fit_leap"] = local_id == "soul_stealing_7_star_strike"
			if local_id not in ["guardian_of_alola", "soul_stealing_7_star_strike"]:
				row["_z_particle_choice"] = local_id
				var choice := "orbes en lugar de evoluciones de Eevee" if local_id == "extreme_evoboost" else "energía psíquica en lugar de Mew" if local_id == "genesis_supernova" else "nube de impacto en lugar del disfraz de Mimikyu" if local_id == "lets_snuggle_forever" else "capullo e impactos sin Pokémon auxiliares"
				row["visual_art_choice"] = {"policy": "pinned_z_partial_motif_v1", "kind": "partial_motif_only", "source_name": "Z · opción PARCIAL: " + choice, "replaced_source_status": "renderable_but_art_rejected", "native_source_repaired": false, "mechanics_enabled": false, "scope": "LAB_ONLY_NOT_BATTLE_APPROVAL"}
		row["_general_pose"] = ""
		if GENERAL_POSE_EXPORTS.has(local_id):
			var pose_proof: Array = GENERAL_POSE_EXPORTS[local_id]
			if row.opponent_export or row.mapped_opponent != (row.actor_side == "front") or row.name != "Move:" + local_id.replace("_", "").to_upper() or row.sheet != pose_proof[2] or JSON.stringify(row.frames).sha256_text() != pose_proof[0] or JSON.stringify(row.layers).sha256_text() != pose_proof[1]:
				return _invalid("Export distinto de la pose general auditada: " + id)
			row["_general_pose"] = local_id
	pack = parsed
	return true


func _invalid(message: String) -> bool:
	last_error = message
	pack = {}
	textures.clear()
	return false


func clear_preview() -> void:
	clip = {}
	current_frame = -1
	for sprite: Sprite2D in _sprites:
		sprite.hide()
		sprite.texture = null
	for sprite: Sprite2D in _layers.values():
		sprite.hide()
		sprite.texture = null
	if _arena != null:
		_arena.set_runtime_visibility(false, false)


func select_clip(index: int) -> bool:
	clear_preview()
	if index < 0 or index >= pack.get("clips", []).size():
		return false
	clip = pack.clips[index]
	return show_frame(0)


func show_seconds(elapsed: float) -> bool:
	if clip.is_empty() or not is_finite(elapsed):
		return false
	return show_frame(int(floor(maxf(0.0, elapsed) * 20.0)))


func show_frame(index: int) -> bool:
	for sprite: Sprite2D in _bystander_sprites: sprite.hide()
	for sprite: Sprite2D in _sprites:
		sprite.hide()
	for sprite: Sprite2D in _layers.values():
		sprite.hide()
	current_frame = -1
	if clip.is_empty() or index < 0 or index >= clip.frames.size():
		return false
	current_frame = index
	_arena.size = size
	_arena.visible = not effects_only and external_actor_layout.is_empty()
	_arena.player_species = back_species
	_arena.enemy_species = front_species
	var self_targeted: bool = clip.get("target_scope") == "user"
	_arena.set_runtime_visibility(self_targeted and clip.actor_side != "back", self_targeted and clip.actor_side != "front")
	_arena.queue_redraw()
	_actors = {"back": _actor(back_species, "back"), "front": _actor(front_species, "front")}
	# Uninvolved doubles battlers share the clip's background/foreground depth,
	# so an environmental plate cannot erase two of the four participants.
	for i in external_bystanders.size():
		if _bystander_sprites.size() <= i:
			var sprite := Sprite2D.new(); sprite.region_enabled = true
			add_child(sprite); _bystander_sprites.append(sprite)
		var actor: Dictionary = external_bystanders[i]
		var sprite := _bystander_sprites[i]
		sprite.texture = actor.texture; sprite.region_rect = actor.region
		sprite.position = actor.center; sprite.offset = actor.offset
		sprite.scale = Vector2.ONE * float(actor.gain); sprite.z_index = int(actor.depth); sprite.show()
	if _actors.back.is_empty() or _actors.front.is_empty():
		last_error = "Falta una vista del Pokémon seleccionado"
		return false
	var frame: Array = clip.frames[index]
	var self_body_slot := _self_body_slot(frame) if self_targeted else -1
	for slot in frame.size():
		if frame[slot] == null:
			continue
		var cel: Array = frame[slot]
		if int(cel[6]) != 1 or float(cel[8]) <= 0.0:
			continue
		var sprite := _sprites[slot]
		var pattern := int(cel[7])
		var z_choice := String(clip.get("_z_particle_choice", ""))
		if z_choice.begins_with("savage_spin_out_") and pattern in [6, 7, 8, 9, 23, 24, 25, 26]:
			# Keep the source cocoon/web and impacts; omit fixed-species cameos.
			continue
		if z_choice == "extreme_evoboost" and pattern >= 0 and pattern < 8:
			pattern = 9 + pattern % 4
		elif z_choice == "genesis_supernova" and pattern >= 35 and pattern <= 46:
			pattern = 31 + (pattern - 35) % 3
		elif z_choice == "lets_snuggle_forever" and pattern in [3, 4, 5, 21, 22, 23, 24, 25, 26]:
			pattern = 12
		if clip.get("_motif_policy", "") == "electric_without_badge" and pattern in [10, 11, 12]:
			# Explicit partial art choice: keep the original electrical sequence,
			# omit only the three-tile species badge. The export stays immutable.
			continue
		var steel_motif: bool = clip.get("_motif_policy", "") == "steel_impact" and pattern == 8
		if steel_motif:
			# Reuse this same immutable atlas's neutral metallic impact tile.
			pattern = 9
		# Reset per use: a previously displayed atlas particle must not change
		# filtering for an unrelated clip or a battler in the same sprite slot.
		sprite.region_filter_clip_enabled = steel_motif or (pattern >= 0 and (clip.get("_local_effect", "") == "flatter" or not z_choice.is_empty()))
		# One primary self battler; extra cels (2+) remain deliberate copies.
		if self_targeted and pattern < 0 and slot < 2 and slot != self_body_slot:
			continue
		if effects_only and pattern < 0:
			continue
		var base_scale := minf(size.x / 512.0, size.y / 384.0)
		var pixel_scale := Vector2.ONE * base_scale
		var actor_offset := Vector2.ZERO
		if pattern < 0:
			var actor: Dictionary = _actors[clip.slot_sides[0 if pattern == -1 else 1]]
			sprite.texture = actor.texture
			sprite.region_rect = actor.region
			base_scale = float(actor.gain)
			pixel_scale = Vector2.ONE * base_scale
			actor_offset = actor.offset
		else:
			sprite.texture = textures[clip.sheet]
			var full := Rect2((pattern % 5) * 192, (pattern / 5) * 192, 192, 192)
			sprite.region_rect = full.intersection(Rect2(Vector2.ZERO, sprite.texture.get_size()))
			actor_offset = sprite.region_rect.get_center() - full.get_center()
			if int(cel[26]) == 4 and clip.get("target_scope") != "user" and not pattern in clip.get("uniform_screen_patterns", []):
				# Screen mosaics must share the affine camera's axis scale with their
				# positions. Uniform particle scale would open gaps between the tiles.
				pixel_scale = ((Vector2(_actors[clip.slot_sides[1]].center) - Vector2(_actors[clip.slot_sides[0]].center)) / (SOURCE_FRONT - SOURCE_BACK)).abs()
		sprite.offset = actor_offset
		# Some source projectiles travel between both canonical actors despite
		# carrying user-focus cells. Adapt their path (not their shape) when the
		# bounded battle binding explicitly requests it for our different camera.
		var position_focus := int(cel[26])
		if clip.get("_general_pose", "") == "clanging_scales" and slot == 1 and pattern == -2:
			# The source's stationary target track is erroneously tagged user-
			# local. Keep its own canonical origin, in either viewing direction.
			position_focus = 1
		if pattern >= 0 and position_focus == 1 and clip.get("_native_target_anchor", false):
			position_focus = 2
		if position_focus == 1:
			if clip.get("_native_projection", "") == "field_body" and slot == 0 and pattern == -1:
				# The uninvolved rear battler must stay at its own origin.
				position_focus = 2
			elif clip.get("_native_projection", "") == "shadow_path" and pattern >= 0:
				# The oval travels between actors; sparks are target-local.
				position_focus = 3 if pattern == 0 else 2
		if clip.get("_dash_user_path", false):
			# These complete source-screen runs intentionally exit and re-enter.
			# Adapt their path between actors, without scaling the battler shape
			# or clamping authored exits inside the screen (which exposes wraps).
			if pattern == (-2 if clip.opponent_export else -1):
				position_focus = 3
			elif clip.id == "take_down/front" and pattern >= 0 and position_focus == 1:
				# Native front impact stars are local to SOURCE_BACK, the target.
				position_focus = 2
		if (effects_only or not external_actor_layout.is_empty()) and affine_particle_path and pattern >= 0:
			position_focus = 3
		var point := Vector2(float(cel[0]), float(cel[1]))
		sprite.position = map_position(point, position_focus)
		if clip.get("_general_pose", "") == "court_change" and slot < 2 and pattern < 0:
			# Presentation only: the source's crossing metaphor must return the
			# battlers to their own places. It cannot leave the teams swapped.
			var home := Vector2(_actors[clip.slot_sides[0 if pattern == -1 else 1]].center)
			var settle := smoothstep(13.0, float(clip.frames.size() - 1), float(index))
			sprite.position = sprite.position.lerp(home, settle)
		if clip.get("_local_effect", "") == "entrainment" and pattern == -2:
			# Preserve the dance's X, rising steps and timing. Fit only the
			# source's 80px downward excursion to the rear actor's headroom.
			var recipient: Dictionary = _actors[clip.slot_sides[1]]
			var descent := sprite.position.y - float(recipient.center.y)
			if descent > 0.0:
				var room := maxf(0.0, size.y - 8.0 - float(recipient.center.y) - float(recipient.half_height))
				var limit := clampf(room / (80.0 * minf(size.x / 512.0, size.y / 384.0)), 0.0, 1.0)
				sprite.position.y = float(recipient.center.y) + descent * limit
		var beam_target_x := float(clip.get("_beam_target_source_x", 0.0))
		if pattern >= 0 and position_focus == 3 and beam_target_x > 0.0:
			var rear_x := float(_actors[clip.slot_sides[0]].center.x)
			var forward_x := float(_actors[clip.slot_sides[1]].center.x)
			sprite.position.x = rear_x + (point.x - beam_target_x) / (SOURCE_FRONT.x - beam_target_x) * (forward_x - rear_x)
		# A previous clip may have used an affine (skewed) beam basis in this slot.
		# Never let that basis leak into an unrelated particle or actor.
		if sprite.skew != 0.0:
			sprite.skew = 0.0
		sprite.rotation = -deg_to_rad(float(cel[3])) * (-1.0 if clip.get("mapped_opponent", false) else 1.0)
		sprite.scale = Vector2(float(cel[2]), float(cel[11])) * pixel_scale / 100.0
		if pattern >= 0 and pattern in clip.get("affine_particle_patterns", []):
			# Transform the WHOLE source particle, not just its center. Otherwise
			# an oblique ray drifts away from the target when our camera changes.
			var axis := (Vector2(_actors[clip.slot_sides[1]].center) - Vector2(_actors[clip.slot_sides[0]].center)) / (SOURCE_FRONT - SOURCE_BACK)
			var angle := -deg_to_rad(float(cel[3]))
			var x_basis := Vector2(cos(angle), sin(angle)) * (float(cel[2]) / 100.0) * axis
			var y_basis := Vector2(-sin(angle), cos(angle)) * (float(cel[11]) / 100.0) * axis
			sprite.transform = Transform2D(x_basis, y_basis, sprite.position)
		sprite.flip_h = (int(cel[4]) != 0) != (pattern >= 0 and bool(clip.get("mapped_opponent", false)))
		(sprite.material as ShaderMaterial).shader = _blend_shaders[int(cel[5])]
		sprite.z_index = _priority(int(cel[25]), int(cel[26]), pattern, slot)
		var tint_cel := cel
		if clip.get("_local_effect", "") == "acupressure" and pattern < 0 and slot < 2:
			# LAB self-use reference for this user-or-ally move: the finger
			# already marks the user. Transfer its paired flash to that user.
			# This does not implement an ally recipient or battle stat changes.
			tint_cel = frame[1 - slot]
		var render_opacity := float(cel[8])
		if clip.get("_dash_user_path", false) and pattern == (-2 if clip.opponent_export else -1):
			render_opacity *= _dash_visibility_weight(index)
		if clip.get("_z_fit_leap", false) and slot == 0 and cel[0] > SOURCE_FRONT.x:
			_fit_z_leap(sprite, cel)
		_tint(sprite, tint_cel.slice(12, 16), tint_cel.slice(16, 20), render_opacity)
		sprite.show()
	for layer: String in ["back", "front"]:
		if not effects_only and (external_actor_layout.is_empty() or String(clip.layers[index][layer].name) in external_layer_names):
			_show_layer(layer, clip.layers[index][layer])
	return true


func _fit_z_leap(sprite: Sprite2D, cel: Array) -> void:
	# Only the pinned Marshadow-Z user's emergence beyond the target. Preserve
	# timing, source fades, scales and target/particle paths. Fit the visible
	# battler bounds, not the transparent padding of its sprite sheet.
	var actor: Dictionary = _actors[clip.slot_sides[0]]
	var target := Vector2(_actors[clip.slot_sides[1]].center)
	var delta := sprite.position - target
	var half := Vector2(actor.half_width, actor.half_height) * Vector2(cel[2], cel[11]).abs() / 100.0
	target = target.clamp(half + Vector2.ONE * 8.0, size - half - Vector2.ONE * 8.0)
	for axis in 2:
		var room: float = size[axis] - 8.0 - half[axis] - target[axis] if delta[axis] >= 0.0 else target[axis] - 8.0 - half[axis]
		if absf(delta[axis]) > 0.0:
			delta[axis] *= clampf(room / absf(delta[axis]), 0.0, 1.0)
	sprite.position = target + delta


func _dash_visibility_weight(index: int) -> float:
	# Pinned exports jump between offscreen endpoints. Large modern sprites
	# can still touch the edge there; fade only that authored wrap, never the
	# contact phase, so no part of the body teleports visibly across the arena.
	if clip.move_id == "rock_climb":
		return 0.0 if index >= 20 and index <= 24 else 0.5 if index in [19, 25] else 1.0
	return 0.0 if index >= 9 and index <= 13 else 0.5 if index in [8, 14] else 1.0


func _self_body_slot(frame: Array) -> int:
	# OppMove swaps canonical roles. Some source animations (e.g. Lunar Dance)
	# author the other track instead, or alternate tracks (Bide). Never keep an
	# idle default over an authored pose/tint/fade. If both are authored, retain
	# the export's user track. This is a bounded camera-adapter policy, not a
	# claim that two source battler cells are independent Pokemon in a self move.
	var preferred := 1 if clip.opponent_export else 0
	if frame.size() < 2:
		return preferred
	if not _authored_body_pose(frame[preferred], preferred) and _authored_body_pose(frame[1 - preferred], 1 - preferred):
		return 1 - preferred
	return preferred


func _authored_body_pose(cel: Variant, slot: int) -> bool:
	if cel == null:
		return true
	var origin := SOURCE_BACK if slot == 0 else SOURCE_FRONT
	if not Vector2(cel[0], cel[1]).is_equal_approx(origin):
		return true
	for field: int in [2, 3, 4, 5, 6, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19]:
		var baseline := 100.0 if field in [2, 11] else 255.0 if field == 8 else 1.0 if field == 6 else 0.0
		if not is_equal_approx(float(cel[field]), baseline):
			return true
	return false


func _actor(species: StringName, side: String) -> Dictionary:
	if external_actor_layout.has(side): return external_actor_layout[side]
	var animation: Dictionary = Catalog.animation(species, side)
	if animation.is_empty():
		return {}
	# Fixed idle frame for a reproducible effect comparison, not a new species pose.
	var r: Array = animation.regions[0]
	var region := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	var bounds := Catalog.presentation_bounds(species, side, animation)
	var placement := Layout.placement(size, side, bounds)
	var gain := float(placement.gain) * float(animation.unit_scale)
	var center := Vector2(placement.anchor) + bounds.get_center() * float(placement.gain)
	var full_center := Vector2(placement.anchor) + (region.size * 0.5 - Vector2(animation.pivot)) * gain
	return {"texture": animation.texture, "region": region, "gain": gain, "center": center,
		"offset": (full_center - center) / gain, "half_width": bounds.size.x * float(placement.gain) * 0.5, "half_height": bounds.size.y * float(placement.gain) * 0.5}


func map_position(point: Vector2, focus: int) -> Vector2:
	if focus == 4 and clip.get("target_scope") == "user":
		# Screen-space objects do not use the user-target line. That line has
		# zero length for self moves; collapsing it hid Wish/Substitute sprites.
		var screen_gain := minf(size.x / 512.0, size.y / 384.0)
		return (size - Vector2(512, 384) * screen_gain) / 2.0 + point * screen_gain
	var back := Vector2(_actors[clip.slot_sides[0]].center)
	var front := Vector2(_actors[clip.slot_sides[1]].center)
	var scale_unit := minf(size.x / 512.0, size.y / 384.0)
	var reflection := Vector2(-1, 1) if clip.get("mapped_opponent", false) else Vector2.ONE
	if focus == 1:
		return front + (point - SOURCE_FRONT) * scale_unit * reflection
	if focus == 2:
		return back + (point - SOURCE_BACK) * scale_unit * reflection
	# Fixed camera adaptation for screen/two-focus cells. OppMove exports keep
	# canonical slots back/front: they already contain opposite-side choreography.
	return back + (point - SOURCE_BACK) / (SOURCE_FRONT - SOURCE_BACK) * (front - back)


func _priority(priority: int, focus: int, pattern: int, slot: int) -> int:
	if slot < 2 and pattern < 0:
		return 30 if clip.slot_sides[0 if pattern == -1 else 1] == "back" else 20
	if priority == 0:
		return 10
	if priority == 1:
		return 80
	if not focus in [1, 2]:
		return 20 if priority == 2 else 80
	var z := 30 if clip.slot_sides[1 if focus == 1 else 0] == "back" else 20
	return z - 1 if priority == 2 else z + 1


func _tint(sprite: Sprite2D, color: Array, tone: Array, opacity: float) -> void:
	var material := sprite.material as ShaderMaterial
	material.set_shader_parameter("overlay", Color(float(color[0]) / 255.0, float(color[1]) / 255.0, float(color[2]) / 255.0, float(color[3]) / 255.0))
	material.set_shader_parameter("tone", Vector4(float(tone[0]), float(tone[1]), float(tone[2]), float(tone[3])) / 255.0)
	material.set_shader_parameter("opacity", opacity / 255.0)


func _show_layer(layer: String, row: Dictionary) -> void:
	var sprite: Sprite2D = _layers[layer]
	# From f12 the underwater transition needs the original wrapped water fill.
	# Suppress only its premature appearance before the main crest has entered.
	(sprite.material as ShaderMaterial).shader = _water_primary_shader if layer == "front" and current_frame < 12 and clip.get("_hydro_primary_only", false) and row.name == "PRAS- Surf FG Opp.png" else TintShader
	if float(row.opacity) <= 0.0 or (String(row.name).is_empty() and float(row.colorAlpha) <= 0.0):
		return
	var solid: bool = String(row.name).is_empty()
	sprite.texture = _white if solid else textures[clip.layer_sheets[row.name]]
	var gain := minf(size.x / 512.0, size.y / 384.0)
	sprite.scale = Vector2.ONE * gain
	sprite.region_rect = Rect2(Vector2(-float(row.bgX), -float(row.bgY)), size / gain)
	_tint(sprite, [row.colorRed, row.colorGreen, row.colorBlue, 255 if solid else row.colorAlpha], [0, 0, 0, 0], float(row.opacity) * (float(row.colorAlpha) / 255.0 if solid else 1.0))
	sprite.show()


func visible_cells() -> int:
	var count := 0
	for sprite: Sprite2D in _sprites:
		if sprite.visible:
			count += 1
	return count
