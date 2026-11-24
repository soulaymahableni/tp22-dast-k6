#!/usr/bin/env bash
# Partie 1 : scan baseline (passif) directement sur Juice Shop
cd "$(dirname "$0")/.."
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -r reports/baseline-direct.html -J reports/baseline-direct.json
echo "code retour : $?   (0 = OK, 1 = au moins un FAIL, 2 = au moins un WARN)"
