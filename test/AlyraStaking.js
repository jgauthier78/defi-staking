const ERC20TokenAT1 = artifacts.require("./ERC20TokenAT1.sol");
const ERC20TokenAT2 = artifacts.require("./ERC20TokenAT2.sol");
const AlyraStaking = artifacts.require("./AlyraStaking.sol");
const { time } = require('@openzeppelin/test-helpers');
const truffleAssert = require('truffle-assertions');

contract("AlyraStaking", accounts => {
  const tokensOwner = accounts[1];
  const contractOwner = accounts[3]; // 0xDDd3D3c39fCE44C3e25968B49Fa18ecEb7BDd52D in Ganache
  const initialAmountAT1 = 1000000000000000;
  const transferedAmountAT1 = 100000000000000;
  const initialAmountAT2 = 2000000000000000;
  const transferedAmountAT2 = 200000000000000;
  const STAKING_RATE = 6;
  
  beforeEach(async function () {
    this.ERC20TokenAT1Instance = await ERC20TokenAT1.deployed();
    await this.ERC20TokenAT1Instance.transfer(tokensOwner, transferedAmountAT1, { from: contractOwner });
    this.ERC20TokenAT2Instance = await ERC20TokenAT2.deployed();
    await this.ERC20TokenAT2Instance.transfer(tokensOwner, transferedAmountAT2, { from: contractOwner });
    this.AlyraStakingInstance = await AlyraStaking.deployed();
  });
  
  it("...check AT1 balances", async function () {
    // Get balance of AT1 for contractOwner
    const balanceOfContractOwnerAT1 = await this.ERC20TokenAT1Instance.balanceOf(contractOwner, { from: contractOwner });
    let diffAmount = initialAmountAT1 - transferedAmountAT1;
    assert.equal(balanceOfContractOwnerAT1, diffAmount, "contractOwner AT1 balance should be " + diffAmount + " and got " + balanceOfContractOwnerAT1);
    
    // Get balance of AT1 for tokensOwner after transfer
    const balanceOfTokensOwnerAT1 = await this.ERC20TokenAT1Instance.balanceOf(tokensOwner, { from: contractOwner });
    assert.equal(balanceOfTokensOwnerAT1, transferedAmountAT1, "tokensOwner AT1 balance should be " + transferedAmountAT1 + " and got " + balanceOfTokensOwnerAT1);

  });
  
  it("...should reject stake if amount = 0", async function () {
    await truffleAssert.reverts(this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, 0, { from: tokensOwner }), "You cannot stake 0 token");
  });

  it("...should reject stake if amount not approved before", async function () {
    await truffleAssert.reverts(this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, 600, { from: tokensOwner }), "ERC20: transfer amount exceeds allowance");
  });

  it("...total staked amount should be 1000", async function () {
    const amount1 = 600;
    const amount2 = 400;
    let totalAmount = amount1 + amount2;
    
    // first approve amount to AlyraStaking contract address first
    await this.ERC20TokenAT1Instance.approve(this.AlyraStakingInstance.address, totalAmount, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken first with 600
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, amount1, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken second time with 400
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, amount2, { from: tokensOwner });
    // total staked amount should be equal to 1000
    const tokenStakedAmount = await this.AlyraStakingInstance.getTokenStakedAmount(this.ERC20TokenAT1Instance.address, { from: tokensOwner });
    assert.equal(tokenStakedAmount, totalAmount, "Total staked AT1 should be " + totalAmount + " and is " + tokenStakedAmount);
  });
});
