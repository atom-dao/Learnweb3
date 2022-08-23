// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* These Soulbound smart contract represents the NFTs which are certificates of
   an degree for students passed out from college.
   The owner(college) of the contract need to issue an certificate for a student so that 
   the student can claim the certificate only once and not transferable
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SoulBoundNFT is ERC721, ERC721URIStorage, Ownable {
    //  counters used to track the number of ids and issuing ERC721 ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // cerificates var maps between student address and the tokenURI that contains metadata
    mapping(address => string) public certificates;

    // issuedCerrtificates var maps student address and the status of the certificate issued
    mapping(address => bool) public issuedCertificate;

    constructor() ERC721("SoulDegree", "SDG") {}

    /* @dev checks whether certificate issued or not
       @param _studentAddress is the address to check whether certificate issued or not
     */
    function checkCertificateissued(address _studentAddress)
        public
        view
        returns (bool)
    {
        return issuedCertificate[_studentAddress];
    }

    // @dev issues certificate to a address mentioned by the owner only
    function issueCertificate(address _to) public onlyOwner {
        issuedCertificate[_to] = true;
    }

    /* @dev student claims certificate by minting NFT
       @param _tokenUri is the url to the metadata of the NFT
     */
    function claimCertificate(string memory _tokenUri) public {
        require(
            checkCertificateissued(msg.sender),
            "certificate is not issued or claimed"
        );
        issuedCertificate[msg.sender] = false;
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenUri);
        certificates[msg.sender] = _tokenUri;
    }

    /* @dev mints NFT directly to the student only by the owner
       @param _to is the address of the student to be minted
       @param _uri is the url of metadata associated with the specific student
     */
    function safeMint(address _to, string memory _uri) public onlyOwner {
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    /* @dev burns the NFT owned by owner , only owner can be allowed to burn token
       @param _tokenId is the id of the token to be burn
     */
    function burn(uint256 _tokenId) public {
        address owner = ERC721.ownerOf(_tokenId);
        require(owner == msg.sender, "Only Owner can burn token");
        _burn(_tokenId);
    }

    /* @dev revokes the NFT issued to someone by owner of the contract
       @param _tokenId is the id of the token to be revoked
     */
    function revokeToken(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    /* @dev checks if @param from is set to zero, if yes then NFT will be transfered to new owner  
       if No then the transaction to be minted is stopped so that the NFT will become
       non-transferable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal virtual override {
        // checks if the revoke is happening which is done by owner
        if (msg.sender != owner()) {
            require(from == address(0), "token transfer is blocked");
        }
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    // _burn and tokenURI are overridden from the parent contracts
    function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }
}
