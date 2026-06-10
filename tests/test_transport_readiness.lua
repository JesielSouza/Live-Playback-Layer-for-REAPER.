local transport_readiness = require("scripts.transport_readiness")

local function build_context(overrides)
    overrides = overrides or {}

    return {
        adapter_capabilities = overrides.adapter_capabilities or {
            real_transport_supported = true,
            real_transport_enabled = true
        },
        gate_result = overrides.gate_result or {
            executable = true
        },
        preflight_report = overrides.preflight_report or {
            status = "simulated"
        },
        safety_dashboard = overrides.safety_dashboard or {
            execution_blocked = false
        },
        seek_plan = overrides.seek_plan or {
            ok = true,
            locked = false
        },
        ui_session_state = overrides.ui_session_state or {
            transport_confirmed = true
        }
    }
end

local function has_blocker(report, expected)
    for _, blocker in ipairs(report.blockers) do
        if blocker == expected then
            return true
        end
    end

    return false
end

local function run_transport_readiness_tests()
    print("Running transport readiness tests...\n")

    local missing = transport_readiness.build(nil)
    assert(missing.status == "invalid", "Test 1 failed")
    assert(has_blocker(missing, "missing_context"), "Test 1 failed")
    print("Test 1 passed: missing context returns invalid/missing_context")

    local unsupported = transport_readiness.build(build_context({
        adapter_capabilities = { real_transport_supported = false, real_transport_enabled = true }
    }))
    assert(has_blocker(unsupported, "adapter_supported"), "Test 2 failed")
    print("Test 2 passed: adapter_supported false adds blocker")

    local disabled = transport_readiness.build(build_context({
        adapter_capabilities = { real_transport_supported = true, real_transport_enabled = false }
    }))
    assert(has_blocker(disabled, "adapter_enabled"), "Test 3 failed")
    print("Test 3 passed: adapter_enabled false adds blocker")

    local gate_blocked = transport_readiness.build(build_context({
        gate_result = { executable = false }
    }))
    assert(has_blocker(gate_blocked, "gate_executable"), "Test 4 failed")
    print("Test 4 passed: gate_executable false adds blocker")

    local not_simulated = transport_readiness.build(build_context({
        preflight_report = { status = "blocked" }
    }))
    assert(has_blocker(not_simulated, "preflight_simulated"), "Test 5 failed")
    print("Test 5 passed: preflight_simulated false adds blocker")

    local safety_blocked = transport_readiness.build(build_context({
        safety_dashboard = { execution_blocked = true }
    }))
    assert(has_blocker(safety_blocked, "safety_not_blocked"), "Test 6 failed")
    print("Test 6 passed: safety_not_blocked false adds blocker")

    local bad_seek = transport_readiness.build(build_context({
        seek_plan = { ok = false, locked = false }
    }))
    assert(has_blocker(bad_seek, "seek_plan_ok"), "Test 7 failed")
    print("Test 7 passed: seek_plan_ok false adds blocker")

    local locked_seek = transport_readiness.build(build_context({
        seek_plan = { ok = true, locked = true }
    }))
    assert(has_blocker(locked_seek, "seek_plan_unlocked"), "Test 8 failed")
    print("Test 8 passed: seek_plan_unlocked false adds blocker")

    local unconfirmed = transport_readiness.build(build_context({
        ui_session_state = { transport_confirmed = false }
    }))
    assert(has_blocker(unconfirmed, "manual_confirmed"), "Test 9 failed")
    print("Test 9 passed: manual_confirmed false adds blocker")

    local ready = transport_readiness.build(build_context())
    assert(ready.ready == true, "Test 10 failed")
    print("Test 10 passed: all checks true returns ready=true")

    assert(ready.status == "ready", "Test 11 failed")
    print("Test 11 passed: all checks true returns status ready")

    local blocked = transport_readiness.build(build_context({
        adapter_capabilities = { real_transport_supported = false, real_transport_enabled = false },
        ui_session_state = { transport_confirmed = false }
    }))
    assert(blocked.status == "blocked", "Test 12 failed")
    print("Test 12 passed: no confirmation and blocked returns status blocked")

    local review = transport_readiness.build(build_context({
        adapter_capabilities = { real_transport_supported = false, real_transport_enabled = false },
        ui_session_state = { transport_confirmed = true }
    }))
    assert(review.status == "review", "Test 13 failed")
    print("Test 13 passed: confirmation plus blocked returns status review")

    assert(blocked.summary == "readiness_blocked", "Test 14 failed")
    print("Test 14 passed: blocked summary is readiness_blocked")

    assert(review.summary == "readiness_review", "Test 15 failed")
    print("Test 15 passed: review summary is readiness_review")

    local formatted = transport_readiness.format(review)
    assert(string.find(formatted, "Status"), "Test 16 failed")
    print("Test 16 passed: format contains Status")

    assert(string.find(formatted, "Blockers"), "Test 17 failed")
    print("Test 17 passed: format contains Blockers")

    print("\nTransport readiness tests passed successfully!")
end

run_transport_readiness_tests()
