#!/usr/bin/env bash
# Partie 3 : baseline via le proxy durci, pour comparer avec le scan direct
cd "$(dirname "$0")/.."
docker compose restart proxy && sleep 3
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:8080 -r reports/baseline-proxy.html -J reports/baseline-proxy.json
echo "code retour : $?"
echo
python3 scripts/compare.py reports/baseline-direct.json reports/baseline-proxy.json
