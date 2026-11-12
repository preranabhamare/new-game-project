class_name OutpostDataSources
extends RefCounted

## All fact cards below cite sources fetched during implementation. Game tuning
## remains explicitly labeled as an exaggeration or placeholder where applicable.
const ARCHIVED_SOLAR_EVENTS := [
	{"date": "2017-09-06", "class": "X9.3", "name": "Historic solar flare", "mars_note": "A Sun event is not automatically a Mars surface event; this replay is for learning, not a Mars-impact claim.",
		"url": "https://api.nasa.gov/DONKI/FLR?startDate=2017-09-06&endDate=2017-09-06&api_key=DEMO_KEY", "event_id": "2017-09-06T11:53:00-FLR-001"},
]

const RECORDS := [
	{"name": "Mars solar day", "drives": "Sol clock explanation", "label": "Real data", "status": "Archived", "fact": "A mean Mars solar day is 24 hours, 39 minutes, 35.244 seconds.", "url": "https://www.giss.nasa.gov/tools/mars24/help/notes.html"},
	{"name": "Earth-Mars signal delay", "drives": "Antenna message flavor countdown", "label": "Real data; countdown is an estimate", "status": "Archived source", "fact": "One-way light time varies with the planets' distance; NASA gives about 3 to 22 minutes.", "url": "https://science.nasa.gov/mars/mars-relay-network/"},
	{"name": "DONKI solar-flare archive", "drives": "Historic Replay", "label": "Real event; not a guaranteed Mars impact", "status": "Archived", "fact": "The September 6, 2017 flare peaked at X9.3. A flare facing Earth may miss Mars.", "url": "https://api.nasa.gov/DONKI/FLR?startDate=2017-09-06&endDate=2017-09-06&api_key=DEMO_KEY"},
	{"name": "Perseverance MEDA", "drives": "Jezero temperature and dust cards", "label": "Real data source; rates exaggerated in game mode", "status": "Archived source description", "fact": "MEDA measures temperature, wind, humidity, and atmospheric dust at Jezero. No single average is used as a forecast here.", "url": "https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/"},
	{"name": "Curiosity RAD", "drives": "Dose lesson and Real Mars mode", "label": "Real measurement; game dose is exaggerated", "status": "Archived", "fact": "Curiosity measured an average surface dose equivalent near 0.67 mSv per day during the reported 2012-2013 interval.", "url": "https://www.nasa.gov/news-release/nasa-rover-results-include-first-age-measurement-on-mars-and-help-for-human-exploration/"},
	{"name": "Opportunity and the 2018 global storm", "drives": "Historic storm lesson", "label": "Real mission event; storm timing exaggerated", "status": "Archived", "fact": "A large 2018 dust storm reduced sunlight so much that Opportunity could not recharge.", "url": "https://astrobiology.nasa.gov/news/opportunity-rover-mission-comes-to-an-end/"},
	{"name": "Spirit and Opportunity panel cleanings", "drives": "Dust-devil teaching card", "label": "Real mission observations; cleaning chance exaggerated", "status": "Archived", "fact": "Unpredictable wind events sometimes cleaned the rovers' solar panels.", "url": "https://science.nasa.gov/photojournal/solar-panel-dust-accumulation-and-cleanings/"},
	{"name": "Outpost power rates", "drives": "Solar output, storm losses, and panel-dust game rates", "label": "UNVERIFIED / placeholder", "status": "Game tuning", "fact": "These rates are play values, not engineering predictions. Switch Real Mars mode to use the separate reference preset; panel-specific ratings still need hardware sources.", "url": ""},
	{"name": "OSDR crew and plant science cards", "drives": "Research unlocks", "label": "Not yet curated", "status": "No local archive", "fact": "No OSDR findings are shown until each card has a verified source and kid-friendly summary.", "url": "https://osdr.nasa.gov/"},
]

static func donki_flare_url(start_date: String, end_date: String, api_key: String = "DEMO_KEY") -> String:
	return "https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s" % [start_date.uri_encode(), end_date.uri_encode(), api_key.uri_encode()]

static func live_api_key() -> String:
	var configured := OS.get_environment("NASA_API_KEY").strip_edges()
	return configured if not configured.is_empty() else "DEMO_KEY"
