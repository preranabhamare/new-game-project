class_name OutpostResearchSystem
extends RefCounted

const State = preload("res://simulation/mission_state.gd")

## Gameplay costs and durations are placeholders. Science cards require sourced
## references before any Mars fact is presented as real.
const NODES := {
	"P1": {"name": "Tilted panels", "branch": "Power", "sample": "basalt and rock", "sols": 2, "unlocks": "dust_shedding_panels"},
	"P2": {"name": "Dust shield", "branch": "Power", "sample": "regolith", "prereq": ["P1"], "sols": 3, "unlocks": "panel_shield"},
	"P3": {"name": "Fission power", "branch": "Power", "sample": "regolith", "prereq": ["P2"], "sols": 3, "unlocks": "fission_cargo"},
	"A1": {"name": "CO2 to oxygen", "branch": "Air and Water", "sample": "atmosphere", "sols": 2, "unlocks": "oxygen_unit"},
	"A2": {"name": "Water from regolith", "branch": "Air and Water", "sample": "hydrated minerals", "prereq": ["A1"], "sols": 3, "unlocks": "regolith_water"},
	"A3": {"name": "High-recovery water loop", "branch": "Air and Water", "sample": "hydrated minerals", "prereq": ["A2"], "sols": 3, "unlocks": "water_loop"},
	"F1": {"name": "Greenhouse beds", "branch": "Food", "sample": "regolith", "sols": 2, "unlocks": "greenhouse_beds"},
	"F2": {"name": "Perchlorate washing", "branch": "Food", "sample": "salts and special minerals", "prereq": ["F1"], "sols": 3, "unlocks": "salt_washing"},
	"S1": {"name": "Regolith walls", "branch": "Shelter", "sample": "regolith", "sols": 2, "unlocks": "regolith_walls"},
	"S2": {"name": "Sintered bricks", "branch": "Shelter", "sample": "regolith", "prereq": ["S1"], "sols": 3, "unlocks": "sintered_bricks"},
	"E1": {"name": "Weather station", "branch": "Exploration and Comms", "sample": "atmosphere", "sols": 2, "unlocks": "weather_station"},
	"E2": {"name": "Curiosity-class upgrade", "branch": "Exploration and Comms", "sample": "basalt and rock", "prereq": ["E1"], "sols": 3, "unlocks": "curiosity_upgrade"},
}
const CAMPAIGN_SOLS := 30

static func state_data(state: State) -> Dictionary:
	if not state.flags.has("research"):
		state.flags["research"] = {"discovered": [], "completed": [], "project": {}}
	return state.flags["research"]

static func discover_from_sample(state: State, sample_type: String) -> Array[String]:
	var research: Dictionary = state_data(state)
	var found: Array[String] = []
	for node_id: String in NODES.keys():
		if str(NODES[node_id]["sample"]) == sample_type and not research["discovered"].has(node_id):
			research["discovered"].append(node_id)
			found.append(node_id)
	return found

static func discover_from_reading(state: State, reading: String) -> Array[String]:
	if reading.to_lower() == "atmosphere":
		return discover_from_sample(state, "atmosphere")
	return []

static func can_start(state: State, node_id: String) -> Dictionary:
	if not NODES.has(node_id): return {"ok": false, "reason": "unknown research"}
	var research: Dictionary = state_data(state)
	if not research["discovered"].has(node_id): return {"ok": false, "reason": "read or collect a matching sample first"}
	if not research["project"].is_empty(): return {"ok": false, "reason": "the lab can work on one project at a time"}
	for prerequisite: String in NODES[node_id].get("prereq", []):
		if not research["completed"].has(prerequisite): return {"ok": false, "reason": "finish %s first" % prerequisite}
	return {"ok": true, "reason": "ready"}

static func start_action(state: State, node_id: String) -> Dictionary:
	var validation: Dictionary = can_start(state, node_id)
	if not validation["ok"]: return {"type": "research_start", "target_id": node_id, "cost": {}, "reason": validation["reason"]}
	var node: Dictionary = NODES[node_id]
	return {"type": "research_start", "target_id": node_id, "sols": int(node["sols"]),
		"cost": {"crew_hours": 4.0, "power": 6.0, "materials": 2.0, "earth_parts": 1.0}}

static func advance_sol(state: State, lab_powered: bool, solar_event_corruption: bool = false) -> Dictionary:
	var research: Dictionary = state_data(state)
	var project: Dictionary = research["project"]
	if project.is_empty(): return {"advanced": false, "complete": false, "detail": "No research project is running."}
	if solar_event_corruption:
		project["progress_sols"] = 0
		return {"advanced": false, "complete": false, "detail": "A particle event corrupted the experiment; progress reset."}
	if not lab_powered:
		return {"advanced": false, "complete": false, "detail": "The lab was off, so research paused."}
	project["progress_sols"] = int(project.get("progress_sols", 0)) + 1
	if int(project["progress_sols"]) < int(project["required_sols"]):
		return {"advanced": true, "complete": false, "detail": "The lab made progress."}
	research["completed"].append(str(project["node_id"]))
	var node_id := str(project["node_id"])
	var unlock := str(NODES[node_id]["unlocks"])
	project.clear()
	state.flags["unlocks"] = state.flags.get("unlocks", [])
	state.flags["unlocks"].append(unlock)
	return {"advanced": true, "complete": true, "detail": "%s is ready. It unlocks %s." % [node_id, unlock]}

static func project_days_remaining(state: State) -> int:
	var research: Dictionary = state_data(state)
	var project: Dictionary = research["project"]
	if project.is_empty(): return 0
	return maxi(0, int(project.get("required_sols", 0)) - int(project.get("progress_sols", 0)))
