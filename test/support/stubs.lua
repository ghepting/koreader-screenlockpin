--- Minimal fake KOReader environment for exercising plugin modules off-device.
---
--- KOReader modules assume a running app: a real `UIManager`, a frontend
--- `EventListener`, a monotonic clock, persisted `G_reader_settings`. This
--- stands all of that up in-process so the state machines can be driven
--- directly, with a clock the test controls instead of wall time.
---
--- Deliberately not a mock framework. It fakes only what the modules under
--- test actually touch; anything else should fail loudly rather than
--- silently return nil.

local M = {}

local NOW = 0

--- Every module name this file replaces or supplies.
local STUBBED = {
    "gettext",
    "logger",
    "ui/widget/eventlistener",
    "ui/time",
    "ui/uimanager",
    "plugin/settings",
    "plugin/state/throttle",
    "plugin/state/pininput",
}

--- Advance the fake clock by `seconds`.
function M.advance(seconds) NOW = NOW + seconds end

--- KOReader's own EventListener:extend/new semantics, reproduced so that
--- class-level vs instance-level field behaviour matches the real thing.
local EventListener = {}
function EventListener:extend(subclass)
    subclass = subclass or {}
    setmetatable(subclass, self)
    self.__index = self
    return subclass
end
function EventListener:new(instance)
    instance = self:extend(instance)
    if instance.init then instance:init() end
    return instance
end

--- Install the fake environment.
---
--- @param opts table
---   plugin_root  path to the directory holding `plugin/...` (required)
---   rate_limit   whether shouldRateLimit() reports true (default true)
--- @return table  handles for inspecting what the modules did
function M.install(opts)
    local plugin_root = assert(opts and opts.plugin_root, "opts.plugin_root is required")
    local rate_limit = opts.rate_limit ~= false

    NOW = 0
    local cache = {}
    local scheduled = {}

    -- Drop anything a previous install() left cached, or a second call in the
    -- same process would keep handing out the first call's settings stub.
    for _, name in ipairs(STUBBED) do package.loaded[name] = nil end

    package.preload["gettext"] = function()
        return function(str) return str end
    end
    package.preload["logger"] = function()
        return { dbg = function() end, warn = function() end, info = function() end }
    end
    package.preload["ui/widget/eventlistener"] = function() return EventListener end
    package.preload["ui/time"] = function()
        return { s = function(n) return n end, now = function() return NOW end }
    end
    package.preload["ui/uimanager"] = function()
        return {
            schedule = function(_, at, fn) table.insert(scheduled, { at = at, fn = fn }) end,
            unschedule = function() end,
        }
    end
    package.preload["plugin/settings"] = function()
        return {
            shouldRateLimit     = function() return rate_limit end,
            readPersistentCache = function(key) return cache[key] end,
            putPersistentCache  = function(key, value) cache[key] = value end,
        }
    end

    -- the real modules under test, loaded from whichever tree we were pointed at
    for _, name in ipairs({ "plugin/state/throttle", "plugin/state/pininput" }) do
        package.preload[name] = function()
            return assert(loadfile(plugin_root .. "/" .. name .. ".lua"))()
        end
    end

    return { cache = cache, scheduled = scheduled }
end

return M
