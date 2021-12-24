#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
# MockBCTAddr=$(deploy MockBCT)
# log "MockBCT deployed at:" $MockBCTAddr

LifeformAddr=$(deploy Lifeform 5 10000000000000000 5000000000000000000 0x0c504eAf83941DB8DF4913EFDD35913EFBE67984)
log "Lifeform deployed at:" $LifeformAddr