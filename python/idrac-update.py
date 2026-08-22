#!/usr/bin/env python3
"""Push a Dell firmware DUP to multiple servers via Redfish, optionally reboot each."""

import json
import argparse
import requests
from requests.auth import HTTPBasicAuth
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ---- Config ----
FIRMWARE   = "./BIOS_XXXXX_WN64_2.19.1.EXE"
APPLY_TIME = "OnReset"          # "OnReset" or "Immediate"

# List of servers: (ip, user, password)
SERVERS = [
    ("192.168.1.100", "root", "calvin"),
    ("192.168.1.101", "root", "calvin"),
    ("192.168.1.102", "root", "calvin"),
]


def update_server(ip, user, password, firmware_bytes, filename, reboot, reset_type):
    """Push firmware to one server. Returns True on success."""
    base = f"https://{ip}/redfish/v1"
    sess = requests.Session()
    sess.auth = HTTPBasicAuth(user, password)
    sess.verify = False

    # 1. Push firmware
    push_uri = sess.get(f"{base}/UpdateService", timeout=30).json()["MultipartHttpPushUri"]
    files = {
        "UpdateParameters": (None, json.dumps({"@Redfish.OperationApplyTime": APPLY_TIME}), "application/json"),
        "UpdateFile": (filename, firmware_bytes, "application/octet-stream"),
    }
    resp = sess.post(f"https://{ip}{push_uri}", files=files, timeout=600)
    resp.raise_for_status()
    print(f"  [+] {ip}: pushed. Job: {resp.headers.get('Location')}")

    # 2. Reboot (optional)
    if reboot:
        reset_uri = f"{base}/Systems/System.Embedded.1/Actions/ComputerSystem.Reset"
        r = sess.post(reset_uri, json={"ResetType": reset_type}, timeout=30)
        r.raise_for_status()
        print(f"  [+] {ip}: reboot issued ({reset_type}).")

    return True


def main():
    parser = argparse.ArgumentParser(description="Push Dell firmware to multiple servers.")
    parser.add_argument("--reboot", action="store_true",
                        help="Reboot each server after pushing.")
    parser.add_argument("--reset-type", default="ForceRestart",
                        choices=["ForceRestart", "GracefulRestart"])
    args = parser.parse_args()

    # Read firmware once, reuse for every server
    with open(FIRMWARE, "rb") as fh:
        firmware_bytes = fh.read()
    filename = FIRMWARE.split("/")[-1]

    results = {}
    for ip, user, password in SERVERS:
        print(f"[*] {ip}: starting...")
        try:
            update_server(ip, user, password, firmware_bytes, filename,
                          args.reboot, args.reset_type)
            results[ip] = "OK"
        except Exception as exc:
            print(f"  [!] {ip}: FAILED :: {exc}")
            results[ip] = f"FAILED: {exc}"

    # Summary
    print("\n=== Summary ===")
    for ip, status in results.items():
        print(f"  {ip}: {status}")


if __name__ == "__main__":
    main()
