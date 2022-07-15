#!/usr/bin/env bash
set -euo pipefail

# Script to test tally and score using fake data.

ENDPOINT="${ENDPOINT:-localhost:3000}"

# Follow redirects
CURL="curl -L"

# Create a new session and get the ULID
ulid=$(${CURL} -s "${ENDPOINT}/session" | jq -j '.id')

echo "Session ULID: ${ulid}"

# Fake some correct answers
for demand in fish fish chicken beef veg veg; do
  ${CURL} -s "${ENDPOINT}/tally?ulid=${ulid}&food=${demand}&correct=true" >/dev/null
done

# Get the score
tally_json="$(${CURL} -s "${ENDPOINT}/score?ulid=${ulid}")"
echo "${tally_json}"

# Check tallies
for expected in fish:2 chicken:1 beef:1 veg:2 total:6; do
  type="$(echo "${expected}" | awk -F':' '{print $1}')"
  want="$(echo "${expected}" | awk -F':' '{print $2}')"

  tally="$(echo "${tally_json}" | jq -j .${type})"
  if [[ "${tally}" != "${want}" ]]; then
    echo "Tally for ${type} does not match expected. Want: ${want}, Got: ${tally}" && exit 1
  fi
done
