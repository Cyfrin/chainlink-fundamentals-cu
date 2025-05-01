// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

interface IVault {
    function deposit(address account, uint256 amount) external;
    function withdraw(uint256 amount)  external;
}