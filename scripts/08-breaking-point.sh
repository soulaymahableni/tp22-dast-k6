#!/usr/bin/env bash
# Augmente les VUs jusqu'à franchir un seuil. Lancer "docker stats" dans un 2e terminal.
cd "$(dirname "$0")/.."
for VUS in 20 50 100 200; do
  echo; echo "=================== VUS = $VUS ==================="
  docker run --rm -i --network host -e BASE_URL=http://localhost:8080 -e VUS="$VUS" grafana/k6 run - < k6/load.js
  RC=$?
  echo "code retour k6 (VUS=$VUS) : $RC"
  if [ "$RC" -ne 0 ]; then echo ">>> Point de rupture atteint vers $VUS VUs"; break; fi
done
