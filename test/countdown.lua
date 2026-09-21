--- The rate-limit countdown must keep up with the clock.
---
--- Regression test for the lockout countdown freezing at its starting value:
--- `reevaluate()` is the only thing that repaints the PIN display, and while
--- the throttle is paused every route into it is closed, so "Try again in Ns"
--- was rendered once and never again.
---
---   lua test/countdown.lua [plugin_root]

local here = arg[0]:match("(.*)/[^/]*$") or "."
package.path = here .. "/support/?.lua;" .. package.path

local stubs = require("stubs")
local t = require("t")

local PLUGIN_ROOT = arg[1] or (here .. "/../screenlockpin.koplugin")
stubs.install{ plugin_root = PLUGIN_ROOT, rate_limit = true }

local state = require("plugin/state/pininput"):new{ placeholder = "Enter PIN" }

-- Four failed attempts at the same PIN length trip the lock
-- (FAIL_TRIGGER_PER_LENGTH in plugin/state/throttle.lua).
for _ = 1, 4 do
    state.value = "123"
    state:incFailedCount()
end

t.section("countdown tracks the clock while input is blocked")
t.check("when the lock trips", state.display, "Try again in 10s")

stubs.advance(3)
state:appendInput("7")
t.check("+3s, after a blocked tap", state.display, "Try again in 7s")

stubs.advance(4)
state:delInput(false)
t.check("+7s, after a blocked backspace", state.display, "Try again in 3s")

t.section("blocked input stays blocked")
t.check("PIN buffer untouched", state.value, "")

t.finish()
