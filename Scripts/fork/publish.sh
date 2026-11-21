#!/bin/zsh
set -euo pipefail

# Publishes a notarized release: the GitHub release with its installer, and
# the signed Sparkle feeds that Arma's Check for Updates reads.
#
#   Scripts/fork/publish.sh <notes.md> [version]   (default: the last task release)
#
# Creates release v<version> from main with installer/Arma-<version>.dmg and
# <notes.md> as its notes, then adds that installer to each feed on the
# repository's updates branch, signed with the Sparkle key from the sops
# file: appcast.xml and appcast-webkit.xml for the Stable channel, and
# appcast-development.xml and appcast-development-webkit.xml for Development,
# the channel release builds follow. Earlier releases and feed entries stay.
# A release that already exists is kept, so a failed feed step can run again.

root="${0:A:h:h:h}"
cd "$root"
build="${ARMA_BUILD:-$HOME/code/ArmaBuild}"
secrets="${ARMA_SECRETS:-$HOME/.config/arma/signing.sops.yaml}"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.ssh/key.txt}"
sparkle_version=2.9.5
sparkle_sha256=015336b601493e05c237964954bff6191370003d94edefe663724c88840d73cc
sparkle="$build/tools/Sparkle-$sparkle_version"

fail() { print -u2 "publish: $1"; exit 1; }
step() { print "== $1"; }
secret() { sops -d --extract "[\"$1\"]" "$secrets"; }

notes="${1:-}"
[[ -f "$notes" ]] || fail "usage: publish.sh <notes.md> [version]"
notes="${notes:A}"
version="${2:-$(cat "$build/last-version" 2>/dev/null)}"
[[ -n "$version" ]] || fail "no version; run task release first"
dmg="$build/installer/Arma-$version.dmg"
[[ -f "$dmg" ]] || fail "no $dmg; run task notarize first"
xcrun stapler validate "$dmg" >/dev/null || fail "$dmg is not notarized"
repo="$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')"
tag="v$version"
installer="${dmg:t}"

# The release is made from main as GitHub holds it, so it must be this commit.
git fetch -q origin main updates
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] \
    || fail "this commit is not origin/main; push main first"

if gh release view "$tag" -R "$repo" >/dev/null 2>&1; then
    step "release $tag already exists; keeping it"
else
    step "creating release $tag"
    gh release create "$tag" -R "$repo" --target main --latest \
        --title "Arma $version (preview)" --notes-file "$notes" "$dmg"
fi

if [[ ! -x "$sparkle/bin/generate_appcast" ]]; then
    step "fetching Sparkle $sparkle_version tools"
    mkdir -p "$sparkle"
    gh release download "$sparkle_version" -R sparkle-project/Sparkle \
        --pattern "Sparkle-$sparkle_version.tar.xz" --dir "$sparkle" --clobber
    print "$sparkle_sha256  $sparkle/Sparkle-$sparkle_version.tar.xz" | shasum -a 256 -c - >/dev/null
    tar -xf "$sparkle/Sparkle-$sparkle_version.tar.xz" -C "$sparkle"
fi

work="$(mktemp -d -t arma-publish)"
feeds="$work/updates"
cleanup() {
    git worktree remove --force "$feeds" 2>/dev/null || true
    rm -rf "${work:?}"
}
trap cleanup EXIT
git worktree add -q --detach "$feeds" origin/updates

# Each feed is made in a folder of its own holding that feed as published,
# the installer and its notes; generate_appcast adds the installer's entry,
# signs it and keeps the entries already there.
url="https://github.com/$repo/releases/download/$tag/$installer"
feed() {
    local appcast="$1" channel="$2" source="$work/${1%.xml}"
    mkdir -p "$source"
    cp "$feeds/$appcast" "$source/$appcast"
    cp "$dmg" "$source/$installer"
    cp "$notes" "$source/${installer%.dmg}.md"
    local -a arguments=(
        --ed-key-file -
        --download-url-prefix "https://github.com/$repo/releases/download/$tag/"
        --link "https://github.com/$repo"
        --maximum-versions 0
        --embed-release-notes
        -o "$source/$appcast"
    )
    [[ -z "$channel" ]] || arguments+=(--channel "$channel")
    secret sparkle_eddsa_private_key | "$sparkle/bin/generate_appcast" "${arguments[@]}" "$source" >/dev/null
    grep -Fq "url=\"$url\"" "$source/$appcast" || fail "$appcast does not offer $url"
    cp "$source/$appcast" "$feeds/$appcast"
}
step "signing the update feeds"
feed appcast.xml ""
feed appcast-webkit.xml ""
feed appcast-development.xml development
feed appcast-development-webkit.xml development

printf '%s\n' '# Arma software updates' '' \
    'Signed Sparkle feeds written by Scripts/fork/publish.sh. Each entry points to a notarized installer in this repository'"'"'s GitHub Releases.' \
    > "$feeds/README.md"
git -C "$feeds" add -A
git -C "$feeds" commit -q -s -m "chore(updates): publish $tag"
step "pushing the update feeds"
git -C "$feeds" push -q origin HEAD:updates
step "published $tag: https://github.com/$repo/releases/tag/$tag"
