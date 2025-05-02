// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRouterClient} from "@chainlink/contracts-ccip@1.5.0/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip@1.5.0/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip@1.5.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip@1.5.0/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";
import {IVault} from "./interfaces/IVault.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract Sender is Ownable {
    using SafeERC20 for IERC20;

    // https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#ethereum-testnet-sepolia
    IRouterClient private constant ROUTER = IRouterClient(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    // https://docs.chain.link/resources/link-token-contracts#ethereum-testnet-sepolia
    IERC20 private constant LINK_TOKEN = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    // https://developers.circle.com/stablecoins/docs/usdc-on-test-networks
    IERC20 private constant USDC_TOKEN = IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);
    // https://docs.chain.link/ccip/directory/testnet/chain/ethereum-testnet-sepolia-base-1
    uint64 private constant DESTINATION_CHAIN_SELECTOR = 10344971235874465080;

    event USDCTransferred(
        bytes32 messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        uint256 amount,
        uint256 ccipFee
    );

    error Sender__InsufficientBalance(IERC20 token, uint256 currentBalance, uint256 requiredAmount);
    error Sender__NothingToWithdraw();

    constructor() Ownable(msg.sender) {}

    function transferTokens(
        address _receiver,
        uint256 _amount,
        address _target
    )
        external
        returns (bytes32 messageId)
    {
        if (_amount > USDC_TOKEN.balanceOf(msg.sender)) {
            revert Sender__InsufficientBalance(USDC_TOKEN, USDC_TOKEN.balanceOf(msg.sender), _amount);
        }
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(USDC_TOKEN),
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;
        bytes memory depositFunctionCalldata = abi.encodeWithSelector(
            IVault.deposit.selector,
            msg.sender,
            _amount
        );

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(
                _target, // Address of the target contract
                depositFunctionCalldata
            ),// Encode the function selector and the arguments of the stake function
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200000}) // we need a gas limit to call the receive function
            ),
            feeToken: address(LINK_TOKEN)
        });

        uint256 ccipFee = ROUTER.getFee(
            DESTINATION_CHAIN_SELECTOR,
            message
        );

        if (ccipFee > LINK_TOKEN.balanceOf(address(this))) {
            revert Sender__InsufficientBalance(LINK_TOKEN, LINK_TOKEN.balanceOf(address(this)), ccipFee);
        }

        LINK_TOKEN.approve(address(ROUTER), ccipFee);

        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        USDC_TOKEN.approve(address(ROUTER), _amount);

        // Send CCIP Message
        messageId = ROUTER.ccipSend(DESTINATION_CHAIN_SELECTOR, message);

        emit USDCTransferred(
            messageId,
            DESTINATION_CHAIN_SELECTOR,
            _receiver,
            _amount,
            ccipFee
        );
    }

    function withdrawToken(
        address _beneficiary
    ) public onlyOwner {
        uint256 amount = IERC20(USDC_TOKEN).balanceOf(address(this));
        if (amount == 0) revert Sender__NothingToWithdraw();
        IERC20(USDC_TOKEN).transfer(_beneficiary, amount);
    }
}