// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

/**
@title Constant Product Automated Market Maker
@author Naman Vyas
 */
contract CPAMM {
    /* State Variables */
    uint public FEE_FACTOR = uint(997) / uint(1000); // fee = 0.3%
    IERC20 public immutable tokenX;
    IERC20 public immutable tokenY;
    uint public reserveX;
    uint public reserveY;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    /* Events */
    event Swap(
        address indexed from,
        IERC20 indexed tokenIn,
        uint amountIn,
        IERC20 indexed tokenOut,
        uint amountOut
    );
    event AddLiquidity(
        address indexed to,
        uint amountX,
        uint amountY,
        uint shares
    );
    event RemoveLiquidity(
        address from,
        uint shares,
        uint amountX,
        uint amountY
    );

    constructor(address _tokenX, address _tokenY) {
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
    }

    /**
    @param _to investor
    @param _amount no. of shares.
    @notice Append shares to given address and update totalSupply.
     */
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    /**
    @param _from investor
    @param _amount no. of shares.
    @notice Remove shares from given address and update totalSupply.
     */
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    /**
    @param _reserveX updated value of reserveX
    @param _reserveY updated value of reserveY
    @notice update reserves.
     */
    function _update(uint _reserveX, uint _reserveY) private {
        reserveX = _reserveX;
        reserveY = _reserveY;
    }

    /**
    @param _tokenIn type of token.
    @param _amountIn no. of tokens.

    @notice Swap tokens by transferring {_amountIn} tokens of type {_tokenIn}
    to the contract (or pool). In returns Contract calculates the fee and
    transfer complimentary tokens to the user.

    @dev Formula used: dy = ydx / (x + dx).
    also, while updating reserves, we calculate the new value of reserves
    manually instead of relying on balance of contract of tokenX and tokenY.
    Because someone can transfer the tokens to the contract and manipulate the
    reserves of contract.
     */
    function swap(address _tokenIn, uint _amountIn) external {
        require(
            _tokenIn == address(tokenX) || _tokenIn == address(tokenY),
            "Invalid token."
        );
        require(_amountIn > 0, "amountIn = 0");

        bool isTokenX = _tokenIn == address(tokenX);
        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint reserveIn,
            uint reserveOut
        ) = isTokenX
                ? (tokenX, tokenY, reserveX, reserveY)
                : (tokenY, tokenX, reserveY, reserveX);

        // Transfer tokens to the pool.
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        /* Swapping */

        uint amountInWithFee = _amountIn * FEE_FACTOR;

        // formula for amountOut:-
        // dy = ydx / (x + dx);
        uint amountOut = (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);

        // transfer swapped tokens
        tokenOut.transfer(msg.sender, amountOut);

        // Update reserves
        (uint _newReserveX, uint _newReserveY) = isTokenX
            ? (reserveX + _amountIn, reserveY - amountOut)
            : (reserveX - amountOut, reserveY + _amountIn);

        _update(_newReserveX, _newReserveY);

        emit Swap(msg.sender, tokenIn, _amountIn, tokenOut, amountOut);
    }

    /**
    @param _amountX no. of tokenX
    @param _amountY no. of tokenY

    @notice Transfer {_amountX} of tokenX and {_amountY} of tokenY to
    the contract (or pool) and mint corresponding number of shares to
    the user. user must ensure that the ratio of {_amountX} and {_amountY}
    should be equal to current price. To get current price, use function
    getPrice().
    */
    function addLiquidity(uint _amountX, uint _amountY)
        external
    {
        tokenX.transferFrom(msg.sender, address(this), _amountX);
        tokenY.transferFrom(msg.sender, address(this), _amountY);

        if (reserveX > 0 || reserveY > 0) {
            // Check if the given amount corresponds to current price
            // price = x/y
            // hence, dx/dy should be equal to x/y
            require(reserveX * _amountY == reserveY * _amountX, "x / y != dx / dy");
        }

        /* Mint Shares */
        
        // Liquidity = f(x, y) = xy
        // shares should be proportional to liquidity, hence we've
        // chosen sqrt() function for shares.
        // shares = sqrt(Liquidity) = sqrt(xy).
        uint shares;
        if (totalSupply == 0) {
            // formula: sqrt(xy)
            shares = _sqrt(_amountX * _amountY);
        } else {
            // formula:-
            // shares = increase in liquidity * total liquidity
            // increase in liquidity = dx/x = dy/y
            // shares = (dx/x) * T = (dy/y) * T
            // for security reasons, we'll take minimum of these two. Although they
            // should be same in ideal case.
            shares = _min(
                (_amountX * totalSupply) / reserveX,
                (_amountY * totalSupply) / reserveY
            );
        }
        require(shares > 0, "shares == 0");
        _mint(msg.sender, shares);

        _update(reserveX + _amountX, reserveY + _amountY);

        emit AddLiquidity(
            msg.sender,
            _amountX,
            _amountY,
            shares
        );
    }

    /**
    @param _shares no. of shares to remove

    @notice Remove {_shares} no. of shares and transfer {amountX} of tokenX
    and {amountY} of tokenY to the user.
    */
    function removeLiquidity(uint _shares)
        external
    {
        // formula:-
        // dx = s / T * x
        // dy = s / T * y
        uint amountX = (_shares * reserveX) / totalSupply;
        uint amountY = (_shares * reserveY) / totalSupply;
        require(
            amountX > 0
            && amountY > 0,
            "amountX or amountY == 0"
        );

        _burn(msg.sender, _shares);
        _update(reserveX - amountX, reserveY - amountY);

        tokenX.transfer(msg.sender, amountX);
        tokenY.transfer(msg.sender, amountY);

        emit RemoveLiquidity(
            msg.sender,
            _shares,
            amountX,
            amountY
        );
    }

    function getPrice() public view returns (uint price) {
        price = reserveX / reserveY;
    }

    function _sqrt(uint y) private pure returns (uint z) {
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

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}