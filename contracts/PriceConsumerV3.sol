// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    /**
     * Returns the latest price
     */
    function getLatestPrice(address priceFeedAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}