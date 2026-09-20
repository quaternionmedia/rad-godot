# GdUnitTestSuite
extends GdUnitTestSuite

## The first assertion is deliberately trivial: its only job is to prove the
## runner, the vendored addon and the loop line up, so that the first red
## suite is a real failure and not a plumbing problem.
##
## The second is not trivial. The engine pin in .godot-version is what the
## loop refuses to run without; this makes the same refusal inside the test
## run, so an unannounced engine change turns the suite red rather than
## surfacing later as a behaviour drift nobody can date.


func test_the_harness_runs() -> void:
	assert_int(2 + 2).is_equal(4)


func test_engine_matches_the_pin() -> void:
	# .godot-version uses the release's download form (4.7.2-stable); the engine
	# reports its own form (4.7.2.stable.steam.<hash>). Compare on
	# major.minor.patch.status; the build tag after that is who compiled it.
	var pinned := FileAccess.get_file_as_string("res://.godot-version").strip_edges().replace("-", ".")
	assert_str(pinned) \
		.override_failure_message("res://.godot-version is missing or empty.") \
		.is_not_empty()

	var info := Engine.get_version_info()
	var running := "%d.%d.%d.%s" % [info.major, info.minor, info.patch, info.status]
	assert_str(running) \
		.override_failure_message(
			"Running Godot %s, but .godot-version pins %s. " % [running, pinned] +
			"Upgrading the engine is its own decision: it needs a full test pass " +
			"and an entry in the scope record."
		) \
		.is_equal(pinned)
