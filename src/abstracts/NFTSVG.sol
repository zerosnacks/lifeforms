// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Libraries
import {Base64} from "../libraries/Base64.sol";
import {Strings} from "../libraries/Strings.sol";

/// @notice Provides a function for generating an SVG
/// @author Modified from Uniswap V3 (https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTSVG.sol)
abstract contract NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        uint256 tokenId;
        uint256 tokenBalance;
    }

    function generateTokenURI(SVGParams memory params) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            /* solhint-disable quotes */
                            abi.encodePacked(
                                '{"name":"',
                                _generateName(params),
                                '", "description":"',
                                _generateDescription(params),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                _generateImage(params),
                                '", "attributes": ',
                                _generateAttributes(params),
                                "}"
                            )
                            /* solhint-enable */
                        )
                    )
                )
            );
    }

    function _generateName(SVGParams memory params) internal pure returns (string memory) {
        return string(abi.encodePacked("Lifeform - ", params.tokenId.toString()));
    }

    function _generateDescription(SVGParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Lifeform storing ",
                    params.tokenBalance.toString(),
                    " tonne(s) of carbon from the Verra Verified Carbon Unit (VCU) registry from 2008 or later, bridged by the Toucan Protocol."
                )
            );
    }

    function _generateAttributes(SVGParams memory params) internal pure returns (string memory) {
        return string(abi.encodePacked('[{ "trait_type": "Storage", "value": ', params.tokenBalance.toString(), "}]"));
    }

    function _generateImage(SVGParams memory params) internal pure returns (string memory) {
        return
            Base64.encode(
                bytes(
                    string(
                        /* solhint-disable quotes */
                        abi.encodePacked(
                            '<svg width="600" height="600" viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            '<defs><clipPath id="a"><rect width="600" height="600" rx="38" ry="38"/></clipPath><filter id="b"><feTurbulence in="SourceGraphic" type="fractalNoise" baseFrequency="0.005" numOctaves="5" seed="',
                            params.tokenId.toString(),
                            '" /><feDisplacementMap xChannelSelector="R" yChannelSelector="G" scale="',
                            params.tokenBalance.toString(),
                            '" /></filter></defs>'
                            '<g clip-path="url(#a)"><path fill="rgba(239,239,239,1.0)" d="M0 0h600v600H0z" /><path fill="none" style="filter:url(#b)" d="M0 0h600v600H0z" /><rect width="600" height="600" rx="38" ry="38" fill="none" stroke="rgba(0,0,0,.25)" /></g></svg>'
                        )
                        /* solhint-enable */
                    )
                )
            );
    }
}
