class_name OutpostPlacementRules
extends RefCounted

const Grid = preload("res://simulation/power_grid.gd")
const MissionState = preload("res://simulation/mission_state.gd")
const Tuning = preload("res://simulation/tuning.gd")

## Read-only validation for the Godot placement ghost. terrain_kind is queried from World.gd.
static func validate(state: MissionState, tile: Vector2i, kind: String, terrain_kind: String, explored: bool = true, tuning: Dictionary = {}) -> Dictionary:
	var t: Dictionary = tuning if not tuning.is_empty() else Tuning.preset()
	if tile.x < 0 or tile.y < 0 or tile.x >= 64 or tile.y >= 64:
		return {"valid": false, "reason": "outside the map"}
	if terrain_kind == "cliff_ridge":
		return {"valid": false, "reason": "cliff"}
	if not explored:
		return {"valid": false, "reason": "unexplored"}
	for building: Dictionary in state.buildings:
		if building.get("tile", Vector2i(-1, -1)) == tile:
			return {"valid": false, "reason": "overlaps another building"}
	for panel: Dictionary in state.solar_arrays:
		if panel.get("tile", Vector2i(-1, -1)) == tile:
			return {"valid": false, "reason": "overlaps another building"}
	for battery: Dictionary in state.batteries:
		if battery.get("tile", Vector2i(-1, -1)) == tile:
			return {"valid": false, "reason": "overlaps another building"}
	for pole: Dictionary in state.poles:
		if pole.get("tile", Vector2i(-1, -1)) == tile:
			return {"valid": false, "reason": "overlaps another building"}
	var grid: Dictionary = Grid.compute_grid(state, t)
	var energized: Array = grid["energized_poles"]
	if kind == "power_pole":
		var spec: Dictionary = t["pole_tiers"][1]
		for pole: Dictionary in state.poles:
			if not energized.has(int(pole.get("id", -1))): continue
			var distance := Vector2(tile).distance_to(Vector2(pole.get("tile", Vector2i.ZERO)))
			if distance <= minf(float(spec["radius"]), float(pole.get("radius", 0.0))):
				return {"valid": true, "reason": "connected to the grid"}
		for panel: Dictionary in state.solar_arrays:
			if Grid.solar_generation(state, t) > 0.0 and Vector2(tile).distance_to(Vector2(panel.get("tile", Vector2i.ZERO))) <= float(spec["radius"]):
				return {"valid": true, "reason": "connected to solar power"}
		for battery: Dictionary in state.batteries:
			if float(battery.get("charge", 0.0)) > 0.0 and Vector2(tile).distance_to(Vector2(battery.get("tile", Vector2i.ZERO))) <= float(spec["radius"]):
				return {"valid": true, "reason": "connected to a battery"}
		return {"valid": false, "reason": "not powered"}
	for pole_id: int in energized:
		for pole: Dictionary in state.poles:
			if int(pole.get("id", -1)) != pole_id: continue
			if Vector2(tile).distance_to(Vector2(pole.get("tile", Vector2i.ZERO))) <= float(pole.get("radius", 0.0)):
				return {"valid": true, "reason": "inside an energized pole radius"}
	return {"valid": false, "reason": "not powered"}
