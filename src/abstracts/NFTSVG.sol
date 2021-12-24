// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Vendor
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// Libraries
import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG
/// @author Modified from Uniswap V3 (https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTSVG.sol)
abstract contract NFTSVG {
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        uint256 tokenBalance;
        uint256 tokenScalar;
    }

    function generateTokenURI(SVGParams memory params) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    _generateName(params),
                    '", "description":"',
                    _generateDescription(params),
                    '", "image": "',
                    "data:image/svg+xml;base64,",
                    _generateImage(params),
                    '"}'
                )
            );
    }

    function _generateName(SVGParams memory params) internal pure returns (string memory) {
        return string(abi.encodePacked("Carbon - ", params.tokenId.toString()));
    }

    function _generateDescription(SVGParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Carbon bearing asset storing ",
                    params.tokenBalance.toString(),
                    " Base Carbon Tonne tokens."
                )
            );
    }

    function _generateImage(SVGParams memory params) internal pure returns (string memory) {
        return
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="600" height="600" viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            _generateSVGDefs(params),
                            _generateSVGBody(),
                            "</svg>"
                        )
                    )
                )
            );
    }

    function _generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
        /// @notice tokenBalance has been scaled by 10**18, so say 100 * 15 = 1500
        uint256 scale = params.tokenScalar * params.tokenBalance;

        svg = string(
            abi.encodePacked(
                "<defs>",
                '<clipPath xmlns="http://www.w3.org/2000/svg" id="c1">',
                '<rect width="600" height="600" rx="38" ry="38"/>',
                "</clipPath>",
                '<filter id="f1">',
                '<feTurbulence in="SourceGraphic" type="fractalNoise" baseFrequency="0.02" numOctaves="5" result="t1" seed="',
                params.tokenId.toString(),
                '"/>',
                '<feTurbulence in="SourceGraphic" type="fractalNoise" baseFrequency="0.005" numOctaves="5" result="t2" seed="',
                params.tokenId.toString(),
                '" />',
                '<feDisplacementMap xChannelSelector="R" yChannelSelector="G" in1="t1" in2="t2" scale="',
                scale.toString(),
                '" />',
                "</filter>",
                "</defs>"
            )
        );
    }

    function _generateSVGBody() private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g clip-path="url(#c1)">',
                '<rect width="600" height="600" fill="rgba(239,239,239,1.0)" />',
                '<rect width="600" height="600" fill="none" style="filter: url(#f1)" />',
                '<rect width="600" height="600" rx="38" ry="38" fill="none" stroke="rgba(0,0,0,.25)" stroke-width="1" />',
                "</g>"
            )
        );
    }
}
