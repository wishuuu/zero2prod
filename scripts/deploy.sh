#!/usr/bin/env bash
set -euo pipefail

# Expected env vars provided by the CI SSH step:
# - REGISTRY_URL
# - REGISTRY_USERNAME
# - REGISTRY_PASSWORD

# Pick compose command (v2 or legacy)
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

DEPLOY_DIR="$HOME/zero2prod"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

if [ ! -f docker-compose.yml ]; then
  echo "docker-compose.yml not found in $DEPLOY_DIR" >&2
  exit 1
fi

# Ensure the app service uses the pushed image (replace local build)
export IMAGE_TAG="${REGISTRY_URL}/zero2prod/app:latest"
awk '
  BEGIN { inapp=0; handled=0 }
  # Enter app service
  /^  app:\s*$/ { inapp=1; handled=0; print; next }
  # If inside app and we see an image line, update it
  inapp==1 && /^[[:space:]]+image:/ {
    sub(/image:.*/, "image: " ENVIRON["IMAGE_TAG"])
    handled=1
    print
    next
  }
  # If inside app and we see build: ., replace with image
  inapp==1 && /^[[:space:]]+build:[[:space:]]*\.$/ {
    # Preserve typical 4-space indentation
    print "    image: " ENVIRON["IMAGE_TAG"]
    handled=1
    next
  }
  # Leaving app block when another top-level service begins (two-space indent + name + colon)
  inapp==1 && /^  [a-zA-Z0-9_-]+:/ {
    if (handled==0) { print "    image: " ENVIRON["IMAGE_TAG"] }
    inapp=0
    print
    next
  }
  # Leaving app block when a top-level key begins (no indent)
  inapp==1 && /^[^[:space:]]/ {
    if (handled==0) { print "    image: " ENVIRON["IMAGE_TAG"] }
    inapp=0
    print
    next
  }
  { print }
  END {
    # If file ended while still in app block and not handled, append image line
    if (inapp==1 && handled==0) {
      print "    image: " ENVIRON["IMAGE_TAG"]
    }
  }
' docker-compose.yml > docker-compose.tmp && mv docker-compose.tmp docker-compose.yml

echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin

$COMPOSE down || true
$COMPOSE pull
$COMPOSE up -d --remove-orphans

echo "Deployment complete."

