#!/bin/sh
# Run this after editing niches.csv to sync it into n8n
cp "$(dirname "$0")/niches.csv" /Users/C5404787/n8n/files/niches.csv
echo "niches.csv synced to n8n files volume"
