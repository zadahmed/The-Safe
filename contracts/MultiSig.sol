//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MultiSigWallet {
    // Events to trigger wallet transactions
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    // store Transactions
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // storing owners of multisigwallet
    address[] public owners;
    mapping(address => bool) public isOwner;

    // storing required approvals needed for completion of transaction
    uint public required;

    Transaction[] public transactions;

    // Showcase Transaction is approved by owner or not for a specific execution approva
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "The user is not owner");
        _;
    }

    modifier txExists(uint _txId ){
        require(_txId < transactions.length,"TX does not exist");
        _;
    }

    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender],"The TX already has been approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(transactions[_txId].executed, "Tx has already been executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners required");
        require(
            _required > 0 && required <= _owners.length,
            "Invalid requirement number of owners"
        );

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner already exists");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit Submit(transactions.length - 1);
    }


    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns(uint count){
        for (uint i; i<owners.length;i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required,"Approvals is less than required");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "TX has failed");
        emit Execute(_txId);
    }

    

}
