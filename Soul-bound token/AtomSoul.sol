// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract AtomSoul is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    /*Librariries*/
    using Counters for Counters.Counter;
        
    /* Events */
    /**
     * @notice emit when an NFT is minted.
     * @param to address of owner of new NFT.
     * @param tokenId id of new NFT
     */
    event Attest(address indexed to, uint256 indexed tokenId);
    /**
     * @notice emit when NFT is revoked
     * @param tokenId id of revoked NFT
     */
    event Revoke(uint256 indexed tokenId);

    /*State Variables*/
    /**
     * @dev keep a count of NFT(s) minted so far. Also used as id for NFTs
     */
    Counters.Counter private _tokenIdCounter;

    /* FUNCTIONS */
    constructor() ERC721("AtomSoul", "ATS") {}

    /**
     * @notice Mint a new NFT and emit the `Attest` event. Only owner can call this function.
     * @param to address to which newly minted NFT should get attested
     * @param uri link to the asset associated with the NFT.
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit Attest(to, tokenId);
    }


    /**
     * @dev this override function is required by solidity.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
    }
    /**
     * @notice get the link associated with an NFT.
     * @dev this override function is required by solidity
     * @param tokenId id of the NFT
     */
    function tokenURI(
        uint256 tokenId
        )
        public 
        view
        override(ERC721, ERC721URIStorage) 
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @notice Revoke the NFT ownership and emit the `Revoke` event. Only owner can call this function.
     * @param tokenId id associated with revoked NFT
     */
    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit Revoke(tokenId);
    }

    /**
     * @notice Revert if called. Our contract do not support unsafe method of transferring NFTs
     */
    function transferFrom(
        address,
        address,
        uint256 
    ) public override {
        require(false, "Only safeTransferFrom is allowed.");
    }

    /**
     * @notice Revert if called. This function can only be called by contract itself to mint NFTs.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) beforeTransfer(from, to) public override {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    /**
     * @notice Revert if called. This function can only be called by contract itself to mint NFTs.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) beforeTransfer(from, to) public override {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* Modifiers */
    /**
     * @dev check if transfer is done by contract itself. while minting `from == account(0)` and while revoking `to == account(0)`
     * @param from address from NFT is being transferred.
     * @param to address to NFT is sent.
     */
    modifier beforeTransfer(address from, address to) {
        require(from == address(0) || to == address(0), "Not allowed to transfer token");
        _;
    }
}