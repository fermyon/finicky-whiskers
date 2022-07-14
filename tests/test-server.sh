#!/bin/bash
set -beuo pipefail

./serve.sh &

timeout ${TIMEOUT:-10s} bash -c 'until curl -q 127.0.0.1:3000/index.html &>/dev/null; do sleep 1; done'

trap 'kill -s SIGTERM $(jobs -p)' EXIT

./tally_test.sh && \
  echo "Tally test success!" || \
  echo "Tally test failed."