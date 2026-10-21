#!/usr/bin/env bash
# Claude Code Stop hook: a session does not end while a track whose paths it changed has a stale
# roadmap (docs/roadmap-tracks.json). Exit 2 hands the findings back to the session to fix.
input=$(cat)
# Blocked once already: let it stop (CI still enforces), rather than loop.
[[ $input =~ \"stop_hook_active\"[[:space:]]*:[[:space:]]*true ]] && exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
timeout 15 git -C "$root" fetch -q origin main 2>/dev/null   # compare with the current main where reachable
out=$(cd "$root/pipeline" && python3 -m usul_corpus roadmap --base origin/main --if-available 2>&1) && exit 0
printf 'Roadmap check failed (docs/roadmap.md#tracks):\n%s\n' "$out" >&2
exit 2
