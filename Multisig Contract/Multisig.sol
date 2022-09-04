// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/*
    Multi Signatory wallet uses Registery contract to manage the signatures in wallet 
    where the transaction will be accounted by all the owners by proposing transaction,
    executing the transactions by one another, which adds security to wallet transactions
 */
import "./Registry.sol";

contract MultiSig is AccessRegistry {
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // maps transaction index to the map of owner to bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    // stores all transactions as an array
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // constructor intitializes the AccessRegistry with the signatories
    constructor(address[] memory _owners) AccessRegistry(_owners) {}

    /*
     * @dev Submits a transaction proposal by owner
     * @param _to Address of the destination
     * @param _value Transaction value in ether
     * @param _data Transaction data
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /*
     * @dev Allows an owner to confirm a transaction
     * @param _txIndex is the transaction index
     */
    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /*
     * @dev Allows any owner to exectue a transaction
     * @param _txIndex is the transaction index
     */
    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= authorizationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /*
     * @dev Allows an owner to revoke the confirmation on a transaction
     * @param _txIndex is the transaction index
     */
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /*
     * @dev Fetches the transaction details
     * @param _txIndex is the transaction index
     */
    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /*
     * @dev Gets all owners(signatories) in wallet
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /*
     * @dev Returns no of transactions proposed till now
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
