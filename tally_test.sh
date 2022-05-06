#!/usr/bin/env bash
set -euo pipefail

# Script to test tally and score using fake data.

ENDPOINT="${ENDPOINT:-localhost:3000}"

# Create a new session and get the ULID
ulid=$(curl -s "${ENDPOINT}/session" | jq -r '.id')

echo "Session ULID: ${ulid}"

# Fake some correct answers
for demand in fish fish chicken beef veg veg; do
  curl -s "${ENDPOINT}/tally?ulid=${ulid}&food=${demand}&correct=true" >/dev/null
done

# Get the score
curl "${ENDPOINT}/score?ulid=${ulid}"
