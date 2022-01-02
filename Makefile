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
test:; dapp test --verbosity 2 # --ffi # enable if you need the `ffi` cheat code on HEVM
clean:; dapp clean
lint:; yarn run lint
gas:; dapp snapshot
estimate:; ./scripts/estimate-gas.sh ${contract}
size:; ./scripts/contract-size.sh ${contract}

# Deployment helpers
deploy:; @./scripts/deploy.sh

# rinkeby
deploy-rinkeby: export ETH_RPC_URL = $(call network,rinkeby)
deploy-rinkeby: check-api-key deploy

# verify on Etherscan
# verify-lifeforms:; ETH_RPC_URL=$(call network,rinkeby) dapp verify-contract src/Lifeforms.sol:Lifeforms 0x828edeb6c951586Ee924A65f09242D080d7b4Ae0 100 0xEE35A17d801bEb3cED0FC2059AE503aB34c96BE1
verify-mbct:; ETH_RPC_URL=$(call network,rinkeby) dapp verify-contract src/MockBCT.sol:MockBCT 0xEE35A17d801bEb3cED0FC2059AE503aB34c96BE1 \"MockBCT\" \"MBCT\" 18

check-api-key:
ifndef ALCHEMY_API_KEY
	$(error ALCHEMY_API_KEY is undefined)
endif

# Returns the URL to deploy to a hosted node.
# Requires the ALCHEMY_API_KEY env var to be set.
define network
https://eth-$1.alchemyapi.io/v2/${ALCHEMY_API_KEY}
endef