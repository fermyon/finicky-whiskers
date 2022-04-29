#!/usr/bin/env bash
set -euo pipefail

# Kill running jobs on exit
trap 'kill $(jobs -p)' EXIT

# Start HTTP handlers
spin up --log-dir ./log --file spin.toml &

# Start Redis handler
spin up --log-dir ./log --file spin-morsel.toml &

wait
