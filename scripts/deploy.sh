#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
# MockBCTAddr=$(deploy MockBCT)
# log "MockBCT deployed at:" $MockBCTAddr

# maxSupply, // maxSupply
# salePrice, // salePrice
# tokenCap, // tokenCap
# tokenScalar, // tokenScalar
# underlying // underlying

LifeformAddr=$(deploy Lifeform 100 10000000000000000 10000000000000000000 250 0x0c504eAf83941DB8DF4913EFDD35913EFBE67984)
log "Lifeform deployed at:" $LifeformAddr