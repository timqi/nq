#!/usr/bin/env python
import argparse
import os
import shutil
import subprocess
import sys

zoxide_bin = None
zoxide_exist_path = []


def _run(cmd, stdin=None):
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stdin=subprocess.PIPE,
        shell=True,
        env=os.environ,
    )
    if isinstance(stdin, str):
        stdin = stdin.encode("utf8")
    stdout, stderr = p.communicate(input=stdin)
    return (
        stdout.decode("utf-8").strip() if stdout else "",
        stderr.decode("utf-8").strip() if stderr else "",
    )


def handle_path(path):
    global zoxide_bin, zoxide_exist_path
    if path in zoxide_exist_path:
        return
    _run(f"{zoxide_bin} add '{path}'")


def handle_path_and_depth(path, depth):
    base = path
    queue = [("", 0)]
    while queue:
        sub = queue.pop(0)
        subdir, curr_depth = sub[0], sub[1]
        subfull = os.path.join(os.path.expanduser(base), subdir)
        if not os.path.exists(subfull):
            continue
        handle_path(subfull)
        for dir in os.listdir(subfull):
            path = os.path.join(subfull, dir)
            if not os.path.isdir(path):
                continue
            for flag in [".git", ".root"]:
                if os.path.exists(os.path.join(path, flag)):
                    handle_path(path)
                    break
            if curr_depth < depth:
                queue.append((os.path.join(subdir, dir), curr_depth + 1))


def verify_zoxide():
    global zoxide_bin, zoxide_exist_path
    zoxide_bin = shutil.which("zoxide")
    stdout, stderr = _run(f"{zoxide_bin} query -l")
    if stderr:
        print(stderr)
        return False
    zoxide_exist_path = stdout.splitlines()
    for p in zoxide_exist_path:
        if not os.path.exists(p):
            _run(f"{zoxide_bin} remove '{p}'")
            zoxide_exist_path.remove(p)
    return True


if __name__ == "__main__":
    if not verify_zoxide():
        print("No zoxide binary found.")
        sys.exit(0)

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--directory",
        default=None,
        type=str,
        help="Directory will be scanned from",
    )
    parser.add_argument(
        "-d",
        "--depth",
        type=int,
        default=0,
        help="Level depths will be scanned under directory",
    )
    args = parser.parse_args()
    if not args.directory:
        import yaml

        with open(
            os.path.join(
                "/Users/qiqi/Documents/Backups/alfred/Alfred.alfredpreferences",
                "workflows/alfred_py/vscode.gen.config.yaml",
            ),
            "r",
        ) as f:
            cfg = yaml.load(f, Loader=yaml.FullLoader)
        cfg = cfg.get("local", {})
        for item in cfg.get("scan_folders", []):
            handle_path_and_depth(item.get("path"), item.get("depth"))
        for item in cfg.get("manual", []):
            handle_path(item.get("path"))
    else:
        handle_path_and_depth(args.directory, args.depth)
