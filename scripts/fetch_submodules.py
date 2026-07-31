#!/usr/bin/env python3
import os
import sys
import subprocess

def fix_non_root_module_bazel(submodule_path):
    """
    Bazel 8 forbids `include()` directives in non-root MODULE.bazel files.
    Comment out any `include(...)` lines in cloned submodules.
    """
    module_bazel = os.path.join(submodule_path, "MODULE.bazel")
    if os.path.exists(module_bazel):
        try:
            with open(module_bazel, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
            new_lines = []
            modified = False
            for line in lines:
                stripped = line.strip()
                if stripped.startswith("include(") or stripped.startswith("include ("):
                    new_lines.append(f"# [Patched for Bazel 8 non-root] {line}")
                    modified = True
                else:
                    new_lines.append(line)
            if modified:
                with open(module_bazel, "w", encoding="utf-8") as f:
                    f.writelines(new_lines)
                print(f"Patched non-root include() in {module_bazel}")
        except Exception as e:
            print(f"Warning: Could not patch {module_bazel}: {e}")

def main():
    gitmodules_path = ".gitmodules"
    if not os.path.exists(gitmodules_path):
        print("No .gitmodules file found.")
        return

    with open(gitmodules_path, "r", encoding="utf-8") as f:
        content = f.read()

    submodules = []
    current_path = None
    current_url = None

    for line in content.splitlines():
        line = line.strip()
        if line.startswith("[submodule"):
            if current_path and current_url:
                submodules.append((current_path, current_url))
            current_path = None
            current_url = None
        elif line.startswith("path =") or line.startswith("path="):
            current_path = line.split("=", 1)[1].strip()
        elif line.startswith("url =") or line.startswith("url="):
            current_url = line.split("=", 1)[1].strip()

    if current_path and current_url:
        submodules.append((current_path, current_url))

    print(f"Found {len(submodules)} submodules in .gitmodules")

    for path, url in submodules:
        print(f"\n--- Processing submodule: {path} ---")
        if os.path.exists(path) and os.listdir(path):
            print(f"Directory {path} already exists and is not empty. Skipping clone.")
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            print(f"Cloning {url} -> {path}...")
            cmd = ["git", "clone", "--depth", "1", url, path]
            res = subprocess.run(cmd)
            if res.returncode != 0:
                print(f"Warning: Failed to clone {url} to {path}")

        # Fix any Bazel 8 non-root include() error in this submodule
        fix_non_root_module_bazel(path)

        # Recursively update submodules inside the cloned submodule if any
        if os.path.exists(os.path.join(path, ".gitmodules")):
            print(f"Fetching nested submodules for {path}...")
            subprocess.run(["git", "submodule", "update", "--init", "--recursive", "--depth", "1"], cwd=path)
            # Fix nested submodules too
            for root, dirs, files in os.walk(path):
                if "MODULE.bazel" in files and root != ".":
                    fix_non_root_module_bazel(root)

if __name__ == "__main__":
    main()
