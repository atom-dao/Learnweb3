// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainLinkTask is VRFConsumerBaseV2, Ownable{

    AggregatorV3Interface internal priceFeed;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

  // Your subscription ID.
    uint64 public s_subscriptionId;

  // Rinkeby coordinator.
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // Rinkeby LINK token contract.
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  int256 public s_randomWords;
  uint256 public s_requestId;
  int public ETHPrice;
  address s_owner;


    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        /**
            * Network: Rinkeby
            * Aggregator: ETH/USD
            * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
            */
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        s_subscriptionId = subscriptionId;
    }



    /**@dev fetches ETH price in USD*/
    function getETHPrice() public {
        (,int price,,,) = priceFeed.latestRoundData();
        ETHPrice = price / 10**8;
    }



    /**@dev processes and stores the received random values 
        and makes sure that it is between 1000 and 200- 
    */
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = int((randomWords[0] % 2000)+1000);
    if(s_randomWords > 2000){
        s_randomWords = s_randomWords - 1000;
    }
  }


    /**
        @dev check the ETH status
        returns true for ETH greater than random number
        and false for ETH price less than random number;
     */
    function checkETHStatus() external view returns(bool){
      bool status;
      if(ETHPrice > s_randomWords){
          status = true;
      }
      return status;
    }

    
    /**@dev request random number to be able to use vrf */
    // 1000000000000000000 = 1 LINK
    // Assumes the subscription is funded sufficiently.
    function requestRandomNumber() external onlyOwner {
      // Will revert if subscription is not set and funded.
      s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
    }
  
}