#!/usr/bin/env python3
import argparse
import glob
import importlib.util
import json
import os
import queue
import re
import shutil
import socket
import subprocess
import time

generate_cfg = {
    "local": {
        "~/Documents/Backups/linked": "",
        "~/Documents/Stash/toys": "PY",
        "~/.config/nq": "PY",
        "~/go/src/research": 2,
        "~/go/src/gitlab.fish": 3,
        "~/go/src/github.com": 2,
    },
    "ssh.devhost": {
        "~/scripts": "PY",
        "~/go/src/research": 2,
        "~/go/src/gitlab.fish": 3,
        "~/go/src/github.com": 2,
    },
    "ssh.gb0": {
        "~/go/src/research": 2,
        "~/go/src/github.com": 2,
    },
}


def load_file_as_module(file_path):
    spec = importlib.util.spec_from_loader("", loader=None)
    module = importlib.util.module_from_spec(spec)
    with open(file_path, "r") as f:
        code_string = f.read()
    exec(code_string, module.__dict__)
    return module


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
    g = os.path.expanduser("~/.vscode-server/cli/servers/**/server/bin/remote-cli/code")
    file = glob.glob(g, recursive=True)
    return file[0] if file else None


def run_code(uri):
    bin = search_code_bin_ssh() if isin_ssh() else shutil.which("code")
    if not bin and not isin_ssh():
        raise Exception("code command not found")
    cmds = [bin]
    cmds += [uri] if ":" not in uri else ["--folder-uri", uri]
    print(cmds, bin, uri)

    stdout = stderr = code = ""
    if isin_ssh():
        ipcs = glob.glob(f"/run/user/{os.getuid()}/vscode-ipc-*")
        ipcs.sort(key=lambda x: os.path.getmtime(x), reverse=True)
        if len(ipcs) < 1:
            stderr = "No vscode server found."
        limit = 8
        for ipc in ipcs[:limit]:
            print("ipc", ipc, "cmds", cmds)
            stdout, stderr, code = _run(" ".join(cmds), env={"VSCODE_IPC_HOOK_CLI": ipc})
            if code == 0:
                break
        for ipc in ipcs[limit:]:
            os.remove(ipc)
    else:
        stdout, stderr, code = _run(" ".join(cmds))
        if code == 0:
            time.sleep(1)
    if stderr:
        print("Open code failed:", stderr)
        print("pwd:", os.getcwd())


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
        if not os.path.exists(directory):
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
    dest_dir = os.path.expanduser("~/.cache/alfred/vscode/")
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir, exist_ok=True)
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
            # if v[0]:
            #     args += ["--profile", v[0]]
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


def get_ssh(only_host=False):
    file = os.path.join(os.path.dirname(os.path.realpath(__file__)), "complete-fzf")
    m = load_file_as_module(file)
    hosts = m._parse_host()
    items, issh = [], os.path.join(os.path.dirname(__file__), "issh")
    for item in hosts:
        host, type = item["host"], item["type"]
        if host in ["github.com", "localhost"]:
            continue
        arg = host if only_host else f"{issh} {host}" if type == "fish" else f"ssh -A {host}"
        items.append({"title": host, "arg": arg})
    return json.dumps({"items": items})


def parse_tmux_project():
    tmux = os.path.join(os.path.dirname(__file__), "alacritty-tmux")
    out, err, _ = _run(f"{tmux} capture-pane -p")
    if err:
        raise Exception(err)
    result = re.findall(r"\s/[^\s]+\s", out)
    path = [p.strip() for p in result]
    if not path:
        raise Exception("valid path not found. length:", len(path))
    hosts, path = json.loads(get_ssh(True)), path[-1]
    for item in hosts["items"]:
        host = item["arg"]
        item["arg"] = f"code --folder-uri vscode-remote://ssh-remote+{host}{path}"
        item["subtitle"] = f"{path}"
    return json.dumps(hosts)


def create_args_parser():
    parser = argparse.ArgumentParser(description="Hello World!")
    parser.add_argument("uri", help="Folder or uri to process", nargs="?", default=".")
    parser.add_argument("-g", "--generate", default=None, help="Generate code project index")
    parser.add_argument("--parse-tmux-project", action="store_true", help="Parse tmux project in terminal")
    parser.add_argument("--clean", action="store_true", help="clean ~/.vscode-server")
    return parser


def clean_vscode_data(base_dir):
    base_dir = os.path.expanduser(base_dir)
    if not os.path.exists(base_dir):
        print("path not exists:", base_dir)
        return
    print("cleaning extensions:")
    exts_dir = os.path.join(base_dir, "extensions")
    j = os.path.join(exts_dir, "extensions.json")
    with open(j) as f:
        exts = json.load(f)

    all_exts = [d for d in os.listdir(exts_dir) if os.path.isdir(os.path.join(exts_dir, d))]
    for ext in exts:
        ext_path = ext.get("relativeLocation")
        all_exts.remove(ext_path)
    for ext in all_exts:
        ext_path = os.path.join(exts_dir, ext)
        if os.path.exists(ext_path):
            print("remove", ext_path)
            shutil.rmtree(ext_path)

    print("cleaning old servers:")
    code_servers = [d for d in os.listdir(base_dir) if d.startswith("code-")]

    def get_version(server):
        code_path = os.path.join(base_dir, server)
        if not os.path.exists(code_path):
            return "0.0.0"
        stdout, _, _ = _run(f"{code_path} --version")
        match = re.search(r"(\d+\.\d+\.\d+)", stdout)
        return match.group(1) if match else "0.0.0"

    code_servers.sort(key=lambda d: [int(x) for x in get_version(d).split(".")])
    print("valid server version:", code_servers[-1], "(" + get_version(code_servers[-1]) + ")")
    invalid_hash = [h.split("-")[-1] for h in code_servers[:-1]]
    for bin in os.listdir(os.path.join(base_dir)):
        if bin.startswith("code-") and bin.split("-")[-1] in invalid_hash:
            bin_path = os.path.join(base_dir, bin)
            print("remove bin", bin_path)
            os.remove(bin_path)
    for server in os.listdir(os.path.join(base_dir, "cli", "servers")):
        for h in invalid_hash:
            if h in server:
                server_path = os.path.join(base_dir, "cli", "servers", server)
                print("remove server", server_path)
                shutil.rmtree(server_path)

    print("cleaning logs of cli")
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.startswith(".cli") and file.endswith(".log"):
                log_path = os.path.join(root, file)
                print(f"removing log file: {log_path}")
                os.remove(log_path)


def main():
    parser = create_args_parser()
    args = parser.parse_args()
    if args.parse_tmux_project:
        print(parse_tmux_project())
    elif args.generate is not None:
        generate_project_index(args.generate)
    elif args.clean:
        clean_vscode_data("~/.vscode-server")
    else:
        run_code(args.uri)


if __name__ == "__main__":
    main()
