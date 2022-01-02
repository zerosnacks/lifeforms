# Lifeforms

Carbon bearing NFT - stores [BCT (Base Carbon Tonne)](https://toucan.earth/) carbon credits inside of NFTs. The more BCT you store inside the more you improve the visual fidelity of your carbon lifeform.

![Lifeform progression](./assets/1.png)

**THIS PROJECT IS A PROOF OF CONCEPT, UNAUDITED AND EXPERIMENTAL. PROCEED WITH CAUTION.**

## Deployments

### Rinkeby

- [MockBCT](https://rinkeby.etherscan.io/address/0xEE35A17d801bEb3cED0FC2059AE503aB34c96BE1): 0xEE35A17d801bEb3cED0FC2059AE503aB34c96BE1

## Overview

Voluntary carbon markets enable individuals and organisations to offset their CO2 emissions outside of regulatory regimes by purchasing carbon offsets that were created through the voluntary markets. [Toucan](https://toucan.earth/) enables users of the Polygon network to bridge legacy carbon credits on-chain from the off-chain Verra registry. All metadata about the carbon credit is transferred on-chain as an [TCO2 NFT](https://docs.toucan.earth/protocol/bridge/tco2-toucan-carbon-tokens). Through the concept of [Carbon Pools](https://docs.toucan.earth/protocol/pool/pools) multiple project-specific tokenized carbon tonnes are bundled together into a more liquid carbon index token called [BCT](https://www.coingecko.com/en/coins/toucan-protocol-base-carbon-tonne). To give you some perspective, to capture 1 tonne of CO2 per year you need around 50 trees.

## Why?

Because BCT is a fungible and freely tradable ERC20-token projects can create artificial on-chain demand through innovative gamified locking mechanisms. One such project is [KlimaDAO](https://www.klimadao.finance/), a fork of the popular Olympus Protocol designed to capture carbon inside its treasury.

`Lifeforms` is an attempt at a different kind of locking mechanism. By directly tying the visual fidelity of the NFT to the amount of BCT tokens deposited into the NFT, users are incentivised to bind semi-permanently BCT tokens to their NFTs.

A `Lifeform` with 0 BCT deposited

![Lifeform 0 BCT](./assets/99-0.svg)

A `Lifeform` with 1500 BCT deposited

![Lifeform 1500 BCT](./assets/99-1500.svg)

This on-chain demand is directly reflected - be it on a micro-scale - in the real world. If the price of BCT goes up the traditional off-chain carbon credit market is incentivised to permanently retire more of their carbon credits and bring them on chain. This in turn creates more demand for projects in the real world to be developed that bring forth these carbon credits.

## How?

After approving with `approveToken` users deposit BCT tokens into the `Lifeform` contract address using `depositToken`. Internally a balance is tied to the `tokenId` instead of the address the user deposited the tokens with. When the NFT is transferred the `tokenBalance` remains tied to the `tokenId` meaning the BCT tokens remain tied to the NFT, not the depositor. If the user desires they can withdraw their deposited BCT tokens at any time using the `withdrawToken` method except after the NFT itself has been transferred already. This will in turn update the token to reflect its current balance with the according level of visual fidelity.

The artwork is composed as an on-chain `SVG` on mint and is dynamically updated to reflect the current BCT balance of the NFT whenever the user deposits into or withdraws BCT tokens from the NFT.

## Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:

- [Uniswap V3: LP Descriptor NFT](https://etherscan.io/address/0x91ae842a5ffd8d12023116943e72a606179294f3#code)
- [Solmate](https://github.com/Rari-Capital/solmate)
