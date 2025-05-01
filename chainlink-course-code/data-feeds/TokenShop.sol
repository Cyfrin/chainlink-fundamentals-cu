// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts@1.3.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";
import {MyERC20} from "./MyERC20.sol";

contract TokenShop is Ownable {

    AggregatorV3Interface internal immutable i_priceFeed;
    MyERC20 public immutable i_token;

    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_USD_PRICE = 2 * 10 ** TOKEN_DECIMALS; // 2 USD with 18 decimals

    event BalanceWithdrawn();

    error TokenShop__ZeroETHSent();
    error TokenShop__CouldNotWithdraw();

    constructor(address tokenAddress) Ownable(msg.sender) {
        i_token = MyERC20(tokenAddress);
        /**
        * Network: Sepolia
        * Aggregator: ETH/USD
        * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        */
        i_priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    /**
    * Returns the latest answer
    */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = i_priceFeed.latestRoundData();
        return price;
    }

    function amountToMint(uint256 amountInETH) public view returns (uint256) {
        // Sent amountETH, convert to USD amount
        uint256 ethUsd = uint256(getChainlinkDataFeedLatestAnswer()) * 10 ** 10; // ETH/USD price with 8 decimal places -> 18 decimals
        uint256 ethAmountInUSD = amountInETH * ethUsd / 10 ** 18; // ETH = 18 decimals
        return (ethAmountInUSD * 10 ** TOKEN_DECIMALS) / TOKEN_USD_PRICE; // * 10 ** TOKEN_DECIMALS since tokenAmount needs to be in TOKEN_DECIMALS
    }

    receive() external payable {
        // convert the ETH amount to a token amount to mint
        if (msg.value == 0) {
            revert TokenShop__ZeroETHSent();
        }
        i_token.mint(msg.sender, amountToMint(msg.value));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert TokenShop__CouldNotWithdraw();
        }
        emit BalanceWithdrawn();
    }
}