// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
import "@OpenZeppelin/contracts/token/ERC20/IERC20.sol";
import "@OpenZeppelin/contracts/utils/math/SafeMath.sol";


contract StakingTokens {
    using SafeMath for uint;
   
    // Constants
    uint constant STAKING_RATE = 6;
    // define here what the rate refers to. Usually it would be a year = 52 weeks in solidity
    // but for test purpose it can be easier to use shorter period like a minute
    uint constant STAKING_PERIODICITY = 1 minutes;
   
    // will store an entry information
    // - lastReferenceDate: last date to use for calculation
    // - totalAmount = sum of staked amount less sum of withdrawn amounts
    // - totalReward = reward expressed in same ERC20 token. Will be converted to "real" reward token later on, when owner wants to withdraw some
    struct TokenInfo {
        uint lastReferenceDate;
        uint totalAmount;
        uint totalReward;
    }
    
    // will contain all the staked tokens and for each stakeholder we will have the full list of stake/widthdraw movements
    TokenInfo[] ERC20Tokens;
    
    // the mapping will map token address to get its corresponding index in ERC20Tokens array
    mapping(address => uint) ERC20TokenMap;
    
    event AmountStaked(uint stakedAmount, uint totalAmount); // ok used in registerProposal function 
   
    function calculateReward (TokenInfo memory _tokenInfo) private view returns (uint){
        return _tokenInfo.totalAmount.mul(block.timestamp.sub(_tokenInfo.lastReferenceDate)).mul(STAKING_RATE).div(STAKING_PERIODICITY);
    }

    /// @notice Stake an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount staked amount
    function stake(address _tokenAddress, uint _amount) public payable {
        // first check that given address is an ERC20 one.
        IERC20 tokenContract = IERC20(_tokenAddress);
        
        uint newTotalAmount = _amount; // default value for first call
        uint newTotalReward = 0; // default value for first call
       
        // check if the token Address already exists in the ERC20TokenMap of msg.sender
        if (ERC20TokenMap[_tokenAddress] == 0) {
            ERC20Tokens.push(TokenInfo(block.timestamp, _amount, 0));
            ERC20TokenMap[_tokenAddress] = ERC20Tokens.length; // careful = we need to keep/use 1 as reference base to keep test on 0 means not already listed
        }
        else {
            TokenInfo storage tokenInfo = ERC20Tokens[ERC20TokenMap[_tokenAddress]-1];
            // calculate reward based on previous amount and previous date and update it 
            tokenInfo.totalReward.add(calculateReward (tokenInfo));
            newTotalReward = tokenInfo.totalReward;
            // update totalAmount with previous totalAmount + _amount
            tokenInfo.totalAmount.add(_amount);
            newTotalAmount = tokenInfo.totalAmount;
            // update lastReferenceDate
            tokenInfo.lastReferenceDate = block.timestamp;
        }
       
        // transfer amount
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        emit AmountStaked(_amount, newTotalAmount);
    }
    
    /// @notice Withdraw an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount amount to be withdrawn
    function withdraw (address _tokenAddress, uint _amount) public {
        // first check that given address is an ERC20 one.
        IERC20 tokenContract = IERC20(_tokenAddress);
       
        // the token should also be registered for the sender
        require(ERC20TokenMap[_tokenAddress] > 0, "Seems you never staked the given token on this contract");
        
        // from here we can instanciate the tokenInfo
        TokenInfo storage tokenInfo = ERC20Tokens[ERC20TokenMap[_tokenAddress]-1];
        
        // check requested amount is available, not higher than what has been staked
        require(tokenInfo.totalAmount >= _amount, "Not enough staked tokens.");
      
        // calculate reward based on previous date and update it 
        tokenInfo.totalReward.add(calculateReward (tokenInfo));
        // update totalAmount with previous totalAmount - _amount
        tokenInfo.totalAmount.sub(_amount);
        // update lastReferenceDate
        tokenInfo.lastReferenceDate = block.timestamp;
        
        // transfer amount back
        tokenContract.transfer(msg.sender, _amount);
    }
    
    function getTokenAmount (address _tokenAddress) public view returns (uint) {
        // the token should also be registered for the sender
        require(ERC20TokenMap[_tokenAddress] > 0, "Seems you never staked the given token on this contract");
        
        // from here we can instanciate the tokenInfo
        TokenInfo storage tokenInfo = ERC20Tokens[ERC20TokenMap[_tokenAddress]-1];
        return tokenInfo.totalAmount;
    }
    
    function getTokenReward (address _tokenAddress) public view returns (uint) {
        // the token should also be registered for the sender
        require(ERC20TokenMap[_tokenAddress] > 0, "Seems you never staked the given token on this contract");
        
        // from here we can instanciate the tokenInfo
        TokenInfo storage tokenInfo = ERC20Tokens[ERC20TokenMap[_tokenAddress]-1];
        return tokenInfo.totalReward;
    }
    
    //TODO continue function getRewardInformation () public { 
} // end Contract StakingTokens


/*
contract AlyraStaking {
    using SafeMath for uint;
   
    // the mapping will map stakeholder addresss to its corresponding contract
    mapping(address => StakingTokens) StakingTokensPerOwnerMap;
   
    function getStakingTokensContract () private returns (StakingTokens) {
        if (StakingTokensPerOwnerMap[msg.sender] == new StakingTokens()) {
            StakingTokensPerOwnerMap[msg.sender] = new StakingTokens();
        }
        return StakingTokensPerOwnerMap[msg.sender];
    }

    /// @notice Stake an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount staked amount
    function stake(address _tokenAddress, uint _amount) public payable {
        // call owner contract stake function
        getStakingTokensContract().stake(_tokenAddress, _amount);
    }
    
    /// @notice Withdraw an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount amount to be withdrawn
    function withdraw (address _tokenAddress, uint _amount) public {
        // call owner contract withdraw function
        getStakingTokensContract().withdraw(_tokenAddress, _amount);
    }
    
    //TODO continue function getRewardInformation () public { 
}
*/
