#!/usr/bin/env bash
# Partie 4 : génère la liste complète des règles (reports/gen.conf) pour compléter zap/rules.tsv
cd "$(dirname "$0")/.."
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -g reports/gen.conf -r reports/gen.html
echo "Liste des règles : reports/gen.conf"
