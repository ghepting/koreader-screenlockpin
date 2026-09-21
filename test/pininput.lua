--- PinInputState behaviour, with the rate limit both on and off.
---
--- Runs the same core assertions in both modes so that changes to the
--- throttle guards can't quietly alter ordinary typing.
---
---   lua test/pininput.lua [plugin_root]

local here = arg[0]:match("(.*)/[^/]*$") or "."
package.path = here .. "/support/?.lua;" .. package.path

local stubs = require("stubs")
local t = require("t")

local PLUGIN_ROOT = arg[1] or (here .. "/../screenlockpin.koplugin")
local DOT = "\u{25CF}" -- what the display shows per entered digit

local function run(rate_limit)
    stubs.install{ plugin_root = PLUGIN_ROOT, rate_limit = rate_limit }

    local submitted
    local state = require("plugin/state/pininput"):new{
        placeholder = "Enter PIN",
        on_update = function(value) submitted = value end,
    }

    t.section("rate limit " .. (rate_limit and "ON" or "OFF") .. ": ordinary input")
    state:appendInput("1")
    state:appendInput("2")
    t.check("digits buffered", state.value, "12")
    t.check("display obfuscated", state.display, DOT:rep(2))

    state:appendInput("3")
    t.check("submits at minimum length", submitted, "123")

    state:delInput(false)
    t.check("backspace drops one digit", state.value, "12")

    state:delInput(true)
    t.check("hold-backspace clears", state.value, "")
    t.check("placeholder restored", state.display, "Enter PIN")

    for _ = 1, 15 do state:appendInput("9") end
    t.check("capped at maximum length", #state.value, 12)
    state:delInput(true)

    if not rate_limit then return end

    t.section("rate limit ON: lockout")
    for _ = 1, 4 do
        state.value = "123"
        state:incFailedCount()
    end
    t.check("lockout engaged", state.display, "Try again in 10s")

    state:appendInput("5")
    t.check("input rejected while locked", state.value, "")

    stubs.advance(10)
    state:appendInput("5")
    t.check("input accepted once elapsed", state.value, "5")
    t.check("display back to normal", state.display, DOT)
end

run(false)
run(true)
t.finish()
