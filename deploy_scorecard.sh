#!/usr/bin/env bash
# Autonomous scorecard deploy: rebuild from canonical ledger, push to GitHub Pages.
# Designed to run unattended (cron/launchd). Fails safe — any error aborts before push.
set -euo pipefail
cd "$(dirname "$0")"
python3 scorecard/build_scorecard.py
cp scorecard/dist/scorecard.html docs/index.html
# rebuild dataset + social content from canonical sources; failures abort the
# deploy (set -e) rather than shipping a stale/partial build silently.
python3 dataset/build_dataset.py
python3 content/build_content.py
# NOTE: data/settled_markets.csv (~42MB) is gitignored and intentionally NOT
# added here. One-time migration (run manually, not from this script):
#   git rm --cached data/settled_markets.csv
echo "NOTE: data/settled_markets.csv is gitignored; if still tracked, run: git rm --cached data/settled_markets.csv" >&2
git add docs/index.html scorecard/dist/trades.json scorecard/dist/trades.csv \
        data/DATASET.md data/favorite_longshot_analysis.json content/
if git diff --cached --quiet; then
  echo "NO_CHANGES"
  exit 0
fi
git commit -q -m "auto: regenerate scorecard $(date -u +%Y-%m-%dT%H:%MZ)"
git push -q origin main
echo "DEPLOYED_OK"
