// erc20tokenat1.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract ERC20TokenAT2 is ERC20 {
    constructor(uint256 initialSupply) public ERC20("ALYRA TEST 2", "AT2") {
        _mint(msg.sender, initialSupply);
    }
}