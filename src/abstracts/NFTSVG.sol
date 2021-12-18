// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Libraries
import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG
/// @author Modified from Uniswap V3 (https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTSVG.sol)
abstract contract NFTSVG {
    using Strings for uint256;

    function generateTokenURI(
        uint256 tokenId,
        uint256 tokenBalance,
        uint256 totalTokenReserves
    ) public pure returns (string memory) {
        string memory name = _generateName(tokenId);
        string memory description = _generateDescription(tokenBalance);
        string memory image = _generateImage(tokenId, tokenBalance, totalTokenReserves);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _generateName(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("Carbon - ", tokenId.toString()));
    }

    function _generateDescription(uint256 tokenBalance) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked("Carbon bearing asset storing ", tokenBalance.toString(), " Base Carbon Tonne tokens.")
            );
    }

    function _generateImage(
        uint256 tokenId,
        uint256 tokenBalance,
        uint256 totalTokenReserves
    ) internal pure returns (string memory) {
        // x^3 / x^3 + (1 - x)^3 (steep smoothstep)
        // 0.04 -> 4% of total supply = 1
        // 0 (0) - 75 (0.5) - 150 (1)
        uint256 x = (tokenBalance / totalTokenReserves); // 150.000 tons
        uint256 scale = 100 + (x**3 / x**3 + (1 - x)**3);

        return
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="300" height="300" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            "<defs>",
                            '<filter id="f1">',
                            '<feTurbulence in="SourceGraphic" type="fractalNoise" baseFrequency="0.02" numOctaves="5" result="t1" seed="',
                            tokenId.toString(),
                            '" />',
                            '<feTurbulence in="SourceGraphic" type="fractalNoise" baseFrequency="0.01" numOctaves="5" result="t2" seed="',
                            (tokenId + 1).toString(),
                            '" />',
                            '<feDisplacementMap xChannelSelector="R" yChannelSelector="G" in="t1" in2="t2" scale="',
                            scale.toString(),
                            '" />',
                            "</filter>",
                            "</defs>",
                            '<rect width="300" height="300" fill="rgba(239,239,239,1)" />',
                            '<rect width="300" height="300" fill="none" style="filter: url(#f1)" />',
                            '<rect width="300" height="300" rx="0" ry="0" fill="none" stroke="rgba(0,0,0,.25)" stroke-width="1" />',
                            "</svg>"
                        )
                    )
                )
            );
    }
}
