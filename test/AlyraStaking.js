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
  
  before(async function () {
    this.ERC20TokenAT1Instance = await ERC20TokenAT1.deployed();
    await this.ERC20TokenAT1Instance.transfer(tokensOwner, transferedAmountAT1, { from: contractOwner });
    this.ERC20TokenAT2Instance = await ERC20TokenAT2.deployed();
    await this.ERC20TokenAT2Instance.transfer(tokensOwner, transferedAmountAT2, { from: contractOwner });
    this.AlyraStakingInstance = await AlyraStaking.deployed();
    // directly approve transferedAmountAT2 to avoid need of calling approve on each test for AT2
    await this.ERC20TokenAT2Instance.approve(this.AlyraStakingInstance.address, transferedAmountAT2, { from: tokensOwner });
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
    const stakedAmount = 1000;
    await truffleAssert.reverts(this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, stakedAmount, { from: tokensOwner }), "ERC20: transfer amount exceeds allowance");
  });

  it("...total staked amount should be 1000", async function () {
    const stakedAmount1 = 600;
    const stakedAmount2 = 400;
    const withdrawnAmount = 1000
    let totalAmount = stakedAmount1 + stakedAmount2 - withdrawnAmount;
    
    // first approve amount to AlyraStaking contract address
    await this.ERC20TokenAT1Instance.approve(this.AlyraStakingInstance.address, stakedAmount1 + stakedAmount2, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken first with stakedAmount1
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, stakedAmount1, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken second time with stakedAmount2
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, stakedAmount2, { from: tokensOwner });
    // call AlyraStakingInstance.withdrawToken with withdrawnAmount
    await this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT1Instance.address, withdrawnAmount, { from: tokensOwner });
    // total staked amount should be equal to totalAmount
    const tokenStakedAmount = await this.AlyraStakingInstance.getTokenStakedAmount(this.ERC20TokenAT1Instance.address, { from: tokensOwner });
    assert.equal(tokenStakedAmount, totalAmount, "Total staked AT1 should be " + totalAmount + " and is " + tokenStakedAmount);
  });

  it("...should reject withdraw if requested amount is higher than staked tokens", async function () {
    const withdrawnAmountRequested = 1;
    
    await truffleAssert.reverts(this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT1Instance.address, withdrawnAmountRequested, { from: tokensOwner }), "Not enough staked tokens.");
  });

  it("...should get the correct award in AT2 token units", async function () {
    const firstStakedAmount = 1000;
    const secondStakedAmount = 1500;
    const firstWithdrawnAmount = 500;
    const secondWithdrawnAmount = 2000;
    const expectedTokenRewardAfterFirstPeriod = 60; // after 1 day, 1000 => 60
    const expectedTokenRewardAfterSecondPeriod = 360; // after 2 additional days, 2500 (1000 + 1500) => 150 per day = 300 for 2 days + 60 previous = 360
    const expectedTokenRewardAfterThirdPeriod = 720; // after 3 additional days, 2000 (2500 - 500) => 120 per day = 360 for 3 days + 360 previous = 720
    const expectedTokenRewardAfterFourthPeriod = 720; // after 1 additional day, 0 (2000 - 2000) => should remain = 720

    ///////////////////////////
    // Begin first assertion //
    ///////////////////////////
    // call AlyraStakingInstance.stakeToken with firstStakedAmount
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT2Instance.address, firstStakedAmount, { from: tokensOwner });
    // increase time for one day
    await time.increase(time.duration.days(1));;
    // get getTokenReward
    let tokenRewardFromContract = await this.AlyraStakingInstance.getTokenReward(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    // First assertion
    assert.equal(tokenRewardFromContract, expectedTokenRewardAfterFirstPeriod, "Reward in AT2 token after 1 day should be " + expectedTokenRewardAfterFirstPeriod + " and is " + tokenRewardFromContract);
    ///////////////////////////
    // End first assertion   //
    ///////////////////////////

    ////////////////////////////
    // Begin second assertion //
    ////////////////////////////
    // call AlyraStakingInstance.stakeToken with secondStakedAmount
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT2Instance.address, secondStakedAmount, { from: tokensOwner });
    // increase time for two days
    await time.increase(time.duration.days(2));;
    // get getTokenReward
    tokenRewardFromContract = await this.AlyraStakingInstance.getTokenReward(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    // Second assertion
    assert.equal(tokenRewardFromContract, expectedTokenRewardAfterSecondPeriod, "Reward in AT2 token after 2 days should be " + expectedTokenRewardAfterSecondPeriod + " and is " + tokenRewardFromContract);
    ////////////////////////////
    // End second assertion   //
    ////////////////////////////

    ///////////////////////////
    // Begin third assertion //
    ///////////////////////////
    // call AlyraStakingInstance.withdrawToken with firstWithdrawnAmount
    await this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT2Instance.address, firstWithdrawnAmount, { from: tokensOwner });
    // increase time for three days
    await time.increase(time.duration.days(3));;
    // get getTokenReward
    tokenRewardFromContract = await this.AlyraStakingInstance.getTokenReward(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    // Third assertion
    assert.equal(tokenRewardFromContract, expectedTokenRewardAfterThirdPeriod, "Reward in AT2 token after 3 days should be " + expectedTokenRewardAfterThirdPeriod + " and is " + tokenRewardFromContract);
    ///////////////////////////
    // End third assertion   //
    ///////////////////////////

    ////////////////////////////
    // Begin fourth assertion //
    ////////////////////////////
    // call AlyraStakingInstance.withdrawToken with secondWithdrawnAmount
    await this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT2Instance.address, secondWithdrawnAmount, { from: tokensOwner });
    // increase time for one day
    await time.increase(time.duration.days(1));;
    // get getTokenReward
    tokenRewardFromContract = await this.AlyraStakingInstance.getTokenReward(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    // Second assertion
    assert.equal(tokenRewardFromContract, expectedTokenRewardAfterFourthPeriod, "Reward in AT2 token after 1 day should be " + expectedTokenRewardAfterFourthPeriod + " and is " + tokenRewardFromContract);
    
    // we can check again after n additional days, it should now remain the same reward amount
    await time.increase(time.duration.days(10));;
    // get getTokenReward
    tokenRewardFromContract = await this.AlyraStakingInstance.getTokenReward(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    // Second assertion
    assert.equal(tokenRewardFromContract, expectedTokenRewardAfterFourthPeriod, "Reward in AT2 token after 10 days should still be " + expectedTokenRewardAfterFourthPeriod + " and is " + tokenRewardFromContract);
    ////////////////////////////
    // End fourth assertion   //
    ////////////////////////////
    
  });
  
  it("...should return the correct Tokens Rewards In ETH", async function () {
    // now check All Tokens Rewards In ETH
    let expectedTokensRewardsInETH = 720 * 20; // 20 = price of AT2 token, 720 comes from previous test
    let allTokensRewardsInETH = await this.AlyraStakingInstance.getAllTokensRewardsInETH({ from: tokensOwner });
    // assert
    assert.equal(allTokensRewardsInETH, expectedTokensRewardsInETH, "All Tokens Rewards price in ETH should be " + expectedTokensRewardsInETH + " and is " + allTokensRewardsInETH);

  });
  

  it("...can stake different tokens without mixing them", async function () {
    const stakedAT1Amount1 = 600;
    const stakedAT1Amount2 = 400;
    const withdrawnAT1Amount = 300
    let totalAT1Amount = stakedAT1Amount1 + stakedAT1Amount2 - withdrawnAT1Amount;

    const stakedAT2Amount1 = 1000;
    const withdrawnAT2Amount = 900
    const stakedAT2Amount2 = 500;
    let totalAT2Amount = stakedAT2Amount1 - withdrawnAT2Amount + stakedAT2Amount2;
    
    // first approve AT1 and AT2 amounts to AlyraStaking contract address
    await this.ERC20TokenAT1Instance.approve(this.AlyraStakingInstance.address, stakedAT1Amount1 + stakedAT1Amount2, { from: tokensOwner });
    await this.ERC20TokenAT2Instance.approve(this.AlyraStakingInstance.address, stakedAT2Amount1 + stakedAT2Amount2, { from: tokensOwner });

    // we should be able to stake.withdrawn AT1 and AT2 tokens in "mix mode"
    // call AlyraStakingInstance.stakeToken first with stakedAT1Amount1
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, stakedAT1Amount1, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken second time with stakedAT1Amount2
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT1Instance.address, stakedAT1Amount2, { from: tokensOwner });
    // call AlyraStakingInstance.stakeToken first with stakedAT2Amount1
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT2Instance.address, stakedAT2Amount1, { from: tokensOwner });
    // call AlyraStakingInstance.withdrawToken with withdrawnAT1Amount
    await this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT1Instance.address, withdrawnAT1Amount, { from: tokensOwner });
    // call AlyraStakingInstance.withdrawToken with withdrawnAT2Amount
    await this.AlyraStakingInstance.withdrawToken(this.ERC20TokenAT2Instance.address, withdrawnAT2Amount, { from: tokensOwner });
    // total staked amount should be equal to totalAmount
    // call AlyraStakingInstance.stakeToken first with stakedAT2Amount2
    await this.AlyraStakingInstance.stakeToken(this.ERC20TokenAT2Instance.address, stakedAT2Amount2, { from: tokensOwner });
    
    // assert AT1 staked amount = totalAT1Amount
    const tokenStakedAT1Amount = await this.AlyraStakingInstance.getTokenStakedAmount(this.ERC20TokenAT1Instance.address, { from: tokensOwner });
    assert.equal(tokenStakedAT1Amount, totalAT1Amount, "Total staked AT1 should be " + totalAT1Amount + " and is " + tokenStakedAT1Amount);

    // assert AT2 staked amount = totalAT1Amount
    const tokenStakedAT2Amount = await this.AlyraStakingInstance.getTokenStakedAmount(this.ERC20TokenAT2Instance.address, { from: tokensOwner });
    assert.equal(tokenStakedAT2Amount, totalAT2Amount, "Total staked AT2 should be " + totalAT2Amount + " and is " + tokenStakedAT2Amount);
  });

});
