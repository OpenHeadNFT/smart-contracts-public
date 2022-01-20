# Open Head NFT Smart Contracts

In this repository you will find the Open Head smart contracts. Keep in mind the code is already verified in Etherscan, so you can just browse it there. We believe GitHub is a better tool to browse the content of the contracts.

We also want you to know that these contracts have been audited by Solidity Finance before being published.
You can check the audit [here](https://solidity.finance/audits/OpenHeadNFT/).

## Open Head Token
[Etherscan](https://etherscan.io/address/0xca6788C8eFa6A1c8Bc97FA98938fa361d51eF823#code)
[Contract](smart-contracts/OpenHeadToken.sol)

Smart contract for the token itself. It's a fairly straightforward implementation of ERC721, the golden standard for non-fungible tokens.

## Initial Raffle
[Etherscan](https://etherscan.io/address/0xBF8Be372E828f6a7Cd812062B715875215180C70#code)
[Contract](smart-contracts/InitialRaffle.sol)

This contract will receive roughly 0.01 ETH each time a token is minted.
When either all public tokens (9750) are sold or 90 days since deployment (16th of April) pass, a random winner will be selected using Chainlink VRF.
Once a winner is elected, he'll have the ability to claim the funds of the contract, so he'll still receive his share if more tokens are minted.

Keep in mind you can check the current raffle pot on the Etherscan link above.

## Open Head Treasury
[Etherscan](https://etherscan.io/address/0xD28bCbabc7a17fE47D5C8d8b81F289F6fDdf1421#code)
[Contract](smart-contracts/Treasury.sol)

This is the treasury of the Open Head team. Every time it receives funds, it will:
* Send at least 50% of the funds to the Monthly Raffle Manager.
* Send at least 10% of the funds to the Weekly Raffle Manager.
* Send the rest to the Open Head team wallet.

It's important to remember that we can increase the percentage allocated to the raffles, but never decrease them under the default values (50% for monthly raffles and 10% for weekly raffles).

## Monthly Raffle
[Etherscan](https://etherscan.io/address/0x9a09cC9152baee8F22ba6F4167a6de96b3Ce4b2A#code)
[Contract](smart-contracts/MonthlyRaffle.sol)

This is the base contract for the monthly raffles. Each time a monthly raffle is launched, it will be executing the logic found here.

## Monthly Raffle Manager
[Etherscan](https://etherscan.io/address/0x671C5Bf273e772140D9533e8a31Dd085660D9694#code)
[Contract](smart-contracts/MonthlyRaffleManager.sol)

Each time this contract receives funds, it will allocate them to the next month's raffle. If no next month raffle exists,one will be created using a Minimal Proxy (EIP-1167). Monthly raffles will be randomly executed between the first and the last day of the allocated month. You can check the address of the monthly raffles using the raffles mapping, where the key is: "month-year" (eg: "1-2022").

## Weekly Raffle
[Etherscan](https://etherscan.io/address/0xD1bc9c19C08b323A2587fC4644915166eAf4bC06#code)
[Contract](smart-contracts/WeeklyRaffle.sol)

This is the base contract for the weekly raffles. Each time a weekly raffle is launched, it will be executing the logic found here.

## Weekly Raffle Manager
[Etherscan](https://etherscan.io/address/0xf4E89557c4FcdBD016255729c95185188eFAFcD2#code)
[Contract](smart-contracts/WeeklyRaffleManager.sol)

Each time this contract receives funds, it will allocate 25% of the received value to each raffle scheduled to happen the following month. If no next month raffles exists, four will be created using a Minimal Proxy (EIP-1167):

* The first one will take place between the 1st and the 7th.
* The second one will take place between the 8th and the 14th.
* The third one will take place between the 15th and the 21st.
* The fourth one will take place between the 22nd and the 28th.

You can check the address of the weekly raffles using the raffles mapping, where the key is "month-year" (eg: "1-2022") and the index is a number between 0 and 3.