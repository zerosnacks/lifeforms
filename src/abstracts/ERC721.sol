// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC-721 implementation.
/// @author Modified from LexDAO (https://github.com/lexDAO/Kali/blob/main/contracts/tokens/erc721/ERC721.sol)
abstract contract ERC721 {
    // ======
    // EVENTS
    // ======

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ================
    // METADATA STORAGE
    // ================

    string public name;

    string public symbol;

    // ===============
    // ERC-721 STORAGE
    // ===============

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => string) public tokenURI;

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // =============
    // ERC-165 LOGIC
    // =============

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x01ffc9a7;
    }

    // =============
    // ERC-721 LOGIC
    // =============

    function approve(address spender, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");

        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(from == ownerOf[tokenId], "NOT_OWNER");

        require(
            msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
            "NOT_APPROVED"
        );

        // this is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);

        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint256,bytes)`
            (, bytes memory returned) = to.staticcall(
                abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data)
            );

            bytes4 selector = abi.decode(returned, (bytes4));

            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }

    // ==============
    // INTERNAL LOGIC
    // ==============

    function _mint(
        address to,
        uint256 tokenId,
        string memory tokenURI_
    ) internal virtual {
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        // this is reasonably safe from overflow because incrementing `totalSupply` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits,
        // and because the sum of all user balances can't exceed 'type(uint256).max'
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        tokenURI[tokenId] = tokenURI_;

        emit Transfer(address(0), to, tokenId);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
