#!/usr/bin/env bash
set -euo pipefail

# IP address and port to listen on
SPIN_ADDRESS="${SPIN_ADDRESS:-127.0.0.1:3000}"

# Log directory for the stdout and stderr of spin components
SPIN_LOG_DIR="${SPIN_LOG_DIR:-log}"

# Kill running jobs on exit
trap 'kill $(jobs -p)' EXIT

# Start HTTP handlers
spin up --log-dir "${SPIN_LOG_DIR}" --file spin.toml --listen "${SPIN_ADDRESS}" --sqlite @highscore/migration.sql &

wait
