#!/bin/zsh
set -euo pipefail

# Moves Arma's Servo engine to a newer servo release and rebuilds it.
#
#   Scripts/fork/update-servo.sh [version]    (default: crates.io's newest)
#   Scripts/fork/update-servo.sh --check      print pinned and newest only
#
# Pins CrestEngines/Servo/Cargo.toml to servo =<version>, updates Cargo.lock,
# and rebuilds libarma_servo.dylib with Scripts/build-servo-engine.sh, which
# re-applies CrestEngines/Servo/Patches to the servo-net that release names.
# A patch that no longer applies stops the build; refresh it, then run again.

root="${0:A:h:h:h}"
cd "$root"
export PATH="$HOME/.cargo/bin:$PATH"
manifest=CrestEngines/Servo/Cargo.toml

fail() { print -u2 "update-servo: $1"; exit 1; }
step() { print "== $1"; }

pinned="$(sed -nE 's/^servo = \{ version = "=([^"]+)" \}/\1/p' "$manifest")"
[[ -n "$pinned" ]] || fail "no servo pin in $manifest"
newest="$(curl -fsS -A "arma-update-servo (github.com/devops-senpai/Arma)" \
    https://crates.io/api/v1/crates/servo | python3 -c 'import json,sys; print(json.load(sys.stdin)["crate"]["max_stable_version"])')"
if [[ "${1:-}" == "--check" ]]; then
    print "servo pinned $pinned, newest $newest"
    exit 0
fi
command -v cargo >/dev/null || fail "cargo is not installed; install Rust with rustup"
version="${1:-$newest}"
if [[ "$version" == "$pinned" ]]; then
    step "servo is already $pinned"
    exit 0
fi

step "servo $pinned -> $version"
sed -i '' -E "s/^servo = \{ version = \"=[^\"]+\" \}/servo = { version = \"=$version\" }/" "$manifest"
(cd CrestEngines/Servo && cargo update -p servo --precise "$version")
step "rebuilding libarma_servo"
Scripts/build-servo-engine.sh
step "updated; check Servo pages in a Debug build, then commit $manifest and CrestEngines/Servo/Cargo.lock"
