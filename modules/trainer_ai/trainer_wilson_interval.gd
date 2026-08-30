class_name TrainerWilsonInterval
extends RefCounted

# Offline benchmark statistic. Basis-point output keeps reports compact and stable.
# z=1.96 is the conventional two-sided 95% Wilson score interval.
const Z_95 := 1.96


static func calculate(successes: int, trials: int, z: float = Z_95) -> Dictionary:
	var n := maxi(0, trials)
	var s := clampi(successes, 0, n)
	if n <= 0:
		return {
			"successes": s,
			"trials": n,
			"estimate_basis_points": 0,
			"lower_basis_points": 0,
			"upper_basis_points": 10000,
			"confidence_percent": 95,
			"method": "wilson_score_v1",
		}
	var p := float(s) / float(n)
	var z2 := z * z
	var denominator := 1.0 + z2 / float(n)
	var center := (p + z2 / (2.0 * float(n))) / denominator
	var margin := z * sqrt(
		(p * (1.0 - p) / float(n)) + (z2 / (4.0 * float(n) * float(n)))
	) / denominator
	return {
		"successes": s,
		"trials": n,
		"estimate_basis_points": clampi(int(round(p * 10000.0)), 0, 10000),
		"lower_basis_points": clampi(int(round((center - margin) * 10000.0)), 0, 10000),
		"upper_basis_points": clampi(int(round((center + margin) * 10000.0)), 0, 10000),
		"confidence_percent": 95,
		"method": "wilson_score_v1",
	}
