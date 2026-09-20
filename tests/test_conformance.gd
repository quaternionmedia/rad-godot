# GdUnitTestSuite
extends GdUnitTestSuite

## Every case in rad's pinned vector file passes against this core.
##
## The file is the governed artefact, copied byte for byte from the rad commit
## `conformance/vectors.lock` names; `tools/check_vector_pin.py` refuses a
## copy that is not those bytes. This suite replays it through
## `RadConformance`, the port of the reference's own runner, and reports every
## failing case in one run rather than stopping at the first.
##
## The last two tests are the suite's own mutation, kept beside the guard: a
## replayer that cannot notice a wrong expectation is not evidence of anything,
## so each run proves it notices one.

const VECTORS := "res://conformance/vectors.json"


func _vectors() -> Dictionary:
	var text := FileAccess.get_file_as_string(VECTORS)
	assert_str(text).override_failure_message("%s could not be read." % VECTORS).is_not_empty()
	var parsed: Variant = JSON.parse_string(text)
	assert_object(parsed).override_failure_message("%s did not parse as JSON." % VECTORS).is_not_null()
	return parsed


func test_every_vector_passes() -> void:
	var v := _vectors()
	var results := RadConformance.run(v)
	assert_int(results.size()).override_failure_message("No cases ran; is the file empty?").is_greater(0)
	var failures := RadConformance.failures(v)
	assert_array(failures) \
		.override_failure_message(
			"%d of %d vectors failed (vectors %s):\n  %s" % [failures.size(), results.size(), v.version, "\n  ".join(failures)]
		) \
		.is_empty()
	print("rad conformance: %d/%d cases pass (vectors %s)" % [results.size() - failures.size(), results.size(), v.version])


func _first_case_with(v: Dictionary, key: String) -> Dictionary:
	for c in v.cases:
		if c.has(key):
			return c.duplicate(true)
	fail("no case carries %s" % key)
	return {}


func test_the_replayer_notices_a_wrong_expected_index() -> void:
	# JSON numbers arrive as floats; an index compared as a float could pass
	# for the wrong reason. Perturb one expectation and require a failure.
	var c := _first_case_with(_vectors(), "pure")
	c.pure[0].expectIndex = float(int(c.pure[0].expectIndex) + 1)
	var r := RadConformance.run({ "cases": [c] })
	assert_bool(r[0].pass) \
		.override_failure_message("The replayer passed a pure case whose expected index was wrong.") \
		.is_false()


func test_the_replayer_notices_a_wrong_expected_commit() -> void:
	var v := _vectors()
	for c in v.cases:
		if c.has("trace") and c.expect.committed != null:
			var m: Dictionary = c.duplicate(true)
			m.expect.committed = float(int(m.expect.committed) + 1)
			var r := RadConformance.run({ "cases": [m] })
			assert_bool(r[0].pass) \
				.override_failure_message("The replayer passed '%s' with the wrong committed index." % c.name) \
				.is_false()
			return
	fail("no trace case commits")
