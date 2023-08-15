#!/usr/bin/env python3
import glob
import os
import argparse
import shutil
import subprocess


def _run(cmd, env={}):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, env=env)
    stdout, stderr = p.communicate()
    return (
        stdout.decode("utf-8").strip() if stdout else "",
        stderr.decode("utf-8").strip() if stderr else "",
        p.returncode,
    )


def isin_ssh():
    return "SSH_CLIENT" in os.environ or "SSH_CONNECTION" in os.environ


def search_code_bin_ssh():
    g = os.path.expanduser("~/.vscode-server/bin/**/bin/remote-cli/code")
    file = glob.glob(g, recursive=True)
    return file[0] if file else None


def run_code(uri):
    bin = search_code_bin_ssh() if isin_ssh() else shutil.which("code")
    if not bin:
        raise Exception("code command not found")
    cmds = [bin]
    cmds += [uri] if ":" not in uri else ["--folder-uri", uri]

    if isin_ssh():
        ipcs = glob.glob(f"/run/user/{os.getuid()}/vscode-ipc-*")
        ipcs.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        for ipc in ipcs[:20]:
            # print("ipc", ipc, "cmds", cmds)
            stdout, stderr, code = _run(" ".join(cmds), env={"VSCODE_IPC_HOOK_CLI": ipc})
            # print("out", stdout, "err", stderr, "code", code)
            if code == 0:
                return
    print("Open code failed:", stderr)


def create_args_parser():
    parser = argparse.ArgumentParser(description="Hello World!")
    parser.add_argument("uri", help="Folder or uri to process", nargs="*", default=".")
    return parser


def main():
    parser = create_args_parser()
    args = parser.parse_args()
    run_code(args.uri)


if __name__ == "__main__":
    main()
