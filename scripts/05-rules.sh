#!/usr/bin/env bash
# Partie 4 : règles bloquantes. Attendu : 1 sur le direct, 0 sur le proxy durci.
cd "$(dirname "$0")/.."
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -c zap/rules.tsv -I -r reports/rules-direct.html > reports/rules-direct.log 2>&1
D=$?
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:8080 -c zap/rules.tsv -I -r reports/rules-proxy.html > reports/rules-proxy.log 2>&1
P=$?
echo "===== FAIL sur le scan direct (3000) ====="; grep -E "^FAIL-NEW|^FAIL-INPROG" reports/rules-direct.log || echo "(aucun)"
echo "===== FAIL sur le proxy durci (8080) ====="; grep -E "^FAIL-NEW|^FAIL-INPROG" reports/rules-proxy.log || echo "(aucun)"
echo
echo "code retour direct (3000)      : $D   (attendu 1)"
echo "code retour proxy durci (8080) : $P   (attendu 0)"
