extends SceneTree
## Scene-independent authoring tool; no nodes, scenes, input bot or AI service.
## Uses the existing Transit scheduler and real sim bridge; outputs replay inputs.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for adversarial in [false, true]:
		var sim := SimBridge.new()
		sim.want_minor = 2
		sim.record_path = "res://tests/replays/m4_adversarial.ndjson" if adversarial else "res://tests/replays/m4_min_path.ndjson"
		sim.archive_rows = LoreLoader.archive_rows(LoreLoader.load_entries()["entries"])
		if not sim.start() or not sim.new_game(0, "sol", false, Transit.new_game_params()):
			push_error(sim.last_error)
			quit(1)
			return
		var targets := [TransitHarness.TARGET, {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}]
		for target in targets:
			var transit := Transit.new()
			if not sim.send([{"k": "plan", "target": target, "cruise_phi": 2.6466524123622457}], 0.0):
				quit(1)
				return
			var id: int = sim.world["journey"]["plan_id"]
			if not sim.send([{"k": "commit", "plan_id": id}], 0.0):
				quit(1)
				return
			if adversarial:
				var moving := transit.step(sim.world, 0.05)
				if not sim.send(moving["intents"], moving["dtau"]):
					quit(1)
					return
				transit.settle(sim.last_refused, 0)
				for intent in [{"k": "plan", "target": target, "cruise_phi": 2.6466524123622457}, {"k": "cancel"}, {"k": "commit", "plan_id": id}]:
					if not sim.send([intent], 0.0):
						quit(1)
						return
			var ticks := 0
			while Transit.is_committed(sim.world) and ticks < 10000:
				var step := transit.step(sim.world, 0.05)
				if not sim.send(step["intents"], step["dtau"]):
					quit(1)
					return
				transit.settle(sim.last_refused, 0)
				ticks += 1
			if sim.world["journey"]["state"] != "arrived":
				push_error("bounded transit did not arrive")
				quit(1)
				return
			print("m45 authored leg ticks=", ticks)
		# AC5: deterministic recorded response copied from existing stub replay.
		# Provider is never launched; recordResult validates the logged body/hash.
		if not sim.send([{"k":"ai_open","kind":"text","purpose":"line","entity_id":"medic","emotions":["neutral","loving","grieving"],"context":{"topic":"first_night_aboard"}}], 0.0) or not sim.send([{"k":"record","source":"ai","req":"1","kind":"text","sha256":"c1638e8d302827381672649e34fe84b6d091f6578ae69fe5c6d31defae803bc0","body":"{neutral} Stub line one for medic."}], 0.0):
			quit(1)
			return
		sim.stop()
	quit(0)
