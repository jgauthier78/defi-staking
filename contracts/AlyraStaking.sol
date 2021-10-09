// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
 
import "@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
import "@OpenZeppelin/contracts/token/ERC20/IERC20.sol";


contract AlyraStaking {
   
    // Constants
    uint constant STAKING_RATE = 6;
    // define here what the rate refers to. Usually it would be a year = 52 weeks in solidity
    // but for test purpose it can be easier to use shorter period like a minute
    uint constant STAKING_PERIODICITY = 1 minutes;
       
    // will store an entry information
    // - LastReferenceDate: last date to use for calculation
    // - StakedAmount = sum of staked amount less sum of withdrawn amounts
    // - totalReward = reward expressed in same ERC20 token. Will be converted to "real" reward token later on, when owner wants to withdraw some
    struct Token {
        address TokenAddress;
        uint StakedAmount;
        uint PreviousStakedAmountPerSecond;
        uint LastReferenceDate;
    }
    Token[] Tokens;
    mapping(address => uint) TokenMap;
    
    function getNewStakedAmountPerSecond (Token memory _token) private view returns (uint){
        return _token.PreviousStakedAmountPerSecond + ((block.timestamp - _token.LastReferenceDate) * _token.StakedAmount);
    }

    /// @notice calculate reward based on _token parameter
    /// @dev simple calculation based on prorata
    /// @param _token struct containing the necessary information (amount and LastReferenceDate)
    /// @return an uint
    function calculateReward (Token memory _token) private view returns (uint){
        return (getNewStakedAmountPerSecond(_token) * STAKING_RATE) / (STAKING_PERIODICITY * 100);
        // uint elapsedTimeInSeconds = block.timestamp - token.lastReferenceDate;
        // uint elapsedTimeInStakingPeriodicity = elapsedTimeInSeconds / STAKING_PERIODICITY;
        // return (elapsedTimeInStakingPeriodicity * STAKING_RATE * token.totalStakedAmount) / 100;
    }
    
    /// @notice Stake an amount of a specific ERC20 token
    /// @dev reward calculation is done before applying the new amount to the total
    /// @param _tokenAddress address of the staked token
    /// @param _amount staked amount
    function StakeToken (address _tokenAddress, uint _amount) public {
        require(_amount > 0, "You cannot stake 0 token");

        int arrayIndex = int(TokenMap[_tokenAddress]) - 1;
        if (arrayIndex == -1) {
            Tokens.push(Token(_tokenAddress, _amount, 0, block.timestamp));
            TokenMap[_tokenAddress] = Tokens.length;
        }
        else {
            Token storage currentToken = Tokens[uint(arrayIndex)];
            currentToken.PreviousStakedAmountPerSecond = getNewStakedAmountPerSecond(currentToken);
            currentToken.StakedAmount = currentToken.StakedAmount + _amount;
            currentToken.LastReferenceDate = block.timestamp;
        }

        // transfer amount from stakeholder to the contract
        // stakeholder will have first approve (minimum = _amount) the contract to transfer tokens from its address
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
    }
    
    /// @notice Withdraw an amount of a specific ERC20 token
    /// @dev reward calculation is done before withdrawing the required amount from the total
    /// @param _tokenAddress address of the staked token
    /// @param _amount amount to be withdrawn
    function WithdrawToken (address _tokenAddress, uint _amount) public {
        int arrayIndex = int(TokenMap[_tokenAddress]) - 1;
        require(arrayIndex > -1, "Seems you never staked the given token on this contract");
        
        Token storage currentToken = Tokens[uint(arrayIndex)];
        require(currentToken.StakedAmount >= _amount, "Not enough staked tokens.");
        
        currentToken.PreviousStakedAmountPerSecond = getNewStakedAmountPerSecond(currentToken);
        currentToken.LastReferenceDate = block.timestamp;
        currentToken.StakedAmount = currentToken.StakedAmount - _amount;

        // transfer amount back to stakeholder
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }
    
    function GetTokenStakedAmount (address _tokenAddress) public view returns (uint) {
        int arrayIndex = int(TokenMap[_tokenAddress]) - 1;
        if (arrayIndex == -1) {
            return 0;
        }
        else {
            return Tokens[uint(arrayIndex)].StakedAmount;
        }
    }

    function GetTokenReward (address _tokenAddress) public view returns (uint) {
        int arrayIndex = int(TokenMap[_tokenAddress]) - 1;
        if (arrayIndex == -1) {
            return 0;
        }
        else {
            return calculateReward(Tokens[uint(arrayIndex)]);
        }
    }
}
