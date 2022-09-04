// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
    AccessRegistry contract keeps track of wallet signatory as addresses and also can 
    modify the signatories by Adding,Removing and Renouncing the owners
 */
contract AccessRegistry {
    address public admin;
    // addresses of all owners
    address[] public owners;
    mapping(address => bool) public isOwner;
    // No of authorizations required to perform a transaction
    uint256 authorizationsRequired;

    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event AdminTransfer(address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin is allowed");
        _;
    }

    modifier ownerExists(address _owner) {
        require(isOwner[_owner] == true, "owner doesn't exist");
        _;
    }

    modifier notOwnerExists(address _owner) {
        require(isOwner[_owner] == false, "owner already exists");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "given parameter value is null");
        _;
    }

    /*
     * @dev constructor sets msg.sender to admin and intiantiate all signatories as owners
     */
    constructor(address[] memory _owners) {
        admin = msg.sender;
        require(_owners.length > 0, "atleast one signatory required");
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        authorizationsRequired = (owners.length * 60) / 100;
    }

    /*
     * @dev Adds new owner to the wallet only initialized by Admin
     * @param owner Address of the new owner
     */
    function addOwner(address owner)
        public
        onlyAdmin
        notNull(owner)
        notOwnerExists(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
        getAuthorizations(owners);
    }

    /*
     * @dev Remove owner from the wallet only by Admin
     * @param _owner Address of the new owner
     */
    function removeOwner(address _owner)
        public
        onlyAdmin
        notNull(_owner)
        ownerExists(_owner)
    {
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        getAuthorizations(owners);
    }

    /*
     * @dev Transfers ownership from one wallet to another
     * @param _to Address of the new owner
     * @param _from Address of the old owner
     */
    function transferOwner(address _from, address _to)
        public
        onlyAdmin
        notNull(_from)
        notNull(_to)
        ownerExists(_from)
        notOwnerExists(_to)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == _from) {
                owners[i] = _to;
                break;
            }
        isOwner[_from] = false;
        isOwner[_to] = true;
        emit OwnerRemoval(_from);
        emit OwnerAddition(_to);
    }

    /*
     * @dev Renounce the Admin to new admin
     * @param _newadmin Address of the new admin
     */
    function renounceAdmin(address _newadmin) public onlyAdmin {
        admin = _newadmin;
        emit AdminTransfer(_newadmin);
    }

    /*
     * @dev Updates no of autorizations required every time the signatories changes
     * @param _owners list of address of the owners
     */
    function getAuthorizations(address[] memory _owners) internal {
        authorizationsRequired = (_owners.length * 60) / 100;
    }
}
