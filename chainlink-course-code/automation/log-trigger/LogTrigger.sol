// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.26;

import { Log, ILogAutomation } from "@chainlink/contracts@1.3.0/src/v0.8/automation/interfaces/ILogAutomation.sol";

contract LogTrigger is ILogAutomation {  
    event CountedBy(address indexed msgSender);

    uint256 public counted;

    constructor() {}

    function checkLog(  
        Log calldata log,  
        bytes memory  
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {  
        upkeepNeeded = true;  
        address logSender = bytes32ToAddress(log.topics[1]);  
        performData = abi.encode(logSender);  
    }

    function performUpkeep(bytes calldata performData) external override {  
        counted += 1;  
        address logSender = abi.decode(performData, (address));  
        emit CountedBy(logSender);  
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {  
        return address(uint160(uint256(_address)));  
    }  
}