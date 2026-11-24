#!/usr/bin/env python3
"""Compare deux rapports JSON ZAP (direct / proxy) : alertes par pluginid."""
import json, sys

def load(path):
    try:
        data = json.load(open(path))
    except FileNotFoundError:
        return {}
    out = {}
    for site in data.get("site", []):
        for a in site.get("alerts", []):
            out[a["pluginid"]] = (a["alert"], a.get("riskdesc", ""), int(a.get("count", 0) or 0))
    return out

d, p = load(sys.argv[1]), load(sys.argv[2])
print(f"{'pluginid':<9}{'Alerte':<60}{'Direct':>8}{'Proxy':>8}")
for pid in sorted(set(d) | set(p), key=int):
    name = (d.get(pid) or p.get(pid))[0][:58]
    print(f"{pid:<9}{name:<60}{(d[pid][2] if pid in d else '-'):>8}{(p[pid][2] if pid in p else '-'):>8}")
print(f"\nTotal types d'alertes : direct = {len(d)}, proxy durci = {len(p)}")
