pragma solidity ^0.8.13; // specifying the version of the solidity we will be using to deploy the contract

//Copied the basic code interfacr of ERC20 from openzepplin 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returning the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returning the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returning a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returning the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returning a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returning a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ERC20 is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Yura";
    string public symbol = "YR";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}


contract amm  
{
    //mentioning all the state variables
    IERC20 public immutable tok1; //initializing first token
    IERC20 public immutable tok2; //initializing second token 

    uint public reserve0; //to keep a check of the tok1 in pool
    uint public reserve1; //to keep a check of the tok2 in pool

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    //defining the constructor to give initial values to both the token variables
    constructor(address _tok1, address _tok2) {
        tok1 = IERC20(_tok1);
        tok2 = IERC20(_tok2);
    }

    //basic function to mint new tokens
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount; //giving to the wallet
        totalSupply += _amount; //increasing total supply
    }

    //basic function to burn the already existing tokens
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount; //taking from the wallet
        totalSupply -= _amount; //decreasing the total supply
    }


    function _update(uint _reserve0, uint _reserve1) private //it is used to update the reserves which we have written down below
    {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    //function to swap
    function swap(address _tokIn, uint _amountIn) external returns (uint amountOut) //takes address of token to swap and how much tokens user want to swap and returns the other token
    {
        require(_tokIn == address(tok1) || _tokIn == address(tok2),"invalid token"); //to checkif user is swapping that single pair which is there in our LP and nothing else
        require(_amountIn > 0, "amount in = 0"); //also checking if input is greater than 0 or else it doesnt make sense to swap

        bool istok1 = _tokIn == address(tok1); //to check tokIn is either the first token or the second one
        (IERC20 tokIn, IERC20 tokOut, uint reserveIn, uint reserveOut) = istok1 // to simply associate the right token to right reserve by using basic ternary operator so that we can select which token remove and which to add
            ? (tok1, tok2, reserve0, reserve1)
            : (tok2, tok1, reserve1, reserve0);

        tokIn.transferFrom(msg.sender, address(this), _amountIn); //transfering the tokens

        
        // 0.5% fee
        uint amountInWithFee = (_amountIn * 995) / 1000; //now here a fee of 0.3 is not deducted
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee); //we deducted the fee and passed that value to amount out which will help us giving it back to user

        tokOut.transfer(msg.sender, amountOut); //sending the other token to user

        _update(tok1.balanceOf(address(this)), tok2.balanceOf(address(this))); //here we update the reserves by calling the func
    }

    //function to add liquidity to the pools
    function addLiquidity(uint _amt1, uint _amt2) external returns (uint shares) //taking in amt of both the tokens the user want to add in LP
    {
        tok1.transferFrom(msg.sender, address(this), _amt1); //pulling in tok1 from user
        tok2.transferFrom(msg.sender, address(this), _amt2); //pulling in tok2 from user

        
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amt2 == reserve1 * _amt1, "x / y != dx / dy"); //so here we are checking the condition if in case the price of tokens have not changed so its simple dy/dx = y/x if this satisfies we are good to go
        }

        if (totalSupply == 0) {
            shares = _sqrt(_amt1 * _amt2);
        } else {
            shares = _min((_amt1 * totalSupply) / reserve0,(_amt2 * totalSupply) / reserve1); //using min func we defined to find the shares that will be added 
        }
        require(shares > 0, "shares = 0"); //to check if shares is greater than 0 so that we can give the user their minted shares
        _mint(msg.sender, shares); //giving shares as in voila we have minted new tokens

        _update(tok1.balanceOf(address(this)), tok2.balanceOf(address(this))); //again updating the reserves so as to get the right values after the process is done
    }

    //function to remove liquidity
    function removeLiquidity(uint _shares) external returns (uint amount1, uint amount2)
    {

        // bal1 >= reserve0
        // bal2 >= reserve1
        uint bal1 = tok1.balanceOf(address(this)); //to get the balance of the token1 in LP
        uint bal2 = tok2.balanceOf(address(this)); //to get the balance of the token2 in LP

        amount1 = (_shares * bal1) / totalSupply; // so here we are calculating how much token1 we have to give to users for him requesting to remove his share from lp
        amount2 = (_shares * bal2) / totalSupply; // so here we are calculating how much token2 we have to give to users for him requesting to remove his share from lp
        require(amount1 > 0 && amount2 > 0, "amount1 or amount2 = 0"); // a check so that we have both the values greater than 0 which we will be using to transfer before removing liquidity from lp

        _burn(msg.sender, _shares); //calling the burn func to remove the shares of users
        _update(bal1 - amount1, bal2 - amount2); //updating the values in lp after burning

        tok1.transfer(msg.sender, amount1); //transferuing token1 to user
        tok2.transfer(msg.sender, amount2); //transfering token2 to user
    }

    //a basic square root function which we are using to calculate the liquidity
    function _sqrt(uint y) private pure returns (uint z) 
    {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint)  //to find the minimum out of x and y like we are not haivng 50:50
    {
        return x <= y ? x : y;
    }
}