
# Chainlinktask

## Deployment

- Create subscription on [Chainlink VRF](https://vrf.chain.link/) and Fund with [LINK tokens](https://faucets.chain.link/rinkeby)(used as fee)

- Copy the Solidity code in ``/Chainlink VRF`` folder and paste it in Remix

- Compile the code and change the deployment environment to injected provider(Metamask)

- Copy the Subscription_Id from Chainlink subscription and deploy the contract with initialising with Subscription_Id 

- Copy address of the deployed contract, add it as a Consumer in subscription portal(Chainlink VRF)

## Test Case

- Call ``getLatestPrice`` to get ETH price in USD

&emsp;&emsp; ![Screenshot (177)](https://user-images.githubusercontent.com/98147030/184120196-090f78c5-e737-418f-aac8-55c3d6197e7d.png)

- Call ``requestRandomWords`` to request random number from VRF, the random number get updated in these process by automatically calling the inbult function ``fulfillRandomWords``

&emsp;&emsp; ![Screenshot (178)](https://user-images.githubusercontent.com/98147030/184120260-4c2750d3-f1f4-4315-af4e-25c5fb891d0d.png)

- Call ``checkEthPrice`` to check ETH price is greater than random number or not, if yes returns true or else false

&emsp;&emsp; ![Screenshot (179)](https://user-images.githubusercontent.com/98147030/184120550-666f63cb-1b88-4983-8a1d-f85c92d80ab8.png)

## Screenshot

&emsp;![Screenshot (176)](https://user-images.githubusercontent.com/98147030/184120878-8246f2b9-6a04-47f5-b5be-bee8a97ba11f.png)

