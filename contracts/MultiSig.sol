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
}
