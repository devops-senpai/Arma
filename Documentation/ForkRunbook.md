# Fork runbook

How Arma keeps up with Crest, keeps its history readable, and ships a
release from a Mac. Each step is a `task` (see `Taskfile.yml`); run
`task --list` for the full set.

## History shape

`main` is upstream Crest's `main` plus one commit per thing Arma adds, with
no merge commits:

- A bug fix or performance change to Crest's own code is one commit,
  written so a Crest user can cherry-pick it alone.
- A feature Arma adds (themes, the terminal, Split View tiling, Servo,
  automation) is one commit holding the whole feature: every later tweak or
  fix to it is folded in, and its message describes the feature as it is
  now, not the order it was built in.
- Fixes and features come before `feat(identity): make the fork Arma`, so
  they apply to Crest without the rename. Arma-only changes (the rename,
  arma:// pages, the sync and release tooling) come after it.

To change an Arma feature, commit the change as a fixup of its commit:

```sh
git add <files>
task fixup -- 'feat(themes): theme library, Space themes, Arma crests and a theme-first setup'
```

`task sync` folds fixups as it replays: each joins the commit it names, even
when later commits changed the same files. `task fold` folds them on demand
with a plain rebase, which stops where a later commit touched the same lines;
leave those for the next sync.
A new bug fix or feature is an ordinary commit with its own release-note
entry file.

## Sync with upstream

```sh
task sync          # fold fixups, merge, replay, verify; nothing is pushed
task check build   # gates and a Debug build
task engine:key    # whether the Chromium engine for this tree is published
```

`task sync` merges upstream's `main` on a temporary branch with
`Scripts/sync-upstream.sh`, replays every fork commit onto upstream's `main`
with `Scripts/fork/regroup.py`, checks the result's tree is the merge's tree,
and resets the branch onto it. The old head stays as `backup/pre-sync-<time>`.

When the merge conflicts, resolve the files on `fork-sync/merge`, stage
them, run `Scripts/sync-upstream.sh --continue`, then `task sync:replay`.
When upstream fixed what a fork commit fixed, keep upstream's version; the
fork commit replays empty and is dropped.

A file edited by hand in the merge without having conflicted, such as a fork
patch rebased onto a new upstream patch, belongs to no replayed commit, and
the replay stops because it differs from the merge. In the replay worktree
the script names, check the file out from `fork-sync/target`, commit it as
`fixup! <subject of the commit it belongs to>`, and run
`Scripts/fork/sync.sh --finish`.

Push only when the owner says so: `git push --force-with-lease origin main`.

## Chromium engine

A change to the engine inputs (`CrestEngines/Chromium` patches, overlay,
host header and lock, and the control-plane prepare, apply, configure and
build scripts) changes the engine key. Before the next release:

```sh
task engine:build     # hours, on the build Mac
task engine:publish   # uploads chromium-engine-<key> to this repository
```

Newer engines:

```sh
task engines:check                  # Chromium, WebKit and Servo at once
task chromium:update -- <version>   # a newer Chrome on the same major; a new major needs its patches reviewed
task servo:update                   # pin the newest servo crate and rebuild libarma_servo
```

WebKit is the system framework: it moves with macOS and Xcode updates, which
`task webkit:check` lists.

## Release

Every release is tried by the owner before it goes to Apple:

1. `task release` builds a Developer ID signed `Arma-<version>.app` in
   `~/code/ArmaBuild` (`ARMA_WITH_SERVO=1 task release` adds the Servo engine,
   left out of releases until it is stable).
2. With the owner's go-ahead, install it over `/Applications/Arma.app`, keeping
   the copy it replaces as `~/code/ArmaBuild/Arma-prev.app`. A locally built,
   signed app runs without notarization, so the owner tries it here.
3. Once the owner says it is good, `task notarize` notarizes and staples the
   app, then builds and notarizes its DMG. Never chain it after `task release`.
4. Push `main`, then publish (below).

Signing values come from `~/.config/arma/signing.sops.yaml` (age key
`~/.ssh/key.txt`); the scripts read them with `sops` and never print them.
The keys are `team_id`, `developer_id_identity`, `developer_id_sha1`,
`notary_keychain_profile`, `app_store_connect_*`, `signing_identities_p12_*`,
`developer_id_certificate_cer_base64`, `sparkle_eddsa_private_key` and
`developer_id_provisioning_profile_*`.

Notarization usually takes minutes; a new account's first submissions can
take hours. `xcrun notarytool history --keychain-profile <profile>` shows
where they are.

Publish with the owner's go-ahead, once main is pushed:

```sh
task publish -- <notes.md>   # GitHub release v<version>, then the signed update feeds
```

It creates the release from `main` with the installer and adds the installer
to the signed Sparkle feeds on the `updates` branch, which the app's Check for
Updates reads (`SUFeedURL`, checked against `SUPublicEDKey`). Release builds
follow the Development channel. Sparkle compares build numbers, so
`task release` builds X.Y.Z as X*10^7 + Y*10^5 + Z.


## Testing a build

Launch a copy with `CREST_ISOLATED_SESSION=1`, a persistence identifier and
its own `--user-data-dir`, so it never touches the owner's data, and drive it
with the bundled `arma` helper. When done, quit it, unregister it with
`lsregister -u`, then delete it.
