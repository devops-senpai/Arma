#!/bin/zsh
set -euo pipefail

# Brings upstream Crest's new commits under the fork while keeping its history
# as upstream's main plus one commit per fork change, with no merge commit.
#
#   Scripts/fork/sync.sh            merge, replay with fixups folded, verify
#   Scripts/fork/sync.sh --replay   after resolving a merge conflict by hand
#   Scripts/fork/sync.sh --finish   after fixing the replay by hand
#
# 1. Merges upstream/main on fork-sync/merge with Scripts/sync-upstream.sh,
#    which regenerates generated files and runs the lint and version check.
#    A conflict it cannot settle stops here: resolve, stage, run
#    Scripts/sync-upstream.sh --continue, then this script with --replay.
# 2. Replays each fork commit, with its message, onto upstream/main in a
#    worktree. Every "fixup! <subject>" commit replays with the commit it
#    names, so it folds there even when later commits changed the same
#    files, which a rebase could not do. A conflicting file takes the
#    merge's content less the edits of commits still to come
#    (Scripts/fork/regroup.py).
# 3. Settles xcodegen's build-phase ordering, checks that the replayed tree
#    is the merge's tree, and moves the branch onto the result. The old head
#    stays as backup/pre-sync-<time>. Nothing is pushed.
#
# With nothing new upstream it still replays when there are fixups to fold.
#
# A file edited by hand in the merge without having conflicted belongs to no
# replayed commit, so the replay comes out without the edit and step 3 stops.
# In the worktree, check the file out from fork-sync/target, commit it as
# "fixup! <subject of the commit it belongs to>", and run --finish.

root="${0:A:h:h:h}"
cd "$root"
# The merge regenerates the contract sources, which needs .NET.
export PATH="$HOME/.dotnet:$PATH" DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
fork_dir="${0:A:h}"
branch="$(git branch --show-current)"
worktree="$root/../${root:t}-fork-sync"
replay=0
finish=0
[[ "${1:-}" == "--replay" ]] && replay=1
[[ "${1:-}" == "--finish" ]] && finish=1

fail() { print -u2 "fork-sync: $1"; exit 1; }
step() { print "== $1"; }
# Whether a "fixup!" commit follows $1. grep reads the whole log: with -q it
# leaves at the first match, git log dies writing to the closed pipe, and
# pipefail then reports the match as a failure.
has_fixups() { git log --format=%s "$1..HEAD" | grep -c '^fixup! ' >/dev/null; }

if (( finish )); then
    [[ "$branch" == fork-sync/merge ]] || fail "--finish runs on fork-sync/merge"
    [[ -d "$worktree" ]] || fail "there is no replay to finish at $worktree"
elif (( ! replay )); then
    [[ "$branch" == fork-sync/merge ]] && fail "on fork-sync/merge; finish the merge and use --replay"
    [[ -z "$(git status --porcelain --untracked-files=no)" ]] || fail "the work tree has changes"
    git fetch -q upstream
    base="$(git merge-base HEAD upstream/main)"
    git branch -f "backup/pre-sync-$(date +%Y%m%d-%H%M)" HEAD
    if [[ "$base" == "$(git rev-parse upstream/main)" ]]; then
        if ! has_fixups "$base"; then
            step "upstream has nothing new"
            exit 0
        fi
        step "upstream has nothing new; folding fixup commits"
        git config fork-sync.branch "$branch"
        git switch -q -C fork-sync/merge
    else
        step "merging $(git rev-list --count "$base..upstream/main") upstream commits on fork-sync/merge"
        git config fork-sync.branch "$branch"
        git switch -q -C fork-sync/merge
        Scripts/sync-upstream.sh || fail "resolve the merge, run Scripts/sync-upstream.sh --continue, then $0 --replay"
    fi
else
    [[ "$branch" == fork-sync/merge ]] || fail "--replay runs on fork-sync/merge"
    git diff --quiet HEAD || fail "commit the merge first (Scripts/sync-upstream.sh --continue)"
fi

branch="$(git config fork-sync.branch)"
if (( ! finish )); then
    old_base="$(git merge-base "$branch" upstream/main)"
    git branch -f fork-sync/target HEAD

    step "replaying $(git rev-list --count "$old_base..$branch") fork commits"
    plan="$(mktemp -t fork-sync-plan)"
    python3 "$fork_dir/regroup.py" plan "$old_base" "$branch" "$plan"
    git worktree remove --force "$worktree" 2>/dev/null || true
    git worktree add -q -B fork-sync/build "$worktree" upstream/main
    (cd "$worktree" && python3 "$fork_dir/regroup.py" "$plan") | grep -E "STUCK|ALL DONE|empty" \
        || fail "replay failed; see $worktree"
    rm -f "$plan"
fi

cd "$worktree"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || fail "commit the changes in $worktree first"
pbx=Crest.xcodeproj/project.pbxproj
if ! git diff --quiet fork-sync/target HEAD -- "$pbx"; then
    owner="$(git log -1 --format=%s -- "$pbx")"
    git checkout -q fork-sync/target -- "$pbx"
    git commit -q -m "fixup! ${owner#fixup! }"
fi
# The project's settling above, and any fixup a person committed here.
if has_fixups upstream/main; then
    GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash upstream/main
fi
git filter-branch -f --msg-filter \
    'sed "/^Regroup-Id: /d" | sed -e :a -e "/^\n*\$/{\$d;N;ba" -e "}"' upstream/main..HEAD >/dev/null 2>&1
if ! git diff --quiet fork-sync/target HEAD; then
    git diff --stat fork-sync/target HEAD
    fail "the replay differs from the merge: in $worktree, commit each file from fork-sync/target as a fixup of the commit it belongs to, then run $0 --finish"
fi
result="$(git rev-parse HEAD)"
cd "$root"
git worktree remove "$worktree"
git switch -q "$branch"
git reset -q --hard "$result"
git branch -D -q fork-sync/merge fork-sync/build fork-sync/target
git config --unset fork-sync.branch
rm -rf "$root/.git/refs/original"

step "done: $(git rev-list --count upstream/main..HEAD) fork commits on upstream $(git rev-parse --short upstream/main)"
key="$(python3 Scripts/control-plane/chromium_engine.py tag)"
repo="$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')"
if gh release view "$key" -R "$repo" >/dev/null 2>&1; then
    step "engine $key is published"
else
    step "engine $key is NOT published: run task engine:build, then task engine:publish"
fi
