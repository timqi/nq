#!/usr/bin/env python3
import argparse
import asyncio
import importlib.util
import json
import os
import subprocess
import sys
import urllib.parse
import urllib.request


def load_file_as_module(file_path):
    spec = importlib.util.spec_from_loader("", loader=None)
    module = importlib.util.module_from_spec(spec)
    with open(file_path, "r") as f:
        code_string = f.read()
    exec(code_string, module.__dict__)
    return module


def _run(cmd):
    print("cmd:", cmd, file=sys.stderr)
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    stdout, stderr = p.communicate()
    return (
        stdout.decode("utf-8").strip() if stdout else "",
        stderr.decode("utf-8").strip() if stderr else "",
    )


async def async_request(url, method="GET", data=None, headers=None):
    loop = asyncio.get_running_loop()
    request = urllib.request.Request(url, method=method, data=data, headers=headers or {})
    response = await loop.run_in_executor(None, urllib.request.urlopen, request)
    content = await loop.run_in_executor(None, response.read)
    return {
        "status_code": response.status,
        "reason": response.reason,
        "headers": dict(response.headers),
        "content": content.decode("utf-8"),
    }


def get_ssh(only_host=False):
    file = os.path.join(os.path.dirname(os.path.realpath(__file__)), "complete-fzf")
    m = load_file_as_module(file)
    hosts = m._parse_host()
    items, issh = [], "/Users/qiqi/.config/nq/bin/issh"
    for item in hosts:
        host, type = item["host"], item["type"]
        if host in ["github.com", "localhost"]:
            continue
        arg = host if only_host else f"{issh} {host}" if type == "fish" else f"ssh -A {host}"
        items.append({"title": host, "arg": arg})
    return json.dumps({"items": items})


async def get_cmc():
    url = "https://s3.coinmarketcap.com/generated/core/crypto/cryptos.json"
    resp = await async_request(url)
    if resp["status_code"] != 200:
        raise Exception(f"Request {url} failed: {resp['reason']}")
    obj = json.loads(resp["content"])
    coins = obj.get("values", [])
    items = [{"title": f"{coin[2]} {coin[1]}", "arg": coin[3]} for coin in coins]
    print("generated cmc items:", len(items))
    return json.dumps({"items": items})


async def get_binance():
    items = []
    api = "https://api.binance.com/api/v3/exchangeInfo"
    spot_resp = await async_request(api)
    if spot_resp["status_code"] != 200:
        raise Exception(f"Request {api} failed: {spot_resp['reason']}")
    spot_obj = json.loads(spot_resp["content"])
    for symbol in spot_obj.get("symbols", []):
        if "usd" not in symbol["quoteAsset"].lower():
            continue
        if "SPOT" not in symbol["permissions"]:
            continue
        arg = f"https://www.binance.com/en/trade/{symbol['baseAsset']}_{symbol['quoteAsset']}?layout=pro&type=spo"
        items.append({"title": f"spot: {symbol['baseAsset']} {symbol['quoteAsset']}", "arg": arg})
    print("generated spot items:", len(items))

    fapi = "https://fapi.binance.com/fapi/v1/exchangeInfo"
    fapi_resp = await async_request(fapi)
    if fapi_resp["status_code"] != 200:
        raise Exception(f"Request {fapi} failed: {fapi_resp['reason']}")
    future_obj = json.loads(fapi_resp["content"])
    for symbol in future_obj.get("symbols", []):
        arg = f"https://www.binance.com/en/futures/{symbol['baseAsset']}{symbol['quoteAsset']}"
        items.append({"title": f"future: {symbol['baseAsset']} {symbol['quoteAsset']}", "arg": arg})
    print("generated future items:", len(items))

    return json.dumps({"items": items})


def run(key):
    if key == "ssh":
        return get_ssh(False)
    elif key == "hostname":
        return get_ssh(True)
    elif key == "cmc":
        return asyncio.run(get_cmc())
    elif key == "binance":
        return asyncio.run(get_binance())
    print("No such command")


def create_args_parser():
    parser = argparse.ArgumentParser(description="Alfred")
    parser.add_argument("-r", "--run", default=None, help="Run alfred command")
    parser.add_argument("-g", "--generate", default=None, help="Generate alfred command index")
    return parser


if __name__ == "__main__":
    parser = create_args_parser()
    args = parser.parse_args()
    if args.run:
        print(run(args.run))
    elif args.generate:
        obj = run(args.generate)
        with open(f"/Users/qiqi/.cache/alfred/{args.generate}.json", "w") as f:
            f.write(obj)
    else:
        parser.print_help()
