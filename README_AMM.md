# Constant-AMM
Took part in the bounty by AtomDAO to code a basic constant AMM


The code is properly identated with comments so that it is easy for everyone to understand.

You can find flow of the code here.

So, we will start by deploting 2 ERC20 tokens.
Now we will deploy the constant AMM. While deploying AMM we will need the addresses of both the deployed tokens so as to interact between them.

We have to initially mint some of the tokens of each type and then have to give approval to the AMM so that we can work on the AMM.
AMM contains three important functions.
The first one is addLiquidity, this is used to by liquidity providers to add liquidity to the LP. Here parameters are the amt of both the tokens which the person is willing to give to provide liquidity.

Second one is swap, this is used by an user to swap between the 2 tokens we have in the LP. Here, one parameter is the token which they have to swap and the amt of token which they wish to swap.

Third one is removeLiquidity which is again used by liquidity providers to remove liquidity to the LP. Here we need only one parameter of how much shares liquidity provider want to dilute and we have a formula(which can be seen in the code) using which we will give the amount of tokens to the liquidity provider.
