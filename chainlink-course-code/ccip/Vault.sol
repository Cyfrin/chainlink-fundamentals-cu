// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@chainlink/contracts@1.3.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract Vault {
    // hard coded to Base Sepolia
    IERC20 public constant USDC = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);

    mapping(address => uint256) public balances;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    error Vault__InsufficientBalance(uint256 currentBalance, uint256 requiredAmount);
    error Vault__FailedToTransfer(address to, uint256 amount);
    error Vault__FailedToDeposit(address to, uint256 amount);

    // Allow anyone to deposit USDC
    // Make sure you approve this contract before calling!
    function deposit(address account, uint256 amount) external {
        balances[account] += amount;
        USDC.transferFrom(account, address(this), amount);
        emit Deposit(account, amount);
    }

    function withdraw(uint256 amount) external {
        if(balances[msg.sender] < amount) {
            revert Vault__InsufficientBalance(balances[msg.sender], amount);
        }
        balances[msg.sender] -= amount;
        USDC.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}