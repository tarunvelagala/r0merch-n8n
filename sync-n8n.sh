#!/bin/bash
# Polls n8n every 2 seconds and syncs all 4 workflows to the workflows/ directory
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3YTNiNWRhOC0zMGNiLTRhZWEtOThmMy05ODM4MDg2Njk1ZTMiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNDM5MGE4ZDctZjllNi00YTdjLWE4Y2EtMWRkYmQwYzFlZGU2IiwiaWF0IjoxNzg1MTk3NjQ0fQ.TXVSNOwVsQsOIbzm_lcgXRBfgF7z9j1voZdEqIyfjG8"
BASE="http://localhost:5678/api/v1"
DIR="/Users/C5404787/workplace/personal/r0merch-n8n/workflows"

mkdir -p "$DIR"

ROOT="/Users/C5404787/workplace/personal/r0merch-n8n"

sync_workflow() {
  local ID="$1"
  local NAME="$2"
  local TARGET="$DIR/${NAME}.json"
  local TMP="/tmp/n8n-sync-${NAME}.json"

  response=$(curl -s "$BASE/workflows/$ID" -H "X-N8N-API-KEY: $API_KEY")
  if echo "$response" | python3 -m json.tool > "$TMP" 2>/dev/null; then
    size=$(wc -c < "$TMP")
    if [ "$size" -gt 100 ]; then
      if ! diff -q "$TMP" "$TARGET" > /dev/null 2>&1; then
        cp "$TMP" "$TARGET"
        echo "[$(date '+%H:%M:%S')] Updated: ${NAME}.json"
      fi
      if [ "$NAME" = "pod-design-orchestrator" ]; then
        if ! diff -q "$TMP" "$ROOT/workflow.json" > /dev/null 2>&1; then
          cp "$TMP" "$ROOT/workflow.json"
        fi
      fi
    fi
  fi
}

while true; do
  sync_workflow "mHbH68xEHobBorKA" "pod-design-orchestrator"
  sync_workflow "fv5oPTCyTNEmKm7j" "typography-analyzer-agent"
  sync_workflow "hqW3sxjuGwt3UUdB" "sticker-inspiration-agent"
  sync_workflow "RD9bQuDJZFq2Vkqn" "artwork-generator-agent"
  sleep 2
done
