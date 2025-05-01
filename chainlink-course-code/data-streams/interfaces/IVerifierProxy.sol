// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IVerifierFeeManager} from "@chainlink/contracts@1.3.0/src/v0.8/llo-feeds/v0.3.0/interfaces/IVerifierFeeManager.sol";

interface IVerifierProxy {
    /**
    * @notice Verifies that the data encoded has been signed.
    * correctly by routing to the correct verifier, and bills the user if applicable.
    * @param payload The encoded data to be verified, including the signed
    * report.
    * @param parameterPayload Fee metadata for billing. For the current implementation this is just the abi-encoded fee token ERC-20 address.
    * @return verifierResponse The encoded report from the verifier.
    */
    function verify(
        bytes calldata payload,
        bytes calldata parameterPayload
    ) external payable returns (bytes memory verifierResponse);

    function s_feeManager() external view returns (IVerifierFeeManager);
}