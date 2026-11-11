#!/usr/bin/env python3
"""Replays the fork's commits onto upstream as one commit per change.

    Scripts/fork/regroup.py <plan.json>
    Scripts/fork/regroup.py plan <base> <head> <plan.json>

The plan is a list of {"id", "commits", "order", "message"} groups, replayed
in order. `plan` writes one from the commits of <base>..<head>: a group per
commit, with each "fixup! <subject>" commit in the group of the commit it
names, so it folds there. "order" is where each commit stood in that history.

Run the replay inside a worktree started at upstream/main, with REGROUP_TARGET
(default fork-sync/target) naming the tree the result must match. Resumable:
groups already committed (by marker trailer) are skipped. On a conflict it
resolves each file to the target tree's content minus the edits of commits
still to come, following the file through their renames. An edit that shares
a line with a later one cannot be taken back out, so that line keeps the
target's text and reaches its own commit already written. A file it cannot
resolve stops the run for a person.
"""
import functools, json, os, subprocess, sys, tempfile

TARGET = os.environ.get("REGROUP_TARGET", "fork-sync/target")


def git(*args, check=True, input=None):
    r = subprocess.run(["git", *args], capture_output=True, text=True, input=input)
    if check and r.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed:\n{r.stdout}\n{r.stderr}")
    return r


def write_plan(base, head, out):
    """One group per commit of base..head, a fixup commit in the group of the commit it names."""
    commits = git("rev-list", "--reverse", f"{base}..{head}").stdout.split()
    plan, named = [], {}
    for i, c in enumerate(commits):
        message = git("log", "-1", "--format=%B", c).stdout
        subject = message.split("\n", 1)[0]
        if subject.startswith("fixup! "):
            while subject.startswith("fixup! "):
                subject = subject[len("fixup! "):]
            if subject not in named:
                raise SystemExit(f"{c[:9]} is a fixup of '{subject}', which no earlier commit is named")
            named[subject]["commits"].append(c)
            named[subject]["order"].append(i)
            continue
        group = {"id": f"c{i:03d}-{c[:9]}", "commits": [c], "order": [i], "message": message}
        plan.append(group)
        named[subject] = group
    json.dump(plan, open(out, "w"))


def later_commits(gi, ci):
    """The commits still to come after commit `ci` of group `gi`, as the old history ordered them."""
    out = []
    for g in PLAN[gi:]:
        start = ci + 1 if g is PLAN[gi] else 0
        out += g["commits"][start:]
    return sorted(out, key=ORDER.get)


def touches(commit, path):
    return bool(git("show", "--format=", "--name-only", commit, "--", path).stdout.strip())


@functools.lru_cache(maxsize=None)
def changes(commit):
    """The renames `commit` made, old name to new, and the paths it added."""
    renamed, added = {}, set()
    for line in git("show", "--format=", "--name-status", "-M", commit).stdout.splitlines():
        status, *paths = line.split("\t")
        if status.startswith("R"):
            renamed[paths[0]] = paths[1]
        elif status == "A":
            added.add(paths[0])
    return renamed, added


def blob(commit, path):
    r = git("rev-parse", "--verify", "-q", f"{commit}:{path}", check=False)
    return r.stdout.strip() if r.returncode == 0 else None


# New name to old name, for the renames of commits already replayed. A fixup
# replays earlier than it was written, so commits still to come know a file it
# renamed by the old name.
MOVED = {}


def resolve_from_target(path, later):
    """`path` as the target has it, less what the commits still to come do to it."""
    known = {path}
    name = path
    while name in MOVED:
        name = MOVED[name]
        known.add(name)
    final = path
    edits = []  # (commit, the file's name before it or None when it adds the file, its name after)
    for c in later:
        renamed, added = changes(c)
        source = next((n for n in known if n in renamed), None)
        if source is not None:
            edits.append((c, source, renamed[source]))
            if source == final:
                final = renamed[source]
            known.add(renamed[source])
            continue
        for n in sorted(known):
            if n in added:
                edits.append((c, None, n))
                break
            if touches(c, n):
                edits.append((c, n, n))
                break
    if blob(TARGET, final) is None:
        # Deleted in the end; deleted now unless a later commit recreates it.
        if edits:
            return False
        git("rm", "-q", "--force", path, check=False)
        return True
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        f.write(git("show", f"{TARGET}:{final}").stdout)
    for position, (c, before, after) in enumerate(reversed(edits)):
        if before is None:
            # The commit adds the file: before it there is none, and nothing earlier can touch it.
            if position != len(edits) - 1:
                return False
            os.remove(path)
            git("rm", "-q", "--force", "--", path, check=False)
            return True
        old, new = blob(f"{c}^", before), blob(c, after)
        if old is None or new is None:
            return False
        if old != new and not take_back(path, new, old):
            print(f"   {path}: kept text {c[:9]} writes, on a line an earlier edit shares", flush=True)
    git("add", "--", path)
    return True


