// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract AuctionContract is Ownable{

    ERC721 NFT;

    error AuctionPeriodElapsed(uint auctionPeriod, uint currentTime);
    error YouCannotBidBelowTheHighestBid(uint highestBid, uint yourBid);
    error AuctionPeriodNotYetElapsed(uint currentTime, uint auctionPeriod);
    error NotABidder();
    error YouDontHaveTheHighestBid(uint highestBid,uint yourBid);
    error CannotWithdrawTheHighestBid();

    struct Auction{
        address contractAddress;
        uint tokenId;
        uint AuctionPeriod;
        uint highestBid;
        bool canBid;
        mapping(address => bool) isBidder;
        mapping(address => uint) bid;
    }

    uint public auctionId;

    mapping(uint => Auction) Auctions;

    event AuctionStart(address NFTAddress, uint _tokenId, uint indexed auctionPeriod, uint indexed auctionId);
    event NftClaimed(address nftAddress, uint tokehId, uint bid, address bidder);
    event BidWithDrawBid(address bidder, uint bid);


    /**
     * @dev transfers the nft to be auction to the contract .
     *
     * Requirements:
     * - `_contractAddress` contract address of the nft to be auctioned;
     * - `_tokenId` tokenId of the nft to be auctioned.
     * - `_auctionPeriod` the period for which the auction will take place, 
     %      this should be in unix timestamp .
     * - only `owner` can call this function.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {AuctionStart} event.
     */
    function addSingleNftForAuction(
        address _contractAddress, 
        uint _tokenId,
        uint _auctionPeriod
        ) public onlyOwner returns(bool){
        uint id = auctionId;
        Auction storage auction = Auctions[id];
        auction.contractAddress = _contractAddress;
        auction.tokenId = _tokenId;
        auction.AuctionPeriod = block.timestamp +_auctionPeriod;
        NFT = ERC721(_contractAddress);
        NFT.transferFrom(msg.sender, address(this), _tokenId);
        auction.canBid = true;
        auctionId++;
        emit AuctionStart(_contractAddress, _tokenId, _auctionPeriod, id);
        return true;
    }

    /**
     * @dev makes bid to for the nft. newBid are added to the previous bid;
     *      can only bid during the auctionPeriod, and cannot bid less than the 
     *      current highest bid
     *
     * Requirements:
     * - `_auctionId` the auctionId for the nft ;
     * - bid must be greater than highest bid.
     * - auction period must be ongoing.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {} event.
     */
    function bid(uint _auctionId) external payable returns(bool){
        require(_auctionId < auctionId, "Auction: Invalid AuctionId");
        Auction storage auction = Auctions[_auctionId];
        uint auctionPeriod = auction.AuctionPeriod;
        if(block.timestamp > auctionPeriod){
            revert AuctionPeriodElapsed({auctionPeriod:auctionPeriod, currentTime: block.timestamp});
        }
        uint highestBid = auction.highestBid;
        uint currentBid = auction.bid[msg.sender];
        uint newBid = currentBid + msg.value;
        if(highestBid > newBid){
            revert YouCannotBidBelowTheHighestBid({highestBid:highestBid, yourBid:msg.value});
        }
        
        auction.bid[msg.sender] = newBid; 
        auction.highestBid = newBid;
        auction.isBidder[msg.sender] = true;
        return true;
    }

    /**
     * @dev transfer nft to the highest bid and 
     * the `msg.sender` to the owner
     *  
     * Requirements:
     * - `_auctionId` the auctionId for the nft ;
     * - `msg.sender` must have the highest bid.
     * - auction period must be have end.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {NftClaimed} event. 
     */
    function ClaimNft(uint _auctionId) public returns(bool){
        require(_auctionId < auctionId, "Auction: Invalid AuctionId");
        Auction storage auction = Auctions[_auctionId];
        bool isBidder = auction.isBidder[msg.sender];
        if(isBidder == false){
            revert NotABidder();
        }
        uint auctionPeriod = auction.AuctionPeriod;
        if(block.timestamp < auctionPeriod){
            revert AuctionPeriodNotYetElapsed({currentTime:block.timestamp, auctionPeriod:auctionPeriod});
        }
        uint buyerBid = auction.bid[msg.sender];
        uint highestBid = auction.highestBid;
        if(buyerBid < highestBid){
            revert YouDontHaveTheHighestBid({highestBid: highestBid, yourBid:buyerBid});
        }
        uint tokenId = auction.tokenId;
        payable(owner()).transfer(buyerBid);
        address nftAddress = auction.contractAddress;
        NFT = ERC721(nftAddress);
        NFT.transferFrom(address(this),msg.sender, tokenId);
        auction.canBid = false;
        emit NftClaimed(nftAddress, tokenId, buyerBid, msg.sender);
        return true;
    }


    /**
     * @dev withdraws bid from the auction
     *
     * Requirement
     * - `_auctionId` the auctionId for the nft.
     * - `msg.sender` must be a bidder
     * - `msg.sender` must not have the highest bid

     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {NftClaimed} event. 
     */

    function withDrawBid(uint _auctionId) public returns(bool){
        require(_auctionId < auctionId, "Auction: Invalid AuctionId");
        Auction storage auction = Auctions[_auctionId];
        bool isBidder = auction.isBidder[msg.sender];
        if(isBidder == false){
            revert NotABidder();
        }
        uint highestBid = auction.highestBid;
         uint buyerBid = auction.bid[msg.sender];
        if(buyerBid == highestBid){
            revert CannotWithdrawTheHighestBid();
        }
        (bool sent, ) = msg.sender.call{value: buyerBid}("");
        require(sent, "Failed to send Ether");
        emit BidWithDrawBid(msg.sender, buyerBid);
        return true;
    }


     /**
     * @dev view auction details
     *
     * Requirement
     * - `_auctionId` the auctionId for the nft.
     *  
     * returns NftContractAddress, tokenId, highestBid, auctionPeriod, and a bool that shows if bid is allowed;
     */

    function viewAuctionDetails(uint _auctionId) public view returns(address, uint, uint, uint, bool){
        require(_auctionId < auctionId, "Auction: Invalid AuctionId");
        Auction storage auction = Auctions[_auctionId];
        address nftAddress = auction.contractAddress;
        uint auctionPeriod = auction.AuctionPeriod;
        uint highestBid = auction.highestBid;
        uint tokenId = auction.tokenId;
        bool canBid = auction.canBid;
        return(nftAddress, auctionPeriod, highestBid, tokenId,canBid);
    }
}