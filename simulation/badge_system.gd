class_name OutpostBadgeSystem
extends RefCounted

const State = preload("res://simulation/mission_state.gd")
const BADGES := [
	{"id":"first_light","name":"First Light","family":"story","fact":"Sunlight powers solar panels; the outpost stores extra energy for night."},
	{"id":"foothold","name":"Foothold","family":"story","fact":"Mars days are called sols."},
	{"id":"storm_rider","name":"Storm Rider","family":"story","fact":"Dust storms can block sunlight from solar panels."},
	{"id":"handover","name":"Handover","family":"story","fact":"A mission handover records what the next crew inherits."},
	{"id":"zone_planner","name":"Zone Planner","family":"planning","fact":"Power poles can pass electricity from one energized pole to another."},
	{"id":"triage","name":"Triage","family":"planning","fact":"A power grid can protect critical loads by shedding lower-priority work."},
	{"id":"reserve_keeper","name":"Reserve Keeper","family":"planning","fact":"A battery reserve is a protected safety margin."},
	{"id":"right_place","name":"Right Place","family":"planning","fact":"Where a solar array sits changes how it connects to nearby buildings."},
	{"id":"first_sample","name":"First Sample","family":"science","fact":"Rover samples can help scientists study Mars rocks and soils."},
	{"id":"clay_detective","name":"Clay Detective","family":"science","fact":"Clay minerals can form when rock interacts with water."},
	{"id":"sky_scout","name":"Sky Scout","family":"science","fact":"Weather stations measure conditions such as wind and dust."},
	{"id":"stuck_and_free","name":"Stuck and Free","family":"science","fact":"Rovers can get stuck in soft sand and need a careful recovery plan."},
	{"id":"learned_hard_way","name":"Learned the Hard Way","family":"resilience","fact":"Engineering teams learn from failures and update their plans."},
	{"id":"comeback","name":"Comeback","family":"resilience","fact":"A repaired system can return to useful work."},
	{"id":"safe_mode_survivor","name":"Safe Mode Survivor","family":"resilience","fact":"Spacecraft use safe modes to protect systems when something goes wrong."},
	{"id":"second_try","name":"Second Try","family":"resilience","fact":"A new plan can start with a new mission seed."},
	{"id":"luckygust","name":"Lucky Gust","family":"real_events","fact":"Wind events unexpectedly cleaned Spirit and Opportunity's solar panels."},
	{"id":"opportunity_lesson","name":"Opportunity's Lesson","family":"real_events","fact":"A 2018 dust storm reduced sunlight reaching Opportunity's solar panels."},
	{"id":"particle_storm","name":"Particle Storm","family":"real_events","fact":"Solar particle events can affect electronics and crew radiation exposure."},
	{"id":"gift_to_next_crew","name":"Gift to the Next Crew","family":"legacy","fact":"A careful handover helps the next team plan their work."},
	{"id":"self_sufficient","name":"Self-Sufficient","family":"legacy","fact":"Local resources can support future work, but some electronics still need Earth parts."},
	{"id":"foundation_builder","name":"Foundation Builder","family":"legacy","fact":"Infrastructure choices shape what later crews can build."},
	{"id":"three_ways","name":"Three Ways to Survive","family":"variety","fact":"A resilient outpost uses several systems to meet its needs."},
	{"id":"fast_and_careful","name":"Fast and Careful","family":"variety","fact":"Planning can save resources while keeping people safe.","hidden":true},
]

static func earned_for_state(state: State) -> Array[String]:
	var earned: Array[String] = []
	if state.sol >= 1: earned.append("foothold")
	if state.sol >= 30: earned.append_array(["handover", "gift_to_next_crew"])
	if not state.solar_arrays.is_empty() and float(state.solar_arrays[0].get("dust", 0.0)) < 0.5: earned.append("first_light")
	if state.flags.get("research", {}).get("completed", []).size() > 0: earned.append("first_sample")
	if bool(state.flags.get("safe_mode", false)): earned.append("particle_storm")
	if bool(state.flags.get("storm_survived", false)): earned.append("storm_rider")
	if state.flags.get("handover_requests", []).size() > 0: earned.append("gift_to_next_crew")
	return earned

static func save_earned(earned: Array[String]) -> void:
	var config := ConfigFile.new()
	config.load("user://outpost_badges.cfg")
	var saved: Array = config.get_value("badges", "earned", [])
	for badge_id: String in earned:
		if not saved.has(badge_id): saved.append(badge_id)
	config.set_value("badges", "earned", saved)
	config.save("user://outpost_badges.cfg")

static func load_earned() -> Array[String]:
	var result: Array[String] = []
	var config := ConfigFile.new()
	if config.load("user://outpost_badges.cfg") == OK:
		for badge_id: Variant in config.get_value("badges", "earned", []): result.append(str(badge_id))
	return result

static func mission_patch_svg(mission_seed: int, earned: Array[String], layout: String) -> String:
	var badges := ", ".join(earned)
	var safe_layout := layout.xml_escape()
	var safe_badges := badges.xml_escape()
	return "<svg xmlns='http://www.w3.org/2000/svg' width='640' height='400' viewBox='0 0 640 400'><rect width='640' height='400' rx='32' fill='#0e2535'/><path d='M320 55 470 120 440 300 320 350 200 300 170 120Z' fill='#c95735' stroke='#f7d38a' stroke-width='8'/><circle cx='320' cy='195' r='68' fill='#f7d38a'/><text x='320' y='205' text-anchor='middle' font-size='26' font-family='sans-serif' fill='#253443'>OZ</text><text x='320' y='372' text-anchor='middle' font-size='18' font-family='sans-serif' fill='white'>Sol seed %d · %s · %s</text></svg>" % [mission_seed, safe_layout, safe_badges]

static func write_mission_patch(mission_seed: int, earned: Array[String], layout: String) -> String:
	var path := "user://mission_patch.svg"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ""
	file.store_string(mission_patch_svg(mission_seed, earned, layout))
	return path
