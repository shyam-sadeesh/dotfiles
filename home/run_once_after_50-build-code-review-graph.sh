#!/usr/bin/env bash

set -euo pipefail

: "${REPOSITORY_LOCATION:?REPOSITORY_LOCATION must point to the workspace repository}"
code-review-graph build --repo "$REPOSITORY_LOCATION"