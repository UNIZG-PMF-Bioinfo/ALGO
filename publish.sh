#!/usr/bin/env bash
# Rebuild the course website (docs/) and push it to GitHub.
#
# Usage:
#   ./publish.sh "commit message"                         # rebuild the whole site
#   ./publish.sh "commit message" Week1/week1_lecture1.qmd  # rebuild only these pages
set -euo pipefail
cd "$(dirname "$0")"

# --- find Quarto -------------------------------------------------------------
QUARTO=$(command -v quarto || true)
if [ -z "$QUARTO" ]; then
  for q in /Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto \
           /Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto \
           /Volumes/Positron*/Positron.app/Contents/Resources/app/quarto/bin/quarto; do
    if [ -x "$q" ]; then QUARTO="$q"; break; fi
  done
fi
if [ -z "$QUARTO" ]; then
  echo "Quarto not found. Install it from https://quarto.org or install Positron."
  exit 1
fi

MSG="${1:-Update course site}"
shift || true

# --- render ------------------------------------------------------------------
echo "==> Rendering with $QUARTO"
if ! "$QUARTO" render ${@+"$@"}; then
  echo "!! Render failed. Restoring files in docs/ that the failed render deleted."
  git diff --name-only --diff-filter=D -- docs | while read -r f; do git checkout -- "$f"; done
  exit 1
fi

# --- commit ------------------------------------------------------------------
echo "==> Committing"
# OneDrive can make git time out while a file is still syncing, so retry a few times
for i in 1 2 3; do
  git add -A && break
  echo "   git add failed (OneDrive sync?), retrying in 5s..."
  sleep 5
done

if git diff --cached --quiet; then
  echo "   Nothing new to commit."
else
  git commit -m "$MSG"
fi

# --- push --------------------------------------------------------------------
echo "==> Pushing to GitHub"
git pull --rebase origin main
git push origin main
echo "==> Done. The site updates on GitHub Pages in a minute or two."
