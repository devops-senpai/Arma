#!/usr/bin/env python3
"""Replays the fork's commits onto upstream as one commit per change.

    Scripts/fork/regroup.py <plan.json>

The plan is a list of {"id", "commits", "message"} groups, replayed in order.
Run inside a worktree started at upstream/main, with REGROUP_TARGET (default
fork-sync/target) naming the tree the result must match. Resumable: groups already committed (by
marker trailer) are skipped. On a conflict it resolves each file to the
target tree's content minus the edits of commits still to come; a file it
cannot resolve stops the run for a person.
"""
import json, os, subprocess, sys

TARGET = os.environ.get("REGROUP_TARGET", "fork-sync/target")

PLAN = json.load(open(sys.argv[1]))


def git(*args, check=True, input=None):
    r = subprocess.run(["git", *args], capture_output=True, text=True, input=input)
    if check and r.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed:\n{r.stdout}\n{r.stderr}")
    return r


def later_commits(gi, ci):
    out = []
    for g in PLAN[gi:]:
        start = ci + 1 if g is PLAN[gi] else 0
        out += g["commits"][start:]
    return out


def touches(commit, path):
    return bool(git("show", "--format=", "--name-only", commit, "--", path).stdout.strip())


def resolve_from_target(path, later):
    exists = git("cat-file", "-e", f"{TARGET}:{path}", check=False).returncode == 0
    later_touching = [c for c in later if touches(c, path)]
    if not exists:
        # Deleted in the end; deleted now unless a later commit recreates it.
        if later_touching:
            return False
        git("rm", "-q", "--force", path, check=False)
        return True
    content = git("show", f"{TARGET}:{path}").stdout
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    for c in reversed(later_touching):
        patch = git("show", "--format=", c, "--", path).stdout
        r = subprocess.run(["git", "apply", "-R", "--recount"], input=patch, capture_output=True, text=True)
        if r.returncode != 0:
            return False
    git("add", "--", path)
    return True


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
            continue
        print(f"== {group['id']}  ({len(group['commits'])} commits)", flush=True)
        for ci, commit in enumerate(group["commits"]):
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
    main()
