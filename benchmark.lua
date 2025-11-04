--[[
    Cancel Addon - Performance Benchmark Script
    
    This script measures the actual performance difference between
    the original and optimized versions of the cancel addon.
    
    Usage: Run from command line with both versions available
]]--

res = require 'resources'
language = 'en'

-- Simulated player data for testing
local mock_player = {
    buffs = {71, 69, 43, 44, 33, 40, 41, 42, 56, 57}  -- Common buffs
}

local function mock_get_player()
    return mock_player
end

-------------------------------------------
-- ORIGINAL VERSION (Nested Loops)
-------------------------------------------
local function cancel_original(command)
    local status_id_tab = {}
    for arg in command:gmatch('[^,]+') do
        table.insert(status_id_tab, arg:match("^%s*(.-)%s*$")) -- trim
    end
    
    local cancelled_count = 0
    for _, v in pairs(mock_player.buffs) do
        for _, r in pairs(status_id_tab) do
            local buff_data = res.buffs[v]
            if buff_data and buff_data[language] then
                if buff_data[language]:lower() == r:lower() or tostring(v) == r then
                    cancelled_count = cancelled_count + 1
                    break
                end
            end
        end
    end
    return cancelled_count
end

-------------------------------------------
-- OPTIMIZED VERSION (Set-Based)
-------------------------------------------
local function cancel_optimized(command)
    local status_id_tab = {}
    for arg in command:gmatch('[^,]+') do
        table.insert(status_id_tab, arg:match("^%s*(.-)%s*$")) -- trim
    end
    
    -- Build target ID set first
    local target_ids = {}
    for _, pattern in ipairs(status_id_tab) do
        local numeric_id = tonumber(pattern)
        if numeric_id then
            target_ids[numeric_id] = true
        else
            for buff_id, buff_data in pairs(res.buffs) do
                if buff_data and buff_data[language] then
                    if buff_data[language]:lower() == pattern:lower() then
                        target_ids[buff_id] = true
                    end
                end
            end
        end
    end
    
    -- Single pass through player buffs
    local cancelled_count = 0
    for _, buff_id in ipairs(mock_player.buffs) do
        if target_ids[buff_id] then
            cancelled_count = cancelled_count + 1
        end
    end
    return cancelled_count
end

-------------------------------------------
-- BENCHMARK RUNNER
-------------------------------------------
local function benchmark(name, func, test_cases, iterations)
    print(string.format("\n=== Testing: %s ===", name))
    
    for test_name, command in pairs(test_cases) do
        local start_time = os.clock()
        
        for i = 1, iterations do
            func(command)
        end
        
        local total_time = os.clock() - start_time
        local avg_time_ms = (total_time / iterations) * 1000
        
        print(string.format("  %s: %.3f ms (%.1f µs)", 
            test_name, avg_time_ms, avg_time_ms * 1000))
    end
end

-------------------------------------------
-- TEST CASES
-------------------------------------------
local test_cases = {
    ["Single buff (name)"] = "Sneak",
    ["Single buff (ID)"] = "71",
    ["Two buffs"] = "Sneak,Invisible",
    ["Five buffs"] = "Sneak,Invisible,Protect,Shell,Haste",
    ["Ten buffs"] = "43,44,33,40,41,42,56,57,71,69",
}

local ITERATIONS = 10000

-------------------------------------------
-- RUN BENCHMARKS
-------------------------------------------
print("\n" .. string.rep("=", 60))
print("CANCEL ADDON - PERFORMANCE BENCHMARK")
print(string.rep("=", 60))
print(string.format("Iterations per test: %d", ITERATIONS))
print(string.format("Player buffs active: %d", #mock_player.buffs))

benchmark("ORIGINAL (Nested Loops)", cancel_original, test_cases, ITERATIONS)
benchmark("OPTIMIZED (Set-Based)", cancel_optimized, test_cases, ITERATIONS)

print("\n" .. string.rep("=", 60))
print("PERFORMANCE COMPARISON")
print(string.rep("=", 60))

-- Calculate improvement percentages
for test_name, command in pairs(test_cases) do
    -- Measure original
    local start = os.clock()
    for i = 1, ITERATIONS do
        cancel_original(command)
    end
    local time_original = os.clock() - start
    
    -- Measure optimized
    start = os.clock()
    for i = 1, ITERATIONS do
        cancel_optimized(command)
    end
    local time_optimized = os.clock() - start
    
    local improvement = ((time_original - time_optimized) / time_original) * 100
    local speedup = time_original / time_optimized
    
    print(string.format("\n%s:", test_name))
    print(string.format("  Original:  %.3f ms", (time_original / ITERATIONS) * 1000))
    print(string.format("  Optimized: %.3f ms", (time_optimized / ITERATIONS) * 1000))
    print(string.format("  Improvement: %.1f%% faster (%.2fx speedup)", improvement, speedup))
end

print("\n" .. string.rep("=", 60))
print("Benchmark complete!")
print(string.rep("=", 60))
