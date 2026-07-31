#!/usr/bin/env python3
import os
import sys
import subprocess
import re

def main():
    gitmodules_path = ".gitmodules"
    if not os.path.exists(gitmodules_path):
        print("No .gitmodules file found.")
        return

    with open(gitmodules_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Parse [submodule "..."] blocks
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

        # Recursively update submodules inside the cloned submodule if any
        if os.path.exists(os.path.join(path, ".gitmodules")):
            print(f"Fetching nested submodules for {path}...")
            subprocess.run(["git", "submodule", "update", "--init", "--recursive", "--depth", "1"], cwd=path)

if __name__ == "__main__":
    main()
