// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Flames is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant BATCH_LIMIT = 20;
    uint256 public constant MAX_MINT_PER_WALLET = 20;

    IERC20 public immutable paymentToken;
    address public feeAddress;
    uint256 public fee = 100000 * 10 ** 18;

    uint256 private _totalMinted;
    string private _baseTokenURI;

    constructor(
        address initialOwner,
        address initialFeeAddress,
        address tokenAddress
    ) ERC721("Flames", "FLAME") Ownable(msg.sender) {
        feeAddress = initialFeeAddress;
        paymentToken = IERC20(tokenAddress);
        _setBaseURI(
            "ipfs://bafybeieokkbwo2hp3eqkfa5chypmevxjii275icwxnuc7dmuexi3qsuvu4/"
        );
        _transferOwnership(initialOwner);
    }

    // set base uri
    function _setBaseURI(string memory baseURI) private {
        _baseTokenURI = baseURI;
    }

    // retrieve base uri
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mint
    function mint(uint256 quantity) external {
        require(msg.sender == tx.origin, "Caller is contract");
        require(quantity > 0, "Quantity cannot be zero");
        require(quantity <= BATCH_LIMIT, "Exceeds batch limit");
        require(_totalMinted + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(
            balanceOf(msg.sender) + quantity <= MAX_MINT_PER_WALLET,
            "Exceeds max per wallet"
        );

        uint256 tokenId;
        for (uint256 index = 0; index < quantity; index++) {
            tokenId = _totalMinted++;
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, _baseTokenURI);
        }

        bool success = paymentToken.transferFrom(
            msg.sender,
            feeAddress,
            fee * quantity
        );
        require(success, "Token transfer failed");
    }

    // total supply minted
    function totalSupply() public view returns (uint256) {
        return _totalMinted;
    }

    // set fee (only owner)
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    // set the receiver address (only owner)
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    // withdraw tokens from contract (only owner)
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId_
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
