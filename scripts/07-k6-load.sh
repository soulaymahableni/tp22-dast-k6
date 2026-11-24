#!/usr/bin/env bash
# Usage : ./scripts/07-k6-load.sh [VUS]   (défaut 20)
cd "$(dirname "$0")/.."
VUS="${1:-20}"
docker run --rm -i --network host -e BASE_URL=http://localhost:8080 -e VUS="$VUS" grafana/k6 run - < k6/load.js
echo "code retour k6 (VUS=$VUS) : $?   (0 = seuils respectés, 99 = seuil franchi)"
