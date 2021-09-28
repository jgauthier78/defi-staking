// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@OpenZeppelin/contracts/access/Ownable.sol";
import "@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
import "@OpenZeppelin/contracts/token/ERC20/IERC20.sol";
import "@OpenZeppelin/contracts/utils/math/SafeMath.sol";

contract AlyraStaking is Ownable {
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
    
    // will allow to define the couple owner (msg.sender) + token (address)
    // to get a kind of unique identifier to map the below array
    struct OwnedToken {
        address tokenOwner;
        address tokenAddress;
    }
   
    // will contain all the staked tokens and for each we will have the full list of stake/widthdraw movements
    TokenInfo[] ERC20Tokens;
   
    // the mapping will map OwnedToken to get its corresponding index in ERC20Tokens array
    mapping(OwnedToken => uint) ERC20map;
   
    // to be planned = event for each function
   
    function calculateReward (TokenInfo memory _tokenInfo) private view returns (uint){
        return _tokenInfo.totalAmount.mul(block.timestamp.sub(_tokenInfo.lastReferenceDate)).mul(STAKING_RATE).div(STAKING_PERIODICITY);
    }
   

    /// @notice Stake an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount staked amount
    function stake(address _tokenAddress, uint _amount) public payable {
        // TODO require = check that msg.balance enough
        // TODO require = check that msg.sender should not be the owner / address 0
        
        // first check that given address is an ERC20 one.
        IERC20 tokenContract = IERC20(_tokenAddress);
       
        // check if the struct msg.sender + token Address already exists in the mappings,
        // if not consider a new AmountEntry
        OwnedToken ownedToken = OwnedToken({tokenOwner: msg.sender, tokenAddress: _tokenAddress});
        if (ERC20map[ownedToken] == 0) {
            ERC20Tokens.push(TokenInfo(block.timestamp, _amount, 0));
            ERC20map[ownedToken] = ERC20Tokens.length; // careful = we need to keep/use 1 as reference base to keep test on 0 means not already listed
        }
        else {
            TokenInfo storage tokenInfo = ERC20Tokens[ERC20map[ownedToken]-1];
            // update totalAmount with previous totalAmount + _amount
            tokenInfo.totalAmount.add(_amount);
            // update lastReferenceDate
            tokenInfo.lastReferenceDate = block.timestamp;
            // calculate reward based on previous date and update it 
            tokenInfo.totalReward.add(calculateReward (tokenInfo));
        }
       
        // transfer amount
        tokenContract.transferFrom(msg.sender, address(this), _amount);
       
        // emit AmountStaked;
    }
    
    /// @notice Withdraw an amount of a specific ERC20 token
    /// @dev 
    /// @param _tokenAddress address of the staked token
    /// @param _amount amount to be withdrawn
    function withdraw (address _tokenAddress, uint _amount) public {
        // first check that given address is an ERC20 one.
        IERC20 tokenContract = IERC20(_tokenAddress);
       
        OwnedToken ownedToken = OwnedToken({tokenOwner: msg.sender, tokenAddress: _tokenAddress});

        // require = check requested amount is available, not higher than what has been staked
        require(ERC20map[ownedToken] > 0 && ERC20Tokens[ERC20map[ownedToken]-1].totalAmount >= _amount, "Not enough staked tokens.");
        // TODO require = check that msg.sender should not be the owner / address 0
      
        TokenInfo storage tokenInfo = ERC20Tokens[ERC20map[ownedToken]-1];
        // calculate reward based on previous date and update it 
        tokenInfo.totalReward.add(calculateReward (tokenInfo));
        // update totalAmount with previous totalAmount - _amount
        tokenInfo.totalAmount.sub(_amount);
        // update lastReferenceDate
        tokenInfo.lastReferenceDate = block.timestamp;
        
        // transfer amount back
        tokenContract.transfer(msg.sender, _amount);
    }
}