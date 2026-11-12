class_name OutpostStorySystem
extends RefCounted

const State = preload("res://simulation/mission_state.gd")
const Tuning = preload("res://simulation/tuning.gd")
const Grid = preload("res://simulation/power_grid.gd")
const Hazards = preload("res://simulation/hazards.gd")

const CREW := {"scientist": "Dr. P", "commander": "Commander S"}
const CHAPTERS := [
	{"id": "landing", "name": "Landing", "from": 1, "to": 4, "lesson": "Your first supplies and safe shelter matter."},
	{"id": "first_power", "name": "First Power / First Night", "from": 5, "to": 9, "lesson": "Power made in the day must last through the night."},
	{"id": "dust", "name": "Dust", "from": 10, "to": 14, "lesson": "Dust in the sky and dust on panels have different effects."},
	{"id": "findings", "name": "First Findings", "from": 15, "to": 19, "lesson": "Samples unlock research, but the lab needs power and crew time."},
	{"id": "storm", "name": "The Storm", "from": 20, "to": 26, "lesson": "A storm trades sunlight for time to protect the outpost."},
	{"id": "handover", "name": "Handover", "from": 27, "to": 30, "lesson": "The next crew inherits the choices you made."},
]
const DILEMMAS := {
	"panel_field": [
		{"id": "near", "option": "Build nearby", "deltas": {"materials": -6.0, "crew_hours": -2.0}, "legacy_tags": ["easy_to_repair"]},
		{"id": "far", "option": "Build farther into sunlight", "deltas": {"earth_parts": -1.0, "dose": 0.1}, "legacy_tags": ["more_sun"]},
		{"id": "delay", "option": "Wait and keep the stores", "deltas": {"power": -8.0, "food": -0.1}, "legacy_tags": ["saved_parts"]},
	],
	"storm_prep": [
		{"id": "clean", "option": "Clean panels now", "deltas": {"crew_hours": -3.0, "dose": 0.1}, "legacy_tags": ["cleaned_before_storm"]},
		{"id": "save_time", "option": "Save crew time", "deltas": {"materials": -2.0, "power": -5.0}, "legacy_tags": ["saved_crew_for_storm"]},
		{"id": "shelter", "option": "Practice the shelter drill", "deltas": {"food": -0.15, "crew_hours": -1.0}, "legacy_tags": ["shelter_ready"]},
	],
	"science_or_food": [
		{"id": "lab", "option": "Keep the lab running", "deltas": {"power": -10.0, "food": 0.15}, "legacy_tags": ["science_first"]},
		{"id": "greenhouse", "option": "Keep the greenhouse running", "deltas": {"food": 0.3, "materials": -2.0}, "legacy_tags": ["food_first"]},
		{"id": "share", "option": "Share power and slow both", "deltas": {"crew_hours": -1.0, "power": -5.0}, "legacy_tags": ["balanced_science"]},
	],
}

static func chapter_for_sol(sol: int) -> Dictionary:
	for chapter: Dictionary in CHAPTERS:
		if sol >= int(chapter["from"]) and sol <= int(chapter["to"]): return chapter.duplicate(true)
	return {}

static func options_for(dilemma_id: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for option: Dictionary in DILEMMAS.get(dilemma_id, []): items.append(option.duplicate(true))
	return items

static func choose_action(dilemma_id: String, option_id: String) -> Dictionary:
	for option: Dictionary in DILEMMAS.get(dilemma_id, []):
		if str(option["id"]) == option_id:
			var action_data := Grid.event_choice_as_action(option)
			action_data["option"] = str(option["option"])
			return action_data
	return {"type": "event_choice", "choice_id": option_id, "cost": {}}

static func handover_report(state: State) -> Dictionary:
	var grid: Dictionary = Grid.compute_grid(state)
	var battery_capacity := 0.0
	for battery: Dictionary in state.batteries: battery_capacity += float(battery.get("capacity", 0.0))
	var explored := int(state.flags.get("explored_tiles", 0))
	var ratings := {
		"power capacity": battery_capacity,
		"shielding": _average_shielding(state),
		"research completed": state.flags.get("research", {}).get("completed", []).size(),
		"area explored": explored,
		"local production": float(state.bulk_regolith_tonnes),
		"stores left": {"air": state.air, "water": state.water, "food": state.food},
		"powered buildings": grid["powered_buildings"].size(),
	}
	var decisions := state.decision_ledger.duplicate(true)
	decisions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return absf(Grid.total_cost({"cost": a.get("immediate_effects", {})})) > absf(Grid.total_cost({"cost": b.get("immediate_effects", {})})))
	var influential: Array[Dictionary] = []
	for i in mini(3, decisions.size()): influential.append(decisions[i])
	return {"ratings": ratings, "influential_decisions": influential,
		"next_crew_requests": state.flags.get("handover_requests", []).duplicate(true), "seed": state.mission_seed,
		"learned": "Your crew learned how choices about power, stores, shelter, and science shape the next Sol."}

static func retry_with_new_seed(state: State, tuning: Dictionary = {}) -> State:
	var new_state: State = State.create_default(tuning if not tuning.is_empty() else Tuning.preset())
	var next_seed := int(posmod(state.mission_seed * 1103515245 + 12345, 2147483647))
	if next_seed == state.mission_seed: next_seed += 1
	new_state.mission_seed = next_seed
	new_state.hazard_schedule = Hazards.schedule_for_seed(next_seed)
	new_state.flags["retry_of_seed"] = state.mission_seed
	return new_state

static func _average_shielding(state: State) -> float:
	if state.buildings.is_empty(): return 0.0
	var total := 0.0
	for building: Dictionary in state.buildings: total += float(building.get("shielding", 0))
	return total / float(state.buildings.size())
