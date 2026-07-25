#!/bin/sh
set -e

echo "[r0merch] Importing workflows from /workflows..."

TMPDIR=$(mktemp -d)

for file in /workflows/*.json; do
  [ -f "$file" ] || continue
  base=$(basename "$file")
  tmp="$TMPDIR/$base"
  # Strip tags array — n8n requires tags to pre-exist in the DB, so we omit them on import
  node -e "
    const fs = require('fs');
    const w = JSON.parse(fs.readFileSync('$file','utf8'));
    delete w.tags;
    fs.writeFileSync('$tmp', JSON.stringify(w));
  "
  echo "[r0merch] Importing $base"
  n8n import:workflow --input="$tmp" || echo "[r0merch] WARN: failed to import $base, skipping"
done

rm -rf "$TMPDIR"
echo "[r0merch] Workflow import complete. Starting n8n..."
exec /docker-entrypoint.sh
