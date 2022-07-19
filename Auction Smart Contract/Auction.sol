// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
@dev interface for interacting with NFT
*/
interface IERC721 {
    function transfer(address, uint) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

/**
@title Auction contract for selling NFTs.
@author Naman Vyas
@notice The contract should be deployed by the seller. All functions and state variables
are kept public to promote transparency.
*/
contract Auction {
    /* State Variables */

    /// @dev Change this value in production
    uint public constant DURATION = 7 days;

    /// @dev i_variableName is a naming convention for immutable variables
    address payable public immutable i_seller;

    IERC721 public nftContract;
    uint public nftId;
    bool public started = false;
    uint public endAt;
    address payable public highestBidder;
    uint public highestBid;
    mapping(address => uint) balance;

    /* Events */
    event Start();
    event End();
    event Bid(address indexed bidder, uint bidAmount);
    event Withdraw(address indexed bidder, uint amount);

    /* Functions */
    constructor() {
        i_seller = payable(msg.sender);
    }

    /**
    @param {_nft} NFT contract's address
    @param {_nftid} NFT's unique id
    @param {_minBid} minimum bid amount

    @notice Start the auction. Only seller can start the auction.

    @custom:NOTE The seller should approve this contract to transfer NFT before 
    calling this function.
    */
    function start(
        IERC721 _nft,
        uint _nftId,
        uint _minBid
    ) external {
        require(!started, "Already Started !!");
        require(
            payable(msg.sender) == i_seller,
            "Only seller can start the auction."
        );

        nftContract = _nft;
        nftId = _nftId;
        nftContract.transferFrom(msg.sender, address(this), nftId);
        highestBid = _minBid;

        started = true;
        endAt = block.timestamp + DURATION;

        emit Start();
    }

    /**
    @param {amount} amount added to previous bid.
    
    @notice New bid amount is calculated by adding {amount} to the balance of bidder.
    A bid is placed only when the new bid is greater than highest bid.

    @dev default value of balance[msg.sender] is ZERO
    */
    function bid(uint amount) external payable {
        require(started, "Not started.");
        require(endAt > block.timestamp, "Ended!");
        uint bidAmount = balance[msg.sender] + amount;
        require(bidAmount > highestBid, "Not enough amount.");

        highestBid = bidAmount;
        highestBidder = payable(msg.sender);
        balance[msg.sender] = bidAmount;

        emit Bid(highestBidder, highestBid);
    }

    /**
    @notice Exit from the auction and withdraw the balance. Highest bidder can't withdraw.
    */
    function withdraw() external {
        require(msg.sender != highestBidder, "Highest Bidder can't withdraw.");
        uint bal = balance[msg.sender];

        (bool sent, ) = payable(msg.sender).call{value: bal}("");
        require(sent, "Transfer failed!");

        delete balance[msg.sender];

        emit Withdraw(msg.sender, bal);
    }

    /**
    @notice End the auction and transfer NFT to the highest bidder. Transfer the highestBid
    amount to the seller. Auction can't be end before specified duration.

    @dev We'll allow everyone to end the auction because if the seller somehow lost the access
    to this contract then the funds of highest bidder will be locked.
    */
    function end() external {
        require(!started, "you need to start first.");
        require(block.timestamp < endAt, "Auction is still ongoing.");

        if (highestBidder != address(0)) {
            nftContract.transfer(highestBidder, nftId);
            (bool sent, ) = i_seller.call{value: highestBid}("");
            require(sent, "Couldn't pay seller!");
        } else {
            nftContract.transfer(i_seller, nftId);
        }

        started = false;
        delete balance[highestBidder];
        delete highestBidder;
        delete nft;
        delete nftId;

        emit End();
    }
}
