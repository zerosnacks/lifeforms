#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
LifeformAddr=$(deploy Lifeform)
log "Lifeform deployed at:" $LifeformAddr
