# Lifeforms

Carbon bearing NFT allowing you to store BCT (Base Carbon Tonne) carbon credits inside of NFTs. Depending on how much you store inside compared you can change the visual result of your carbon lifeform.

**THIS PROJECT IS UNAUDITED AND HIGHLY EXPERIMENTAL**

## Overview

Volunatary carbon markets enable individuals and organisations to offset their CO2 emissions outside of a regulatory regime. These entitites can purchase offsets that were created through the voluntary or compliance markets. [Toucan](https://toucan.earth/) enables users of the Polygon network to purchase BCT or Base Carbon Tonne ERC20 tokens as a representation of offsetting 1 carbon tonne per token. Toucan does this by bridging legacy carbon credits on-chain from the Verra registry. All metadata about the carbon credit is transferred on chain as an ERC721 NFT. Through the concept of [Carbon Pools](https://docs.toucan.earth/protocol/pool/pools) multiple project-specific tokenized carbon tonnes are bundled together into a more liquid carbon index token called [BCT](https://www.coingecko.com/en/coins/toucan-protocol-base-carbon-tonne).

## Why?

Because BCT is a fungible and freely tradeable ERC20-token projects can create artificial on-chain demand through innovative gamified locking mechanisms. This NFT project called `Lifeforms` is an attempt at such a locking mechanism. By directly tying the visual representation of the NFT to the amount of BCT tokens deposited into the NFT users are incentivised to bind BCT tokens to their NFTs.

A `Lifeform` with 0 BCT deposited

![Lifeform 0 BCT](./assets/99-0.svg)

A `Lifeform` with 6 BCT deposited

![Lifeform 6 BCT](./assets/99-1500.svg)

This on-chain demand is directly reflected, be it on a micro-scale, in the real world. If the price of BCT goes up the traditional carbon credit market is incentivised to permanently retire their carbon credits and bring them on chain.

## How?

Through `depositToken` users deposit BCT tokens into the `Lifeform` contract address. Internally a balance is tied to the `tokenId`, not the address the user deposited the tokens with. When the NFT is transferred the `tokenBalance` remains tied to the `tokenId`. If the user desires they can withdraw their deposited BCT tokens at any time using the `withdrawToken` method except after the NFT itself has been transferred already.

The artwork is composed as an on-chain `SVG` on mint and is dynamically updated to reflect the current BCT balance of the NFT whenever the user deposits into or withdraws BCT tokens from the NFT.

![Lifeform progression](./assets/1.png)

## Notices

- BCT TOKEN DEPOSITS ARE CAPPED AT 10.00 PER NFT TO REDUCE RISK.
- THE CONTRACT HAS A HIGH DEGREE OF ADMIN CONTROL.

## Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:

- [Uniswap V3: LP Descriptor NFT](https://etherscan.io/address/0x91ae842a5ffd8d12023116943e72a606179294f3#code)
- [Solmate](https://github.com/Rari-Capital/solmate)
