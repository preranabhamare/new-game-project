class_name OutpostHazards
extends RefCounted

## All hazard schedules are generated from the mission seed. Numeric gameplay
## effects in this file are placeholders until replaced with cited Mars data.
const STORM_FACTORS := {"hazy": 0.72, "orange": 0.48, "dark": 0.24} # Placeholder play values.

static func schedule_for_seed(mission_seed: int, campaign_sols: int = 30) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = mission_seed
	var events: Array[Dictionary] = []
	var first_start := rng.randi_range(10, 12)
	events.append({"type": "regional_storm", "start_sol": first_start, "end_sol": mini(campaign_sols, first_start + rng.randi_range(1, 2)), "stage": "hazy"})
	var second_start := rng.randi_range(20, 22)
	events.append({"type": "global_storm", "start_sol": second_start, "end_sol": mini(campaign_sols, second_start + rng.randi_range(2, 3)), "stage": "dark"})
	var flare_sol := rng.randi_range(6, maxi(6, campaign_sols - 4))
	events.append({"type": "solar_particle_event", "start_sol": flare_sol, "end_sol": flare_sol, "stage": "particle_event"})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["start_sol"]) < int(b["start_sol"]))
	return events

static func weather_for_sol(state: Variant) -> Dictionary:
	var result := {"storm_light_factor": 1.0, "dust_per_sol": 0.03, "sky_dust": 0.0, "stage": "clear", "warning": "", "dust_devil_clean": 0.12}
	var station_powered := false
	var grid: Dictionary = load("res://simulation/power_grid.gd").compute_grid(state)
	station_powered = grid["powered_buildings"].has("weather_station")
	for event: Dictionary in state.hazard_schedule:
		var start := int(event.get("start_sol", 999))
		var end := int(event.get("end_sol", start))
		if state.sol < start or state.sol > end:
			continue
		if str(event.get("type", "")).ends_with("storm"):
			var span := maxi(1, end - start + 1)
			var step := int(floor(float(state.sol - start) * 3.0 / float(span)))
			var stage: String = ["hazy", "orange", "dark"][clampi(step, 0, 2)]
			result["stage"] = stage
			result["storm_light_factor"] = float(STORM_FACTORS[stage])
			result["sky_dust"] = 1.0 - float(STORM_FACTORS[stage])
			result["dust_per_sol"] = 0.03 * 1.8 # Placeholder: storm settling multiplier.
			result["warning"] = "Storm warning: %s skies" % stage if station_powered else "Late warning from Earth: a dust storm is nearby."
			break
	return result

static func events_for_sol(state: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in state.hazard_schedule:
		if int(event.get("start_sol", -1)) == state.sol:
			result.append(event.duplicate(true))
	return result

static func process_sol_start(state: Variant, changes: Array[Dictionary]) -> void:
	for event: Dictionary in events_for_sol(state):
		var kind := str(event.get("type", ""))
		if kind.ends_with("storm"):
			var weather := weather_for_sol(state)
			changes.append({"cause": "dust_storm", "detail": str(weather["warning"])})
		elif kind == "solar_particle_event" and not bool(state.flags.get("solar_event_recovered", false)):
			state.flags["safe_mode"] = true
			state.flags["sensor_saturated"] = true
			for building: Dictionary in state.buildings:
				if str(building.get("type", "")) in ["laboratory", "weather_station", "antenna"]:
					building["faulted"] = true
					building["solar_event_fault"] = true
			if int(state.flags.get("crew_sheltered_sol", -1)) != state.sol:
				state.dose += 0.2 # Placeholder gameplay dose; outdoor exposure is intentionally exaggerated.
			changes.append({"cause": "solar_particle_event", "detail": "Solar particles reset electronics. Systems need crew time to recover."})

static func panel_dust_rate(weather: Dictionary, tuning: Dictionary) -> float:
	return float(weather.get("dust_per_sol", tuning.get("dust_per_sol", 0.03)))
