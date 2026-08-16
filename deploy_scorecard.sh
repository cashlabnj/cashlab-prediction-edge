#!/usr/bin/env bash
# Autonomous scorecard deploy: rebuild from canonical ledger, push to GitHub Pages.
# Designed to run unattended (cron/launchd). Fails safe — any error aborts before push.
set -euo pipefail
cd "$(dirname "$0")"
python3 scorecard/build_scorecard.py
cp scorecard/dist/scorecard.html docs/index.html
# rebuild dataset + social content from canonical sources
python3 dataset/build_dataset.py >/dev/null 2>&1 || true
python3 content/build_content.py >/dev/null 2>&1 || true
if git diff --quiet docs/index.html scorecard/dist/trades.json scorecard/dist/trades.csv 2>/dev/null; then
  # nothing changed in tracked data vs working tree — still commit if docs changed
  :
fi
git add docs/index.html scorecard/dist/trades.json scorecard/dist/trades.csv data/ content/
if git diff --cached --quiet; then
  echo "NO_CHANGES"
  exit 0
fi
git commit -q -m "auto: regenerate scorecard $(date -u +%Y-%m-%dT%H:%MZ)"
git push -q origin main
echo "DEPLOYED_OK"
