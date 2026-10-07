#!/usr/bin/env sh
# Model-check every spec with its config; fails on the first violation.
set -eu
cd "$(dirname "$0")"
JAR="${TLA2TOOLS:-tla2tools.jar}"
for cfg in *.cfg; do
  m="${cfg%.cfg}"
  out="$(java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC -metadir "states/$m" -config "$cfg" "$m.tla" 2>&1)"
  printf '%-10s %s\n' "$m" "$(printf '%s' "$out" | grep -E 'distinct states found' | head -1)"
  printf '%s' "$out" | grep -q 'Model checking completed. No error has been found.' || { printf '%s\n' "$out"; exit 1; }
done
