local regions = require("scripts.regions")

local function run_tests()
    print("Running regions tests...\n")

    -- 1. Region válida simples: INTRO
    local r1 = regions.parse_region_name("INTRO")
    assert(r1.valid == true, "Test 1 failed")
    assert(r1.name == "INTRO", "Test 1 failed")
    assert(r1.id == "INTRO", "Test 1 failed")
    assert(r1.meta.loop == "0", "Test 1 failed")
    assert(#r1.warnings == 0, "Test 1 failed")
    print("Test 1 passed: Simple valid region")

    -- 2. Region válida com todos os campos aceitos.
    local r2 = regions.parse_region_name("VERSE_1|loop=1|next=CHORUS_1|color=blue|midi_scene=verse|jump_quant=immediate|allow_prev=0|notes=play soft")
    assert(r2.valid == true, "Test 2 failed")
    assert(r2.name == "VERSE_1", "Test 2 failed")
    assert(r2.meta.loop == "1", "Test 2 failed")
    assert(r2.meta.next == "CHORUS_1", "Test 2 failed")
    assert(r2.meta.color == "blue", "Test 2 failed")
    assert(r2.meta.midi_scene == "verse", "Test 2 failed")
    assert(r2.meta.jump_quant == "immediate", "Test 2 failed")
    assert(r2.meta.allow_prev == "0", "Test 2 failed")
    assert(r2.meta.notes == "play soft", "Test 2 failed")
    assert(#r2.warnings == 0, "Test 2 failed")
    print("Test 2 passed: Valid region with all fields")

    -- 3. Region com loop=abc gera default e warning.
    local r3 = regions.parse_region_name("CHORUS|loop=abc")
    assert(r3.valid == true, "Test 3 failed")
    assert(r3.meta.loop == "0", "Test 3 failed")
    assert(#r3.warnings > 0, "Test 3 failed")
    print("Test 3 passed: Invalid loop value falls back to default and warns")

    -- 4. Region com jump_quant=bad gera default e warning.
    local r4 = regions.parse_region_name("BRIDGE|jump_quant=bad")
    assert(r4.valid == true, "Test 4 failed")
    assert(r4.meta.jump_quant == "bar", "Test 4 failed")
    assert(#r4.warnings > 0, "Test 4 failed")
    print("Test 4 passed: Invalid jump_quant falls back to default and warns")

    -- 5. Region com allow_prev=maybe gera default e warning.
    local r5 = regions.parse_region_name("TAG|allow_prev=maybe")
    assert(r5.valid == true, "Test 5 failed")
    assert(r5.meta.allow_prev == "1", "Test 5 failed")
    assert(#r5.warnings > 0, "Test 5 failed")
    print("Test 5 passed: Invalid allow_prev falls back to default and warns")

    -- 6. Region com campo desconhecido gera warning.
    local r6 = regions.parse_region_name("VAMP|foo=bar")
    assert(r6.valid == true, "Test 6 failed")
    assert(r6.meta.foo == nil, "Test 6 failed")
    assert(#r6.warnings > 0, "Test 6 failed")
    print("Test 6 passed: Unknown field warns and is ignored")

    -- 7. Region com token sem `=`, depois do nome, gera warning.
    local r7 = regions.parse_region_name("ENDING|something")
    assert(r7.valid == true, "Test 7 failed")
    assert(#r7.warnings > 0, "Test 7 failed")
    print("Test 7 passed: Token without equals sign warns")

    -- 8. Region com nome vazio é inválida.
    local r8 = regions.parse_region_name("   |loop=1")
    assert(r8.valid == false, "Test 8 failed")
    assert(#r8.warnings > 0, "Test 8 failed")
    print("Test 8 passed: Empty name makes region invalid")

    -- 9. parse_regions ordena por start_pos.
    local raw_regions = {
        { name = "CHORUS|loop=0", start_pos = 10, end_pos = 20, index = 2 },
        { name = "VERSE|loop=0", start_pos = 0, end_pos = 10, index = 1 }
    }
    local res9 = regions.parse_regions(raw_regions)
    assert(#res9.sections == 2, "Test 9 failed")
    assert(res9.sections[1].name == "VERSE", "Test 9 failed")
    assert(res9.sections[2].name == "CHORUS", "Test 9 failed")
    print("Test 9 passed: parse_regions sorts valid sections by start_pos")

    -- 10. parse_regions separa válidas e inválidas.
    local raw_regions_mixed = {
        { name = "VALID|loop=0", start_pos = 0, end_pos = 10, index = 1 },
        { name = "|loop=0", start_pos = 10, end_pos = 20, index = 2 }
    }
    local res10 = regions.parse_regions(raw_regions_mixed)
    assert(#res10.sections == 1, "Test 10 failed")
    assert(#res10.invalid == 1, "Test 10 failed")
    assert(res10.sections[1].name == "VALID", "Test 10 failed")
    assert(res10.invalid[1].index == 2, "Test 10 failed")
    print("Test 10 passed: parse_regions separates valid and invalid")

    print("\nAll tests passed successfully!")
end

run_tests()
