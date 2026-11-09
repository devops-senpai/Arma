#!/bin/zsh
set -euo pipefail
zmodload zsh/datetime

# Notarizes a release built by Scripts/fork/release.sh and makes its installer.
#
#   Scripts/fork/notarize.sh [version]     (default: the last task release)
#
# Submits $ARMA_BUILD/Arma-<version>.app to Apple's notary service and staples
# the ticket, builds installer/Arma-<version>.dmg with
# Scripts/package-installer-dmg.sh, signs it, and notarizes and staples the
# disk image too. A new account's first submissions can wait hours; the
# script waits with them. Secrets come from the sops file, as in release.sh.

root="${0:A:h:h:h}"
cd "$root"
build="${ARMA_BUILD:-$HOME/code/ArmaBuild}"
secrets="${ARMA_SECRETS:-$HOME/.config/arma/signing.sops.yaml}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.ssh/key.txt}"

fail() { print -u2 "notarize: $1"; exit 1; }
step() { print "== $1"; }
secret() { sops -d --extract "[\"$1\"]" "$secrets"; }

version="${1:-$(cat "$build/last-version" 2>/dev/null)}"
[[ -n "$version" ]] || fail "no version; run task release first"
app="$build/Arma-$version.app"
dmg="$build/installer/Arma-$version.dmg"
[[ -d "$app" ]] || fail "no $app; run task release first"
notary="$(secret notary_keychain_profile)"
identity="$(secret developer_id_sha1)"

# Each submission's wait, from upload to Apple's answer, is appended to
# $ARMA_BUILD/notary-times.csv, since Apple reports only when it started.
submit() {
    local result started=$EPOCHSECONDS answer
    result="$(xcrun notarytool submit "$1" --keychain-profile "$notary" --wait 2>&1)"
    print -r -- "$result" | grep -E "^[[:space:]]*(id|status):" | tail -2
    answer="$(print -r -- "$result" | sed -nE 's/^[[:space:]]*status: //p' | tail -1)"
    [[ -f "$build/notary-times.csv" ]] || print "submitted,file,status,minutes" > "$build/notary-times.csv"
    print "$(date -u -r $started +%Y-%m-%dT%H:%MZ),${1:t},$answer,$(( (EPOCHSECONDS - started + 30) / 60 ))" >> "$build/notary-times.csv"
    [[ "$answer" == Accepted ]] || fail "Apple did not accept $1"
}

zip="$build/Arma-$version.zip"
rm -f "${zip:?}"
ditto -c -k --keepParent "$app" "$zip"
step "submitting the app"
submit "$zip"
xcrun stapler staple "$app" | tail -1
spctl -a -vv "$app" 2>&1 | sed -n 2p

mkdir -p "${dmg:h}"
rm -f "${dmg:?}"
step "building the installer"
Scripts/package-installer-dmg.sh "$app" "$dmg" --sign "$identity" | tail -1
step "submitting the installer"
submit "$dmg"
xcrun stapler staple "$dmg" | tail -1
spctl -a -vv -t open --context context:primary-signature "$dmg" 2>&1 | sed -n 2p
step "notarized $dmg"
