#!/usr/bin/env bash
# Run every check against a plugin tree. Defaults to the working copy.
#
#   test/run.sh                     # this checkout
#   test/run.sh /path/to/plugin     # some other tree (see README)
#
# Uses luajit when available, since that is what KOReader runs.

set -u

here="$(cd "$(dirname "$0")" && pwd)"
plugin_root="${1:-$here/../screenlockpin.koplugin}"
lua="$(command -v luajit || command -v lua || true)"

if [ -z "$lua" ]; then
    echo "no lua interpreter found; install luajit" >&2
    exit 127
fi

echo "interpreter: $("$lua" -v 2>&1 | head -1)"
echo "plugin root: $plugin_root"

status=0
for check in "$here"/*.lua; do
    echo
    echo "=== $(basename "$check") ==="
    "$lua" "$check" "$plugin_root" || status=1
done

exit $status
