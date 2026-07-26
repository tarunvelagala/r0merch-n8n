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

# Remove any non-canonical files left by previous --separate exports
for f in /workflows/*.json; do
  base=$(basename "$f")
  case "$base" in
    [0-9][0-9]-*|[0-9][0-9][a-z]-*) ;; # canonical NN- or NNx- prefix — keep
    .gitignore) ;;
    *) echo "[r0merch] Removing non-canonical $base"; rm -f "$f" ;;
  esac
done

echo "[r0merch] Workflow import complete."

# --- Export loop: sync UI edits back to /workflows every 60s ---
# Only exports r0merch workflows, writing to canonical NN-name.json filenames.
do_export() {
  echo "[r0merch] Exporting workflows to /workflows..."
  node -e "
    const { execSync } = require('child_process');
    const out = execSync('n8n export:workflow --all --pretty 2>/dev/null').toString();
    let workflows;
    try { workflows = JSON.parse(out); } catch(_) {
      // export:workflow without --separate prints one JSON array
      const match = out.match(/\[[\s\S]*\]/);
      if (!match) { console.error('No JSON found in export output'); process.exit(1); }
      workflows = JSON.parse(match[0]);
    }

    const fs = require('fs');
    const nameToFile = {};
    fs.readdirSync('/workflows').forEach(f => {
      if (!/^[0-9]/.test(f) || !f.endsWith('.json')) return;
      try {
        const w = JSON.parse(fs.readFileSync('/workflows/' + f, 'utf8'));
        if (w.name) nameToFile[w.name] = f;
      } catch(_) {}
    });

    let saved = 0;
    workflows.forEach(w => {
      if (!w.name || !w.name.startsWith('r0merch')) return;
      const filename = nameToFile[w.name];
      if (!filename) return; // unknown workflow — skip, don't create new UUID file
      fs.writeFileSync('/workflows/' + filename, JSON.stringify(w, null, 2));
      saved++;
    });

    // Sanitize: replace any $vars. the UI wrote back with $env.
    let sanitized = 0;
    fs.readdirSync('/workflows').forEach(f => {
      if (!/^[0-9]/.test(f) || !f.endsWith('.json')) return;
      const fpath = '/workflows/' + f;
      const content = fs.readFileSync(fpath, 'utf8');
      if (content.includes('$vars.')) {
        fs.writeFileSync(fpath, content.replaceAll('$vars.', '$env.'));
        sanitized++;
      }
    });
    if (sanitized > 0) console.log('[r0merch] Sanitized $vars. -> $env. in ' + sanitized + ' files.');

    console.log('[r0merch] Exported ' + saved + ' r0merch workflows.');
  " 2>&1 || echo "[r0merch] WARN: export failed, will retry in 60s"
}

export_loop() {
  while true; do
    sleep 60
    do_export
  done
}
export_loop &

echo "[r0merch] Starting n8n..."
exec /docker-entrypoint.sh
