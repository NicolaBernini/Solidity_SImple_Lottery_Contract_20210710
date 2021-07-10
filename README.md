
# Solidity_Simple_Lottery_Contract_20210710

Simple Lottery Contract in Solidity

# Description 

It is possible to simply run it in Remix: just copy paste the [Lottery Token Smart Contract](contracts/Lottery.sol) source code and run it 

It works both with ERC20 and ETH and `owner` can change it anytime just by changing the value of `token` as 

- if `token != address(0)` then it is assumed it points to an ERC20 token 

- if `token == address(0)` then ETH is used 



A simple [ERC20 Token Contract](contracts/SimpleToken.sol) is also provided 

The Randomness is simulated by having an [Oracle for Randomness Smart Conatrct](contracts/Oracle_Randomness.sol) and the related [Interface](contracts/IOracle_Randomness.sol) as a placeholder for something like Chainlink 



# Status 

Still under development 

Next steps 

- [ ] Change the payment scheme: from `transfer()` based (bad for many reasons: it can fail on the receiver side blocking the loop, gas is paid only by caller which does not make sense) to `claim()` 

- [ ] Move to Hardhat and add Unit Tests 