def take_back(path, after, before):
    """Undoes in `path` the edit that turned blob `before` into `after`: a three-way merge
    from `after` toward `before`. Where the file has since changed the same lines, they keep
    the file's own text. Answers whether the whole edit came out."""
    with tempfile.TemporaryDirectory() as scratch:
        sides = []
        for label, sha in (("after", after), ("before", before)):
            side = os.path.join(scratch, label)
            with open(side, "w") as f:
                f.write(git("cat-file", "blob", sha).stdout)
            sides.append(side)
        clean = subprocess.run(["git", "merge-file", "-p", "-q", path, *sides], capture_output=True).returncode == 0
        subprocess.run(["git", "merge-file", "-q", "--ours", path, *sides], capture_output=True)
    return clean


def resolve_from_original(path, commit):
    """The file as `commit` left it in the old history."""
    r = git("show", f"{commit}:{path}", check=False)
    if r.returncode != 0:
        git("rm", "-q", "--force", path, check=False)
        return True
    with open(path, "w") as f:
        f.write(r.stdout)
    git("add", "--", path)
    print(f"   {path}: took {commit}'s own version", flush=True)
    return True


GENERATED = ("CrestContracts/include/", "CrestCore/src/CrestCore.Native/Generated/",
             "CrestShared/Infrastructure/Core/Generated/")


def is_generated(path):
    return path.startswith(GENERATED) or path == "Crest.xcodeproj/project.pbxproj"


def regenerate():
    env = dict(os.environ)
    env["PATH"] = os.path.expanduser("~/.dotnet") + ":" + env["PATH"]
    env["DOTNET_ROOT"] = os.path.expanduser("~/.dotnet")
    for cmd in (["Scripts/control-plane/generate-contracts.sh"], ["xcodegen", "generate", "--quiet"]):
        r = subprocess.run(cmd, capture_output=True, text=True, env=env)
        if r.returncode != 0:
            print(f"   regenerate {cmd[0]} failed:\n{r.stdout[-1500:]}\n{r.stderr[-1500:]}", flush=True)
            return False
    git("add", "--", "CrestContracts/include", "CrestCore/src/CrestCore.Native/Generated",
        "CrestShared/Infrastructure/Core/Generated", "Crest.xcodeproj/project.pbxproj")
    return True


def committed_groups():
    log = git("log", "--format=%B%x00", "upstream/main..HEAD").stdout
    return {line.split(": ", 1)[1].strip() for line in log.splitlines() if line.startswith("Regroup-Id: ")}


def main():
    done = committed_groups()
    for gi, group in enumerate(PLAN):
        if group["id"] in done:
            for commit in group["commits"]:
                MOVED.update({new: old for old, new in changes(commit)[0].items()})
            continue
        print(f"== {group['id']}  ({len(group['commits'])} commits)", flush=True)
        for ci, commit in enumerate(group["commits"]):
            MOVED.update({new: old for old, new in changes(commit)[0].items()})
            r = git("cherry-pick", "--no-commit", "--allow-empty", commit, check=False)
            if r.returncode == 0:
                continue
            unmerged = [p for p in git("diff", "--name-only", "--diff-filter=U").stdout.split("\n") if p]
            later = later_commits(gi, ci)
            generated = [p for p in unmerged if is_generated(p)]
            for p in generated:
                git("checkout", "--ours", "--", p, check=False)
                git("add", "--", p)
            stuck = [p for p in unmerged if not is_generated(p) and not resolve_from_target(p, later)
                     and not resolve_from_original(p, commit)]
            if generated and not stuck and not regenerate():
                stuck = generated
            if stuck:
                print(f"STUCK in {commit} on: {stuck}", flush=True)
                sys.exit(2)
            print(f"   resolved {len(unmerged)} file(s) in {commit}", flush=True)
        git("cherry-pick", "--quit", check=False)
        if not git("diff", "--cached", "--quiet", check=False).returncode:
            print("   (empty, upstream already has it; skipped)", flush=True)
            continue
        message = group["message"].rstrip() + f"\n\nRegroup-Id: {group['id']}\n"
        git("commit", "-q", "-F", "-", input=message)
    print("ALL DONE", flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "plan":
        write_plan(*sys.argv[2:5])
    else:
        PLAN = json.load(open(sys.argv[1]))
        # Where each commit stood in the history being replayed; replay order when the plan says nothing.
        ORDER = {}
        for group in PLAN:
            for commit, order in zip(group["commits"], group.get("order", [])):
                ORDER[commit] = order
        for commit in (c for group in PLAN for c in group["commits"]):
            ORDER.setdefault(commit, len(ORDER))
        main()
