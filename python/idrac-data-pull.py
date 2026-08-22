#!/usr/bin/env python3
"""Pull raw iDRAC Redfish data for auditing. Prints JSON; parse it yourself."""

import json
import requests
from requests.auth import HTTPBasicAuth
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ---- Config ----
SERVERS = [
    ("192.168.1.100", "root", "calvin"),
    ("192.168.1.101", "root", "calvin"),
]

# Endpoints to pull per server (add/remove as you like)
ENDPOINTS = {
    "system":  "/redfish/v1/Systems/System.Embedded.1",
    "manager": "/redfish/v1/Managers/iDRAC.Embedded.1",
    "power":   "/redfish/v1/Chassis/System.Embedded.1/Power",
    "thermal": "/redfish/v1/Chassis/System.Embedded.1/Thermal",
}


def pull(ip, user, password):
    sess = requests.Session()
    sess.auth = HTTPBasicAuth(user, password)
    sess.verify = False

    data = {}
    for name, path in ENDPOINTS.items():
        try:
            r = sess.get(f"https://{ip}{path}", timeout=30)
            r.raise_for_status()
            data[name] = r.json()
        except Exception as exc:
            data[name] = {"error": str(exc)}
    return data


if __name__ == "__main__":
    fleet = {}
    for ip, user, password in SERVERS:
        fleet[ip] = pull(ip, user, password)

    print(json.dumps(fleet, indent=2))
