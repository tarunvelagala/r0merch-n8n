#!/bin/bash
# Polls n8n every 2 seconds and writes the latest workflow to workflow.json
WORKFLOW_ID="1790571d-754c-4445-be73-1c370705998b"
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3YTNiNWRhOC0zMGNiLTRhZWEtOThmMy05ODM4MDg2Njk1ZTMiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNDM5MGE4ZDctZjllNi00YTdjLWE4Y2EtMWRkYmQwYzFlZGU2IiwiaWF0IjoxNzg1MTk3NjQ0fQ.TXVSNOwVsQsOIbzm_lcgXRBfgF7z9j1voZdEqIyfjG8"
TARGET="/Users/C5404787/workplace/personal/r0merch-n8n/workflow.json"

while true; do
  response=$(curl -s "http://localhost:5678/api/v1/workflows/$WORKFLOW_ID" \
    -H "X-N8N-API-KEY: $API_KEY")
  if echo "$response" | python3 -m json.tool > /tmp/n8n-sync-tmp.json 2>/dev/null; then
    if ! diff -q /tmp/n8n-sync-tmp.json "$TARGET" > /dev/null 2>&1; then
      cp /tmp/n8n-sync-tmp.json "$TARGET"
    fi
  fi
  sleep 2
done
