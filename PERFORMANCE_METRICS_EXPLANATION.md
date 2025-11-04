# Cancel Addon - Performance Metrics Explanation

## ⚠️ CRITICAL ISSUE: Metrics Are Not Based on Real Measurements

### The Problem

The performance metrics table in `README.md` shows specific timing values:

```markdown
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Multi-buff cancel (5 buffs)** | ~2.5ms | ~0.8ms | **68% faster** |
| **Wildcard pattern cancel** | ~3.0ms | ~1.0ms | **67% faster** |
| **Single buff cancel** | ~1.2ms | ~0.6ms | **50% faster** |
```

**These numbers are fabricated estimates, not actual measurements.**

### Evidence

1. **No benchmarking code exists** in the addon
   - Searched for: `os.clock`, `benchmark`, `timing`, `measure`
   - Found: 0 instances in the code

2. **No test harness or performance testing infrastructure**
   - No benchmark scripts
   - No timing measurements
   - No test data

3. **Optimization report uses "Estimated" language**
   - "**Estimated** Performance Impact: ~80% reduction"
   - These are theoretical calculations, not real measurements

### How These Numbers Were Created

The percentages were reverse-engineered from optimization descriptions:

1. **"60% faster"** → Listed in optimization report as "nested loop elimination"
2. **"15% faster"** → Listed as "cached player reference"
3. **"20% faster"** → Listed as "optimized wildcard matching"

Then arbitrary millisecond values were added to create a table that looks authoritative but has no basis in reality.

---

## 📊 What We Actually Know

### Code-Level Analysis (Factual)

#### 1. Algorithm Complexity Improvement
- **Before**: O(n × m) where n = player buffs, m = patterns
  - Nested loop: every buff checked against every pattern
- **After**: O(n + m) 
  - First pass resolves patterns to IDs: O(m)
  - Second pass checks buffs once: O(n)

**Example**: With 10 buffs and 5 patterns:
- Before: 10 × 5 = 50 comparisons
- After: 10 + 5 = 15 operations
- Theoretical: **70% reduction in operations**

#### 2. API Call Reduction
- **Before**: `windower.ffxi.get_player()` called every loop iteration
- **After**: Called once, cached
- **Reduction**: From n calls to 1 call

#### 3. Resource Lookup Optimization
- **Before**: `res.buffs[v][language]` accessed in hot loop
- **After**: Accessed once per unique buff ID
- **Improvement**: Fewer table lookups

#### 4. Pattern Matching Optimization
- **Before**: Always used `windower.wc_match()` (expensive regex)
- **After**: Simple string equality for non-wildcard patterns
- **Improvement**: Faster when no wildcards present

### What These Mean Qualitatively

✅ The optimizations are **real and legitimate**
✅ The code **will run faster**
✅ The improvement **scales with number of buffs/patterns**

❌ We **don't know the actual millisecond timings**
❌ We **can't claim specific percentages** without measuring
❌ The **table values are fiction**

---

## 🔬 How to Get Real Measurements

I've created `benchmark.lua` in this directory that will measure actual performance. Here's how to use it:

### Option 1: Standalone Benchmark (Recommended)

```bash
cd "c:\Program Files (x86)\Windower\addons\cancel"
lua benchmark.lua
```

This will output real timing data like:
```
=== Testing: ORIGINAL (Nested Loops) ===
  Single buff (name): 0.125 ms (125.0 µs)
  Five buffs: 0.287 ms (287.0 µs)

=== Testing: OPTIMIZED (Set-Based) ===
  Single buff (name): 0.089 ms (89.0 µs)
  Five buffs: 0.112 ms (112.0 µs)

Improvement: 28.8% faster (1.40x speedup)
```

### Option 2: In-Game Benchmark

Add this to `cancel.lua` after the existing code:

```lua
-- BENCHMARK MODE: Add this to test performance
if ... == 'benchmark' then
    local iterations = 10000
    local test_cases = {
        {name = "Single buff", command = "Sneak"},
        {name = "Five buffs", command = "Sneak,Invisible,Protect,Shell,Haste"},
    }
    
    for _, test in ipairs(test_cases) do
        local start = os.clock()
        for i = 1, iterations do
            -- Run command processing without actually canceling
            local status_id_tab = test.command:split(',')
            local player = windower.ffxi.get_player()
            if player then
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
            end
        end
        local elapsed = os.clock() - start
        local avg_ms = (elapsed / iterations) * 1000
        windower.add_to_chat(159, string.format('[%s] %.3f ms average', test.name, avg_ms))
    end
    return
end
```

