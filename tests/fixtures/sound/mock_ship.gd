extends Node3D
## R2-SOUND S1 test double: just the surface ShipSound reads from the ship demo.
signal captain_event(e: Dictionary)
var active_level := 0
var avatar_pos := Vector3(0, 0, 0)
var avatar: Node3D = null
var director := MockDirector.new()
var consoles := MockConsoles.new()
var lift := MockLift.new()
var journey_sim: Variant = null


class MockDirector:
	var yaw := 0.0
	func walk_yaw() -> float:
		return yaw


class MockConsoles:
	signal used(station: String, action: String)
	var focused := ""
	var stations := {"navigation": {"use": Vector3(0, 0, -6), "meshes": [{"origin": Vector3(0, 1, -7)}]}, "comms": {"use": Vector3(5, 0, -6), "meshes": [{"origin": Vector3(5, 1, -7)}]}}
	var comms_station: Node = null ## R3-EARTH-LINK EL3b.7: the real CommsStation, set by the test


class MockLift:
	var state := "bridge_ready"
	var platform := Node3D.new()


class MockSim:
	signal stepped(events: Array)
	var world := {"tick": 3, "archive": {"memory_health": 50}}
