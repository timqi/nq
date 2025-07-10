#!/usr/bin/env python3

import os
import subprocess
import sys
import signal


def log(*msg):
    print(*msg, file=sys.stderr)


def find_ssh_sock():
    results = []
    for path in os.listdir("/tmp"):
        if path.startswith("ssh-") and not path.startswith("ssh-wsl"):
            p = "/tmp/" + path
            if check_file_owner_is_me(p):
                for f in os.listdir(p):
                    if f.startswith("agent."):
                        results.append(p + "/" + f)
    results.sort(key=lambda d: os.path.getmtime(d), reverse=True)
    return results[0] if results else None


def check_file_owner_is_me(path):
    return os.stat(path).st_uid == os.getuid()


# main logic
log("current agent:", os.getenv("SSH_AUTH_SOCK"))
ssh_connection = os.getenv("SSH_CONNECTION")
if ssh_connection:
    agent = find_ssh_sock()
    log("find agent:", agent)
    print(agent)
    sys.exit(0)


# handle wsl
wsl = os.getenv("WSL_DISTRO_NAME")
wsl_ssh_agent = "/tmp/ssh-wsl.agent"
log("wsl:", wsl, "use:", wsl_ssh_agent)
print(wsl_ssh_agent)
env = os.environ.copy()
env["SSH_AUTH_SOCK"] = wsl_ssh_agent


def kill_old_wsl_agent():
    if os.path.exists(wsl_ssh_agent):
        os.remove(wsl_ssh_agent)

    cmd = "ps -auxww | grep '//./pipe/openssh-ssh-agent' | grep -v grep | awk '{print $2}'"
    pids = subprocess.check_output(cmd, text=True, shell=True)
    for pid in pids.split():
        with open(f"/proc/{pid}/cmdline") as f:
            proc = f.read().strip()
        os.kill(int(pid), signal.SIGKILL)
        log(pid, "killed", proc)


def create_wsl_agent():
    kill_old_wsl_agent()
    cmd = [
        "setsid",
        "socat",
        f"UNIX-LISTEN:{wsl_ssh_agent},fork",
        "EXEC:npiperelay.exe -ei -s //./pipe/openssh-ssh-agent,nofork",
    ]
    log("Starting socat/npiperelay with:", " ".join(cmd))
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, close_fds=True)
    log("Success!")


try:
    output = subprocess.check_output(["ssh-add", "-l"], env=env, stderr=subprocess.STDOUT, text=True)
    log("ssh-add -l check result:\n", output.strip())
    expected_key_substring = "ED25519"
    if expected_key_substring in output:
        log("Success!")
        sys.exit(0)
    log("Key NOT found in ssh-agent, recreating...")
    create_wsl_agent()
    # Find and kill processes holding '//./pipe/openssh-ssh-agent'
except Exception as e:
    log("ssh-add -l failed:", e.output.strip())
    create_wsl_agent()
