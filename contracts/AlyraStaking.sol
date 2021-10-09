// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
 
import "@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
import "@OpenZeppelin/contracts/token/ERC20/IERC20.sol";


contract AlyraStaking {
   
    // Constants
    uint private constant STAKING_RATE = 6;
    // define here what the rate refers to. Usually it would be a year = 52 weeks in solidity
    // but for test purpose it can be easier to use shorter period like a minute
    uint private constant STAKING_PERIODICITY = 1 minutes;
       
    // will store an entry information
    // - lastTransactionDate: last date to use for calculation
    // - stakedAmount = sum of staked amount less sum of withdrawn amounts
    // - totalReward = reward expressed in same ERC20 token. Will be converted to "real" reward token later on, when owner wants to withdraw some
    struct Token {
        address tokenAddress;
        uint stakedAmount;
        uint previousStakedAmountPerSecond;
        uint lastTransactionDate;
    }
    Token[] private tokens;
    mapping(address => uint) private tokenMap;
    
    /// @notice calculate staked amount per second
    /// @param token struct containing the necessary information
    /// @return an uint
    function getNewStakedAmountPerSecond (Token memory token) private view returns (uint){
        return token.previousStakedAmountPerSecond + ((block.timestamp - token.lastTransactionDate) * token.stakedAmount);
    }

    /// @notice calculate reward based on token parameter
    /// @param token struct containing the necessary information
    /// @return an uint
    function calculateReward (Token memory token) private view returns (uint){
        return (getNewStakedAmountPerSecond(token) * STAKING_RATE) / (STAKING_PERIODICITY * 100);
    }
    
    /// @notice Stake an amount of a specific ERC20 token
    /// @param tokenAddress address of the staked token
    /// @param amount staked amount
    function stakeToken (address tokenAddress, uint amount) public {
        require(amount > 0, "You cannot stake 0 token");

        int arrayIndex = int(tokenMap[tokenAddress]) - 1;
        if (arrayIndex == -1) {
            tokens.push(Token(tokenAddress, amount, 0, block.timestamp));
            tokenMap[tokenAddress] = tokens.length;
        }
        else {
            Token storage currentToken = tokens[uint(arrayIndex)];
            currentToken.previousStakedAmountPerSecond = getNewStakedAmountPerSecond(currentToken);
            currentToken.stakedAmount = currentToken.stakedAmount + amount;
            currentToken.lastTransactionDate = block.timestamp;
        }

        // transfer amount from stakeholder to the contract
        // stakeholder will have first approved (minimum = amount) the contract to transfer tokens from its address
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    }
    
    /// @notice Withdraw an amount of a specific ERC20 token
    /// @param tokenAddress address of the staked token
    /// @param amount amount to be withdrawn
    function withdrawToken (address tokenAddress, uint amount) public {
        int arrayIndex = int(tokenMap[tokenAddress]) - 1;
        require(arrayIndex > -1, "Seems you never staked the given token on this contract");
        
        Token storage currentToken = tokens[uint(arrayIndex)];
        require(currentToken.stakedAmount >= amount, "Not enough staked tokens.");
        
        currentToken.previousStakedAmountPerSecond = getNewStakedAmountPerSecond(currentToken);
        currentToken.lastTransactionDate = block.timestamp;
        currentToken.stakedAmount = currentToken.stakedAmount - amount;

        // transfer amount back to stakeholder
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    /// @notice indicate the total staked amount of a given token 
    /// @param tokenAddress address of the staked token
    /// @return an uint
    function getTokenStakedAmount (address tokenAddress) public view returns (uint) {
        int arrayIndex = int(tokenMap[tokenAddress]) - 1;
        if (arrayIndex == -1) {
            return 0;
        }
        else {
            return tokens[uint(arrayIndex)].stakedAmount;
        }
    }

    /// @notice indicate the calculated reward amount for a given token
    /// @param tokenAddress address of the staked token
    /// @return an uint
    function getTokenReward (address tokenAddress) public view returns (uint) {
        int arrayIndex = int(tokenMap[tokenAddress]) - 1;
        if (arrayIndex == -1) {
            return 0;
        }
        else {
            return calculateReward(tokens[uint(arrayIndex)]);
        }
    }
}
