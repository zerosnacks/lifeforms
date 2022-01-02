#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
# MockBCTAddr=$(deploy MockBCT \"MockBCT\" \"MBCT\" 18)
# log "MockBCT deployed at:" $MockBCTAddr

LifeformAddr=$(deploy Lifeform 100 0xEE35A17d801bEb3cED0FC2059AE503aB34c96BE1)
log "Lifeform deployed at:" $LifeformAddr