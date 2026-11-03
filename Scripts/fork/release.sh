#!/bin/zsh
set -euo pipefail

# Builds a Developer ID signed Arma.app from the checked-out commit.
#
#   Scripts/fork/release.sh
#
# Stamps the derived version, publishes the native core, builds the Chromium
# UI product in Release, restores the stamped files, and packages
# $ARMA_BUILD/Arma-<version>.app with the local Chromium engine and Servo.
# Signing values come from the sops file and are never printed.
#
#   ARMA_VERSION          the version to build as (derived, but above the newest release)
#   ARMA_BUILD            output folder (~/code/ArmaBuild)
#   ARMA_CHROMIUM         Chromium workspace (~/Dev/CrestChromium)
#   ARMA_SERVO_DYLIB      libarma_servo (CrestEngines/Servo's build from task servo:update,
#                         else ~/Dev/ArmaServo/spike/target/release/libarma_servo.dylib)
#   ARMA_SECRETS          sops file (~/.config/arma/signing.sops.yaml)
#   SOPS_AGE_KEY_FILE     age key (~/.ssh/key.txt)

root="${0:A:h:h:h}"
cd "$root"
fork_dir="${0:A:h}"
build="${ARMA_BUILD:-$HOME/code/ArmaBuild}"
chromium="${ARMA_CHROMIUM:-$HOME/Dev/CrestChromium}"
servo="${ARMA_SERVO_DYLIB:-$root/CrestEngines/Servo/target/release/libarma_servo.dylib}"
[[ -f "$servo" || -n "${ARMA_SERVO_DYLIB:-}" ]] || servo="$HOME/Dev/ArmaServo/spike/target/release/libarma_servo.dylib"
secrets="${ARMA_SECRETS:-$HOME/.config/arma/signing.sops.yaml}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.ssh/key.txt}"
export PATH="$HOME/.dotnet:$PATH" DOTNET_ROOT="$HOME/.dotnet"

fail() { print -u2 "release: $1"; exit 1; }
step() { print "== $1"; }
secret() { sops -d --extract "[\"$1\"]" "$secrets"; }

[[ -z "$(git status --porcelain --untracked-files=no)" ]] || fail "the work tree has changes"
browser=( $chromium/sources/*/src/out/CrestBaseline/Chromium.app(N/om[1]) )
(( ${#browser} )) || fail "no Chromium build under $chromium/sources"
[[ -f "$servo" ]] || fail "no Servo library at $servo"

profile="$(mktemp -t arma-profile).provisionprofile"
restore() {
    rm -f "$profile"
    git checkout -q -- Config/Version.xcconfig Documentation/ReleaseNotes.json
}
trap restore EXIT
identity="$(secret developer_id_sha1)"
secret developer_id_provisioning_profile_base64 | base64 -d > "$profile"

# The derived version counts fork commits since upstream last set its base,
# and folding commits can lower that count, so a release never goes below
# the newest one published: it takes the next patch instead.
version="${ARMA_VERSION:-$(python3 Scripts/derive-version.py version)}"
published="$(gh release list -R "$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')" \
    --limit 100 --json tagName -q '.[].tagName' | sed -n 's/^v//p' | sort -V | tail -1)"
if [[ -z "${ARMA_VERSION:-}" && -n "$published" && "$(printf '%s\n' "$published" "$version" | sort -V | tail -1)" == "$published" ]]; then
    version="${published%.*}.$(( ${published##*.} + 1 ))"
fi
step "version $version"
sed -i '' -E "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $version/" Config/Version.xcconfig
python3 Scripts/release_note_catalog.py --write-assembled
step "native core"
(cd CrestCore && dotnet publish src/CrestCore.Native -c Release -r osx-arm64 | tail -1)
step "Chromium UI product"
xcodebuild build -scheme CrestChromiumUIProduct -configuration Release CURRENT_PROJECT_VERSION=99999 \
    CODE_SIGNING_ALLOWED=NO -derivedDataPath "$build/release-dd" 2>&1 | grep -E "error:|\*\* BUILD" | tail -5
git checkout -q -- Config/Version.xcconfig Documentation/ReleaseNotes.json

app="$build/Arma-$version.app"
rm -rf "${app:?}"
step "packaging $app"
python3 Scripts/control-plane/package-chromium-host.py \
    --browser "${browser[1]}" --product \
    --ui "$build/release-dd/Build/Products/Release/CrestChromiumUIProduct.framework" \
    --core CrestCore/src/CrestCore.Native/bin/Release/net10.0/osx-arm64/publish/CrestCore.Native.dylib \
    --servo "$servo" \
    --signing-identity "$identity" --distribution \
    --entitlements "$fork_dir/release.entitlements" \
    --provisioning-profile "$profile" \
    --output "$app" | tail -1 | cut -c1-80
codesign --verify --deep --strict "$app"
print -r -- "$version" > "$build/last-version"
step "built and signed $app ($(defaults read "$app/Contents/Info" CFBundleShortVersionString))"
