#!/usr/bin/env bash
set -euo pipefail

provision="$(dirname "$0")/provision-fixture-swipl.sh"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cat > "$scratch/docker" <<'MOCK'
#!/usr/bin/env bash
case "$1:$CONTROL" in
  pull:pull-failure) exit 42 ;;
  pull:wrong-version) exit 0 ;;
  run:wrong-version) printf '%s\n' 'SWI-Prolog version 9.0.5 for x86_64-linux' ;;
  *) exit 99 ;;
esac
MOCK
chmod +x "$scratch/docker"

reject() {
  local control=$1 diagnostic=$2
  local path_file="$scratch/$control.path" env_file="$scratch/$control.env"
  if PATH="$scratch:$PATH" RUNNER_TEMP="$scratch/$control" CONTROL="$control" \
    GITHUB_PATH="$path_file" GITHUB_ENV="$env_file" bash "$provision" > "$scratch/log" 2>&1; then
    echo "Unexpected provisioning success: $control" >&2
    return 1
  fi
  cat "$scratch/log"
  rg -Fq "$diagnostic" "$scratch/log"
  test ! -e "$path_file"
  test ! -e "$env_file"
  echo "Rejected $control without exporting a runtime"
}

reject pull-failure 'Failed to pull pinned SWI-Prolog runtime'
reject wrong-version 'SWI-Prolog identity mismatch'
