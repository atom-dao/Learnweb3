During deployment ensure the following things.

1. Before deployment
    * Address of tokenX and tokenY - You need to provide these two as constructor args while deployment.
2. After deployment
    * Approve contract to execute transferFrom() function - if a user wants to enter the Pool, then S/he needs to approve the contract address for both tokens.
