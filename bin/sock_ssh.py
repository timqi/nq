#!/usr/bin/env python3

import os
import sys


def log(*msg):
    print(*msg, file=sys.stderr)


def find_ssh_sock():
    results = []
    for path in os.listdir("/tmp"):
        if path.startswith("ssh-"):
            p = "/tmp/" + path
            if not os.path.isdir(p):
                continue
            if check_file_owner_is_me(p):
                for f in os.listdir(p):
                    if f.startswith("agent."):
                        results.append(p + "/" + f)
    results.sort(key=lambda d: os.path.getmtime(d), reverse=True)
    return results[0] if results else None


def check_file_owner_is_me(path):
    return os.stat(path).st_uid == os.getuid()


print(find_ssh_sock())
