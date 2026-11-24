#!/bin/zsh
set -euo pipefail

# Builds a Developer ID signed Arma.app from the checked-out commit.
#
#   Scripts/fork/release.sh
#
# Stamps the derived version, publishes the native core for Apple silicon and
# Intel, builds the Chromium UI product in Release, restores the stamped file,
# and packages $ARMA_BUILD/Arma-<version>.app with the local universal Chromium
# engine (out/CrestUniversal, which chromium-fork.py build merges from each
# architecture's browser). The app, the core, the engine and its interface
# framework must each hold both architectures. Servo is left out until it is
# stable enough to ship; ARMA_WITH_SERVO=1 bundles it (Apple silicon only).
# Signing values come from the sops file and are never printed.
#
#   ARMA_VERSION          the version to build as (derived, but above the newest release)
#   ARMA_BUILD            output folder (~/code/ArmaBuild)
#   ARMA_CHROMIUM         Chromium workspace (~/Dev/CrestChromium)
#   ARMA_WITH_SERVO       1 bundles the Servo engine (off by default)
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
browser=( $chromium/sources/*/src/out/CrestUniversal/Chromium.app(N/om[1]) )
(( ${#browser} )) || fail "no universal Chromium build under $chromium/sources; run task engine:build"
servo_args=()
if [[ "${ARMA_WITH_SERVO:-0}" == 1 ]]; then
    [[ -f "$servo" ]] || fail "no Servo library at $servo"
    servo_args=(--servo "$servo")
fi

profile="$(mktemp -t arma-profile).provisionprofile"
restore() {
    rm -f "$profile"
    git checkout -q -- Config/Version.xcconfig
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
# Sparkle offers an update only when its build number is higher, so the
# build number rises with the version: X.Y.Z builds as X*10^7 + Y*10^5 + Z,
# 0.8.223 as 800223. That stays above the 99999 earlier copies carried, so
# they update too.
IFS=. read -r major minor patch <<< "$version"
build_number=$(( major * 10000000 + minor * 100000 + patch ))
step "version $version (build $build_number)"
sed -i '' -E "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $version/" Config/Version.xcconfig
step "native core"
core="$(python3 Scripts/control-plane/mac_core.py --output "$build/core" | tail -1)"
step "Chromium UI product"
xcodebuild build -scheme CrestChromiumUIProduct -configuration Release CURRENT_PROJECT_VERSION="$build_number" \
    CODE_SIGNING_ALLOWED=NO -derivedDataPath "$build/release-dd" 2>&1 | grep -E "error:|\*\* BUILD" | tail -5
git checkout -q -- Config/Version.xcconfig

app="$build/Arma-$version.app"
rm -rf "${app:?}"
step "packaging $app"
python3 Scripts/control-plane/package-chromium-host.py \
    --browser "${browser[1]}" --product \
    --ui "$build/release-dd/Build/Products/Release/CrestChromiumUIProduct.framework" \
    --core "$core" \
    "${servo_args[@]}" \
    --signing-identity "$identity" --distribution \
    --entitlements "$fork_dir/release.entitlements" \
    --provisioning-profile "$profile" \
    --output "$app" | tail -1 | cut -c1-80
codesign --verify --deep --strict "$app"
# The Mac app is universal: every slice a release ships holds both architectures.
for arch in arm64 x86_64; do
    lipo "$app/Contents/MacOS/$(defaults read "$app/Contents/Info" CFBundleExecutable)" -verify_arch "$arch"
    lipo "$app/Contents/Frameworks/CrestCore.Native.dylib" -verify_arch "$arch"
    lipo "$app/Contents/Frameworks/CrestChromiumUIProduct.framework/CrestChromiumUIProduct" -verify_arch "$arch"
done
print -r -- "$version" > "$build/last-version"
step "built and signed $app ($(defaults read "$app/Contents/Info" CFBundleShortVersionString))"
