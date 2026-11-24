#!/usr/bin/env bash
# Démarre Juice Shop (3000), le proxy Nginx durci (8080) et contact-api (3002)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports && chmod -R a+rwX reports zap && chmod a+w .   # ZAP (uid 1000) ecrit dans /zap/wrk
docker compose up -d --build
echo "Attente de Juice Shop..."
for i in $(seq 1 60); do curl -fs http://localhost:3000 >/dev/null && break; sleep 3; done
echo "--- direct (3000) ---";   curl -sI http://localhost:3000 | head -12
echo "--- proxy (8080) ---";    curl -sI http://localhost:8080 | head -20
echo "--- contact-api (3002) ---"; curl -s http://localhost:3002/api/health; echo
