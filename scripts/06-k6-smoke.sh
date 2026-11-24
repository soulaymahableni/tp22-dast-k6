#!/usr/bin/env bash
cd "$(dirname "$0")/.."
docker run --rm -i --network host -e BASE_URL=http://localhost:8080 grafana/k6 run - < k6/smoke.js
echo "code retour k6 : $?"
