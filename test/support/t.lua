--- Tiny assertion helper: enough to report clearly, small enough to read.
local t = { checks = 0, failures = 0 }

function t.check(label, got, want)
    t.checks = t.checks + 1
    local ok = got == want
    if not ok then t.failures = t.failures + 1 end
    print(string.format("  %s  %-36s got %-20s want %s",
        ok and "ok" or "XX", label, tostring(got), tostring(want)))
    return ok
end

function t.section(name) print("\n" .. name) end

--- Print the tally and exit non-zero if anything failed.
function t.finish()
    print(string.format("\n%d checks, %d failed -- %s",
        t.checks, t.failures, t.failures == 0 and "PASS" or "FAIL"))
    os.exit(t.failures == 0 and 0 or 1)
end

return t
