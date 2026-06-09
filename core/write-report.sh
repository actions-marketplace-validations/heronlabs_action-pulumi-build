#!/usr/bin/env bash

set -euo pipefail

: "${COMMAND:?COMMAND is required}"
: "${ENVIRONMENT:?ENVIRONMENT is required}"
: "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"

# Write the Pulumi command output to both the job summary and a file artifact.
# REPORT may be empty (e.g. when the Pulumi step failed before producing output).
{
  echo "## Pulumi ${COMMAND} — heronlabs / ${ENVIRONMENT}"
  echo ''
  echo '````'
  echo "${REPORT:-}"
  echo '````'
} | tee pulumi-report.txt >> "${GITHUB_STEP_SUMMARY}"
