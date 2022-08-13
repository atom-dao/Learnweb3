# Deployment

1. get Link token from [link faucet](https://faucets.chain.link/rinkeby?_ga=2.234874718.1328601376.1660094136-874318943.1659360958)

2. create a subscription here [subscription](https://vrf.chain.link/)

3. Copy the .sol file in this folder to remix. choose Injected web3 and network rinkeby.
4. Deploy the contract pass in your subscription to the constructor. Then add the deployed contract address has a consumer on your subscription page
5. call `getETHPrice()`  to get ETH price 
6. call `requestRandomNumber()` to get a random. `Note this usually takes time, you can go here to check the fulliment status your subscription Id ` 
7. call `checkETHStatus()` to check ETH status

    