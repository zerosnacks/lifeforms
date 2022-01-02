# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

install: solc update npm

# dapp deps
update:; dapp update

# npm deps for linting etc.
npm:; yarn install

# install solc version
# example to install other versions: `make solc 0_8_10`
SOLC_VERSION := 0_8_10
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_${SOLC_VERSION}

# Build & test
build:; dapp build
test:; dapp test # --ffi # enable if you need the `ffi` cheat code on HEVM
clean:; dapp clean
lint:; yarn run lint
gas:; dapp check-snapshot
estimate:; ./scripts/estimate-gas.sh ${contract}
size:; ./scripts/contract-size.sh ${contract}

# Deployment helpers
deploy:; @./scripts/deploy.sh

# polygon
deploy-polygon: export ETH_RPC_URL = $(call polygon_network,mainnet)
deploy-polygon: check-api-key deploy

# rinkeby
deploy-rinkeby: export ETH_RPC_URL = $(call eth_network,rinkeby)
deploy-rinkeby: check-api-key deploy

# verify on Polygonscan
verify:; ETH_RPC_URL=$(call polygon_network,mainnet) dapp verify-contract src/Lifeform.sol:Lifeform $(contract)

check-api-key:
ifndef ALCHEMY_API_KEY
	$(error ALCHEMY_API_KEY is undefined)
endif

# Returns the URL to deploy to a hosted node.
# Requires the ALCHEMY_API_KEY env var to be set.
define polygon_network
https://polygon-$1.g.alchemy.com/v2/${ALCHEMY_API_KEY}
endef

# Returns the URL to deploy to a hosted node.
# Requires the ALCHEMY_API_KEY env var to be set.
define eth_network
https://eth-$1.alchemyapi.io/v2/${ALCHEMY_API_KEY}
endef