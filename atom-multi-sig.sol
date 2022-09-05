// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Wallet{
    address[] public approvers;
      //number of approvers needed to approve a transaction
      //if there are 5 approvers and quorum is 3, then for a txn to pass through we need signature from atlesat 3 wallets
     uint public quorum_len;
     // a minimum of 60% authorization by the signatory wallets to perform a transaction.
    function quorum_calculation() public  returns(uint) {
	 quorum_len  = uint(approvers.length * 60)/100;
		return quorum_len;
	}

    //keeping track of the transaction id
    uint public nextId;
   
    //details regarding the transfer - custom data type
    struct Transfer{
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
         uint numConfirmations;
    }

    

    Transfer[] public transfers;

    constructor(address[] memory _approvers)  {
        approvers = _approvers;
    }

    //access-control

    modifier onlyApprover(){
        bool allowed = false;
        for(uint i =0; i< approvers.length; i++){
            if(approvers[i] == msg.sender ){
                allowed = true;
            }
        }
        require(allowed == true,"only approvers are allowed to access this function");
        _;
    }

    //function to transfer tokens

    function createTransfer(address payable to, uint amount) external onlyApprover(){
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false,
            0
        ));
        
    }

    //Getting the transfer history

    function getTransfers() public view returns(Transfer[] memory){
        return transfers;
    }


    //Approve transfer

    mapping(address=> mapping( uint => bool)) public approvals;

    function approveTransfer(uint id) external  onlyApprover(){

        require(transfers[id].sent == false ,'transfer already made'); 
        require(approvals[msg.sender][id] ==false, 'Cannot approve twice');

        approvals[msg.sender][id] = true; //approving the transaction
        transfers[id].approvals++;  //this is struct's value to keep track of number of approvals. 

        //checking if there are enough number of approvals present for the transaction 
        if(transfers[id].approvals >= quorum_len){
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            to.transfer(amount);  //internal function available in solidity to transfer value. 

        }


    }


    // to send ether to the contract
    // in-built function available in solidity to get ether/tokens into the contract. 
    //Emitting the event to indicate the front-end for funds arrival
    event Deposit(address indexed sender, uint amount, uint balance);
    receive() external payable {
          emit Deposit(msg.sender, msg.value, address(this).balance);
    }  

mapping(uint => mapping(address => bool)) public isConfirmed;
event RevokeConfirmation(address indexed owner, uint indexed txIndex);
function revokeConfirmation(uint id)
        public
        onlyApprover

    {
        require(transfers[id].sent == false ,'transfer already made');
        require(approvals[msg.sender][id] ==false, 'Cannot approve twice');
        Transfer storage transaction = transfers[id];

        require(isConfirmed[id][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[id][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, id);
    }




}