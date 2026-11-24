#!/usr/bin/env bash
# Partie 2 : scan d'API guidé par openapi.yaml (contact-api sur le port 3002)
cd "$(dirname "$0")/.."
docker run --rm --network host -v "$PWD:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-api-scan.py -t /zap/wrk/openapi.yaml -f openapi -r reports/api.html -J reports/api.json
echo "code retour : $?"
