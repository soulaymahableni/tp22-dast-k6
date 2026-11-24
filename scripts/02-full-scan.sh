#!/usr/bin/env bash
# Partie 2 : scan actif (15 à 30 min). -m 5 limite le spider à 5 minutes.
cd "$(dirname "$0")/.."
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py -t http://localhost:3000 -m 5 -r reports/full.html -J reports/full.json
echo "code retour : $?"
