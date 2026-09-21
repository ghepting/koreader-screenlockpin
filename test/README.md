# Tests

Off-device checks for the plugin's state machines. No KOReader install, no
e-reader, no build step — just an interpreter.

```sh
test/run.sh
```

## Requirements

LuaJIT, which is what KOReader itself runs:

```sh
brew install luajit        # macOS
apt install luajit         # Debian/Ubuntu
```

`run.sh` falls back to plain `lua` if LuaJIT isn't present. The code under test
doesn't use anything version-specific, but LuaJIT is the runtime that matters.

## What's here

| File | Covers |
| --- | --- |
| `countdown.lua` | The rate-limit countdown keeps up with the clock while input is blocked |
| `pininput.lua` | `PinInputState` buffering, obfuscation, submit, backspace, length cap, lockout |
| `support/stubs.lua` | The fake KOReader environment |
| `support/t.lua` | Assertion helper |

Each file is runnable on its own and exits non-zero on failure:

```sh
luajit test/pininput.lua
```

## How it works

KOReader modules assume a running app — a real `UIManager`, a frontend
`EventListener`, a monotonic clock, persisted `G_reader_settings`.
`support/stubs.lua` stands in for exactly those, then loads the real
`plugin/state/*.lua` on top. The clock is fake and advanced by hand, so a 60
second lockout takes no wall time to test.

`EventListener:extend`/`:new` are reproduced rather than faked loosely, because
the distinction between class-level and instance-level fields is load-bearing
in this code.

It isn't a mock framework and shouldn't grow into one. It fakes only what the
modules under test actually reach for; anything else should fail loudly rather
than quietly return nil.

## Running against another tree

Both scripts take a plugin root, which makes it easy to check a change against
the version before it:

```sh
mkdir -p /tmp/base/plugin/state
for f in throttle pininput; do
  git show main:screenlockpin.koplugin/plugin/state/$f.lua > /tmp/base/plugin/state/$f.lua
done
luajit test/countdown.lua /tmp/base
```

## What this does not cover

Everything above the state machines: widget layout, the actual e-ink refresh,
gesture handling, settings persistence, the updater, and anything touching real
hardware. The checks stop at `on_display_update` — they verify what the display
*should* be told to show, not what a screen ends up displaying.
