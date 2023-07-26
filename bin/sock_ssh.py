#!/usr/bin/env python3

import os


def find_ssh_sock():
    for path in os.listdir("/tmp"):
        if path.startswith("ssh-"):
            p = "/tmp/" + path
            if check_file_owner_is_me(p):

                for f in os.listdir(p):
                    if f.startswith("agent."):
                        return p + "/" + f


def check_file_owner_is_me(path):
    return os.stat(path).st_uid == os.getuid()


print(find_ssh_sock())
