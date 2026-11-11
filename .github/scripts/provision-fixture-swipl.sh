#!/usr/bin/env bash
set -euo pipefail

# Docker Official Image swipl:9.0.4, Linux amd64 child manifest.
image='docker.io/library/swipl@sha256:fd5af1878cbbda22af08c30636f92714cdf3338d30ca998c2c5d351323529faa'
bin_dir="$RUNNER_TEMP/ida-prolog-bin"
scratch="$RUNNER_TEMP/ida-prolog-scratch"

if ! docker pull --platform linux/amd64 "$image"; then
  echo "Failed to pull pinned SWI-Prolog runtime: $image" >&2
  exit 1
fi

mkdir -p "$bin_dir" "$scratch"
cat > "$bin_dir/swipl" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail
exec docker run --rm --pull never --platform linux/amd64 --network none \
  --user "$(id -u):$(id -g)" \
  --volume "$PWD:$PWD:ro" --workdir "\$PWD" \
  --volume "$scratch:$scratch:ro" \
  --entrypoint swipl "$image" "\$@"
WRAPPER
chmod +x "$bin_dir/swipl"

expected='SWI-Prolog version 9.0.4 for x86_64-linux'
if ! actual=$("$bin_dir/swipl" --version); then
  echo "Failed to start pinned SWI-Prolog runtime: $image" >&2
  exit 1
fi
if [[ "$actual" != "$expected" ]]; then
  printf 'SWI-Prolog identity mismatch: expected %s, got %s\n' "$expected" "$actual" >&2
  exit 1
fi

printf 'Runtime: %s\nImage: %s\n' "$actual" "$image"
printf '%s\n' "$bin_dir" >> "$GITHUB_PATH"
printf 'TMPDIR=%s\n' "$scratch" >> "$GITHUB_ENV"
