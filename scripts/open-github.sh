#!/usr/bin/env bash
# Open this repo's GitHub page in the default browser.
# Derives the URL from the git remote (default: origin) and normalizes both
# SSH (git@github.com:owner/repo.git) and HTTPS forms to a browsable https URL.
#
# Usage: open-github.sh [remote-name]   (defaults to origin)
set -euo pipefail

remote="${1:-origin}"

url="$(git remote get-url "$remote" 2>/dev/null)" || {
  echo "error: no git remote named '$remote'" >&2
  exit 1
}

# Normalize to https://host/owner/repo:
#   git@host:owner/repo(.git)   -> https://host/owner/repo
#   ssh://git@host/owner/repo   -> https://host/owner/repo
#   https://host/owner/repo.git -> https://host/owner/repo (unchanged but for .git)
url="$(printf '%s' "$url" | sed -E 's#^git@([^:]+):#https://\1/#; s#^ssh://git@#https://#')"
url="${url%.git}"          # strip trailing .git
url="${url%/}"            # strip trailing slash

case "$url" in
  https://*|http://*) : ;;
  *) echo "error: could not normalize remote URL to https: $url" >&2; exit 1 ;;
esac

# Pick the platform opener.
if command -v open >/dev/null 2>&1; then        # macOS
  opener=open
elif command -v xdg-open >/dev/null 2>&1; then  # Linux
  opener=xdg-open
else
  echo "Open manually: $url"
  exit 0
fi

echo "Opening $url"
"$opener" "$url"
