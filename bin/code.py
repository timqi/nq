#!/usr/bin/env python3
import argparse
import glob
import json
import os
import queue
import shutil
import socket
import subprocess
import time

generate_cfg = {
    "local": {
        "~/Documents/Backups/linked": "",
        "~/Documents/Stash/datagrip": "DB",
        "~/Documents/Stash/toys": "PY",
        "~/.config/nq": "PY",
        "~/go/src/research": 2,
        "~/go/src/gitlab.fish": 3,
        "~/go/src/github.com": 2,
    },
    "ssh.xy2": {
        "~/Documents/Stash/datagrip": "DB",
        "~/go/src/research": 1,
        "~/go/src/gitlab.fish": 3,
        "~/go/src/github.com": 2,
    },
    "ssh.devhost": {
        "~/scripts": "PY",
        "~/go/src/research": 2,
        "~/go/src/gitlab.fish": 3,
        "~/go/src/github.com": 2,
    },
}


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

    stdout = stderr = code = ""
    if isin_ssh():
        ipcs = glob.glob(f"/run/user/{os.getuid()}/vscode-ipc-*")
        ipcs.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        for ipc in ipcs[:20]:
            # print("ipc", ipc, "cmds", cmds)
            stdout, stderr, code = _run(" ".join(cmds), env={"VSCODE_IPC_HOOK_CLI": ipc})
            if code == 0:
                return
    else:
        stdout, stderr, code = _run(" ".join(cmds))
        if code == 0:
            time.sleep(1)
            return
    print("Open code failed:", stderr)


def get_profile_of_directory(directory):
    level1 = [f.lower() for f in os.listdir(directory)]
    profile = ""
    if any(i in level1 for i in ["dfw.py", "requirements.txt", "pyproject.toml"]):
        profile = "PY"
    elif [any(f.endswith(suffix) for suffix in [".py", ".ipynb"]) for f in level1].count(True) > 1:
        profile = "PY"
    elif any(i in level1 for i in ["package.json", "yarn.lock"]):
        profile = "JS"
    elif any(i in level1 for i in ["go.mod", "go.sum"]):
        profile = "GO"
    elif any(i in level1 for i in ["cargo.toml"]):
        profile = "RS"
    elif any(i in level1 for i in ["cmakelists.txt"]):
        profile = "CC"
    return profile


def resolve_cfg(cfg):
    q, results = queue.Queue(), {}
    for directory, limit in cfg.items():
        directory = os.path.realpath(os.path.expanduser(directory))
        q.put((directory, limit, 0, []))
    while not q.empty():
        directory, limit, depth, proj_arr = q.get()
        directory = os.path.realpath(os.path.expanduser(directory))
        if isinstance(limit, str):
            results[directory] = limit, os.path.basename(directory)
            continue
        if any(i in os.listdir(directory) for i in [".root", ".git"]):
            results[directory] = get_profile_of_directory(directory), " / ".join(proj_arr)
            continue
        for file in os.listdir(directory):
            file = os.path.realpath(os.path.join(directory, file))
            if os.path.isdir(file) and depth < limit:
                q.put((file, limit, depth + 1, proj_arr + [os.path.basename(file)]))
    return results


def generate_project_index(keys):
    if keys == "list":
        bin = os.path.realpath(__file__)
        result = [{"title": "generate vscode proj index: all", "arg": f"{bin} --generate all"}]
        result += [
            {"title": f"generate vscode proj index: {key}", "arg": f"{bin} --generate {key}"}
            for key in generate_cfg.keys()
        ]
        return print(json.dumps({"items": result}, indent=2))

    # parse result from configuration
    keys = list(generate_cfg.keys()) if keys == "all" else [key for key in keys.split(",") if key in generate_cfg]
    generated = {}
    for key in keys:
        cfg = generate_cfg[key]
        if key.startswith("ssh."):
            hostname = key.lstrip("ssh.")
            if not isin_ssh() and socket.gethostname() == hostname:
                continue
            if isin_ssh():
                return print(json.dumps(resolve_cfg(cfg), indent=2))
            out, err, code = _run(f"scp -O {os.path.realpath(__file__)} {hostname}:/tmp/code.py")
            if code != 0:
                return print("scp failed:", err)
            out, err, code = _run(f"ssh {hostname} env python3 /tmp/code.py --generate {key}")
            if code != 0:
                return print("ssh", key, "code:", code, "failed:", err)
            try:
                generated[key] = json.loads(out)
            except Exception as e:
                return print("error decode json:", out)
            _run(f"ssh {hostname} rm /tmp/code.py")
        else:
            generated[key] = resolve_cfg(cfg)

    # generate alfred datastructure
    dest_dir = "/Users/qiqi/.cache/alfred/vscode/"
    sshs_file_path = os.path.join(dest_dir, "ssh.json")
    sshs_ori = []
    if os.path.exists(sshs_file_path):
        with open(sshs_file_path) as f:
            sshs_ori = json.load(f).get("items", [])
    locals, sshs = [], []
    for key, result in generated.items():
        print("handle key:", key)
        is_ssh = key.startswith("ssh.")
        host = key.split(".")[1] if is_ssh else ""
        subtitle_prefix = f"[{host}] " if is_ssh else ""
        if is_ssh:
            sshs_ori = list(filter(lambda x: f"[{host}]" not in x["subtitle"], sshs_ori))
        for path, v in result.items():
            arr = sshs if is_ssh else locals
            args = ["code"]
            if v[0]:
                args += ["--profile", v[0]]
            if is_ssh:
                uri = f"vscode-remote://ssh-remote+{host}{path}"
                args += ["--folder-uri", uri]
            else:
                args += [path]
            arr.append(
                {
                    "title": v[1],
                    "subtitle": f"{subtitle_prefix}{path}",
                    "arg": " ".join(args),
                }
            )
    # persist into cache file
    if len(locals) > 0:
        with open(os.path.join(dest_dir, "local.json"), "w") as f:
            json.dump({"items": locals}, f, indent=2)
        print("local.json generated")
    if len(sshs) > 0:
        sshs += sshs_ori
        with open(os.path.join(dest_dir, "ssh.json"), "w") as f:
            json.dump({"items": sshs}, f, indent=2)
        print("ssh.json generated")


def create_args_parser():
    parser = argparse.ArgumentParser(description="Hello World!")
    parser.add_argument("uri", help="Folder or uri to process", nargs="*", default=".")
    parser.add_argument("-g", "--generate", default=None, help="Generate code project index")
    parser.add_argument("--patchpilot", default=None, type=str, help="Patch copilot token")
    return parser


def patchpilot(token):
    def patch_dir(d):
        for folder in os.listdir(d):
            if not folder.startswith("github.copilot"):
                continue
            p = os.path.join(d, folder, "dist/extension.js")
            if not os.path.exists(p):
                continue
            with open(p, "r+") as f:
                r = f.read()
                if not r:
                    continue
                print("will patch:", p)
                r = r.replace(
                    "headers:{Authorization:`token ${t.token}`",
                    "headers:{Authorization:`token %s`" % token,
                )
                f.write(r)

    home = os.path.expanduser("~")
    d = os.path.join(home, ".vscode/extensions")
    if os.path.exists(d):
        patch_dir(d)


def main():
    parser = create_args_parser()
    args = parser.parse_args()
    if args.generate is not None:
        generate_project_index(args.generate)
    elif args.patchpilot is not None:
        patchpilot(args.patchpilot)
    else:
        run_code(args.uri)


if __name__ == "__main__":
    main()
