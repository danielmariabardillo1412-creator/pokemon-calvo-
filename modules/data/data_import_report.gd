class_name DataImportReport
extends RefCounted

# Collects validation issues and a human-readable summary for the pipeline.
var issues: Array[DataValidationIssue] = []

# Roll-up counters for the required report format.
var species_imported := 0
var moves_imported := 0
var abilities_imported := 0
var items_imported := 0
var statuses_imported := 0
var evolutions_count := 0
var broken_references: Array[String] = []
var rejected: Array[String] = []
var unsupported_mechanics := []

func add_issue(code: String, message: String, context: Dictionary = {}) -> void:
	issues.append(DataValidationIssue.new(code, message, context))

func has_errors() -> bool:
	for i in issues:
		if i.code != "warning":
			return true
	return false

func error_count() -> int:
	var n := 0
	for i in issues:
		if i.code != "warning":
			n += 1
	return n

func to_text() -> String:
	var lines := PackedStringArray()
	lines.append("ESPECIES IMPORTADAS: %d" % species_imported)
	lines.append("MOVIMIENTOS: %d" % moves_imported)
	lines.append("HABILIDADES: %d" % abilities_imported)
	lines.append("OBJETOS: %d" % items_imported)
	lines.append("ESTADOS: %d" % statuses_imported)
	lines.append("EVOLUCIONES: %d" % evolutions_count)
	lines.append("REFERENCIAS ROTAS: %s" % (", ".join(broken_references) if not broken_references.is_empty() else "ninguna"))
	lines.append("REGISTROS RECHAZADOS: %s" % (", ".join(rejected) if not rejected.is_empty() else "ninguno"))
	lines.append("MECÁNICAS TODAVÍA NO SOPORTADAS: %s" % (", ".join(unsupported_mechanics) if not unsupported_mechanics.is_empty() else "ninguna"))
	return "\n".join(lines)
