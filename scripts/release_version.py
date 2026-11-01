#!/usr/bin/env python3
"""
Automated Monorepo Semantic Versioning based on Conventional Commits.
Supports independent component versioning (e.g. tofu-v*, ansible-v*).
"""

import re
import subprocess
import sys

COMPONENTS = {
    "tofu": {
        "prefix": "tofu-v",
        "paths": ["infrastructure/"],
        "scope_filter": "tofu",
    },
    "ansible": {
        "prefix": "ansible-v",
        "paths": ["ansible/", "bootstrap/"],
        "scope_filter": "ansible",
    },
}


def run_cmd(cmd):
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
    return result.stdout.strip()


def parse_semver(tag_str, prefix):
    clean = tag_str.replace(prefix, "")
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)$", clean)
    if not match:
        return (0, 1, 0)
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)))


def get_latest_tag(prefix):
    try:
        tags = run_cmd(["git", "tag", "-l", f"{prefix}*"]).splitlines()
        valid_tags = []
        for t in tags:
            try:
                valid_tags.append((parse_semver(t, prefix), t))
            except Exception:
                continue
        if not valid_tags:
            return None, (0, 1, 0)
        valid_tags.sort(key=lambda x: x[0])
        return valid_tags[-1][1], valid_tags[-1][0]
    except Exception:
        return None, (0, 1, 0)


def determine_bump(commits):
    has_breaking = False
    has_feat = False
    has_fix_or_other = False

    for msg in commits:
        if "BREAKING CHANGE" in msg or re.search(r"^[a-z]+(\([^\)]+\))?!:", msg):
            has_breaking = True
        elif re.search(r"^feat(\([^\)]+\))?:", msg):
            has_feat = True
        else:
            has_fix_or_other = True

    if has_breaking:
        return "major"
    elif has_feat:
        return "minor"
    elif has_fix_or_other:
        return "patch"
    return None


def bump_version(current_tuple, bump_type):
    major, minor, patch = current_tuple
    if bump_type == "major":
        return (major + 1, 0, 0)
    elif bump_type == "minor":
        return (major, minor + 1, 0)
    elif bump_type == "patch":
        return (major, minor, patch + 1)
    return current_tuple


def get_commits_since(tag, paths):
    cmd = ["git", "log", "--pretty=format:%s"]
    if tag:
        cmd.append(f"{tag}..HEAD")
    cmd.append("--")
    cmd.extend(paths)
    try:
        out = run_cmd(cmd)
        return [line.strip() for line in out.splitlines() if line.strip()]
    except Exception:
        return []


def main():
    component = sys.argv[1] if len(sys.argv) > 1 else "all"
    targets = [component] if component in COMPONENTS else list(COMPONENTS.keys())

    for comp in targets:
        cfg = COMPONENTS[comp]
        prefix = cfg["prefix"]
        latest_tag, current_ver = get_latest_tag(prefix)
        commits = get_commits_since(latest_tag, cfg["paths"])

        if not commits:
            print(f"[{comp}] No changes detected since last tag ({latest_tag or 'initial'}). Skipping.")
            continue

        bump = determine_bump(commits) or "patch"
        new_tuple = bump_version(current_ver, bump) if latest_tag else current_ver
        new_tag = f"{prefix}{new_tuple[0]}.{new_tuple[1]}.{new_tuple[2]}"

        print(f"[{comp}] Latest: {latest_tag or 'None'} -> Next: {new_tag} (Bump: {bump})")
        print(f"[{comp}] Commits analyzed ({len(commits)}):")
        for c in commits[:5]:
            print(f"  - {c}")

        if "--tag" in sys.argv:
            print(f"Creating tag {new_tag}...")
            subprocess.run(["git", "tag", "-a", new_tag, "-m", f"release({comp}): {new_tag}"], check=True)
            subprocess.run(["git", "push", "origin", new_tag], check=True)
            try:
                subprocess.run(["git", "push", "gitea", new_tag], check=True)
            except Exception:
                pass


if __name__ == "__main__":
    main()