Then in-game: `//cancel benchmark`

---

## 📝 Corrected README Text

### Replace the "Performance Metrics" section with:

```markdown
## 📊 Performance Improvements

This version includes significant algorithmic improvements:

### Complexity Reduction
- **Before**: O(n×m) nested loop - every buff checked against every pattern
- **After**: O(n+m) two-pass algorithm - build ID set, then single pass
- **Impact**: ~70% fewer comparisons with typical usage (10 buffs, 5 patterns)

### Optimizations Applied
1. **Eliminated nested loops** - Single pass through player buffs
2. **Cached player reference** - One API call instead of n calls
3. **Smart pattern matching** - Skip regex for exact name matches
4. **Cached language setting** - No repeated lookups

### Expected Performance
- Scales better with more buffs/patterns
- Faster single-buff cancellation
- Significantly faster multi-buff operations
- Lower CPU overhead in combat

**Note**: Actual timing depends on hardware and game state. The optimizations 
provide real improvements, but specific millisecond timings require benchmarking
on your system.
```

---

## 🎯 Recommendations

### For Documentation

1. **Remove the metrics table** - It's misleading
2. **Focus on algorithmic improvements** - These are verifiable
3. **Use qualitative language** - "faster", "more efficient", "reduced overhead"
4. **Provide benchmark tools** - Let users measure on their systems

### For Honest Claims

**Good (verifiable)**:
- "Reduced algorithm complexity from O(n×m) to O(n+m)"
- "Eliminates nested loops for better performance"
- "Caches player data to avoid repeated API calls"
- "Provides measurable performance improvements"

**Bad (unverifiable)**:
- "68% faster" (without measurements)
- "~2.5ms" (specific timing without benchmarking)
- "80% reduction" (not measured)

### For Future Optimizations

1. **Always benchmark before claiming numbers**
2. **Use multiple test scenarios**
3. **Run enough iterations for statistical significance**
4. **Document test methodology**
5. **Provide benchmark scripts for reproducibility**

---

## 📚 Benchmark Methodology (If You Measure)

### Proper Testing Should Include:

1. **Controlled Environment**
   - Same character, same zone
   - Consistent buff counts
   - No other CPU-intensive addons

2. **Multiple Scenarios**
   - Single buff by name
   - Single buff by ID
   - Multiple buffs (2, 5, 10)
   - Wildcard patterns
   - Mixed patterns and IDs

3. **Statistical Rigor**
   - Minimum 1000 iterations per test
   - Multiple test runs (3-5)
   - Calculate mean and standard deviation
   - Report confidence intervals

4. **Documentation**
   - System specs (CPU, RAM, OS)
   - Test date and game state
   - Windower version
   - Full test script

5. **Reproducibility**
   - Provide benchmark script
   - Document test procedure
   - Allow others to verify results

---

## ⚖️ Conclusion

### What We Can Honestly Say

✅ "The optimized version uses better algorithms"
✅ "Performance scales better with more buffs"
✅ "Reduces API calls and unnecessary comparisons"
✅ "Expected to be faster in most scenarios"

### What We Cannot Say (Without Measurements)

❌ "68% faster"
❌ "~2.5ms to ~0.8ms"
❌ "80% reduction in processing time"

### The Bottom Line

**The optimizations are real and valuable.** The code quality improvements are legitimate. But the specific performance numbers in the README are fabricated estimates that undermine credibility.

**Action Required**: Either run proper benchmarks to get real numbers, or remove the metrics table and stick to qualitative descriptions of improvements.

---

## 🔗 Resources

- [Lua Performance Tips](http://lua-users.org/wiki/OptimisationTips)
- [Microbenchmarking in Lua](http://lua-users.org/wiki/Microbenchmarking)
- [Windower Performance Best Practices](https://github.com/Windower/Lua/wiki/Performance)

---

**Created**: November 4, 2025  
**Author**: Performance Audit Documentation  
**Purpose**: Clarify the source of performance claims and provide proper measurement methodology
