// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOpenHeadToken.sol";
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

contract InitialRaffle is Ownable, VRFConsumerBase {
    enum RaffleState { FUNDING, FUND_OVER, CALCULATING_WINNER, CLOSED, CLAIMED }
    bytes32 immutable private keyHash;
    uint256 immutable private fee;

    IOpenHeadToken public tokenAPI;
    uint public endsOn;
    uint public nextStepOn;
    uint public fallbackDate;

    RaffleState public state;
    address payable public winner;

    constructor(bytes32 _keyHash, uint _fee, address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) {
        fallbackDate = block.timestamp + 90 days;
        keyHash = _keyHash;
        fee = _fee;
    }

    function setTokenAddr(IOpenHeadToken _tokenAddr) external onlyOwner {
        require(address(tokenAPI) == address(0), "Token address is already set");
        tokenAPI = _tokenAddr;
    }

    function initiateRaffle() public {
        require(address(tokenAPI) != address(0), "Token address must be set");
        require(endsOn == 0, "Raffle already initiated");
        require(tokenAPI.allPublicMinted() || block.timestamp >= fallbackDate, "Cant initiate raffle yet");

        endsOn = block.timestamp + (block.timestamp > fallbackDate ? 0 : 7 days);
    }

    function doIRaffleToday() external {
        require(endsOn != 0, "Raffle not initiated");
        require(block.timestamp >= nextStepOn, "Cant try to raffle yet");
        require(state == RaffleState.FUNDING, "Invalid raffle state");

        if (block.timestamp >= endsOn) {
            state = RaffleState.FUND_OVER;
        } else {
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
            requestRandomness(keyHash, fee);
            nextStepOn = block.timestamp + 1 days;
        }
    }

    function triggerCalculateWinner() external {
        require(state == RaffleState.FUND_OVER, "Invalid raffle state");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        state = RaffleState.CALCULATING_WINNER;
        requestRandomness(keyHash, fee);
    }

    function findNewWinner() external {
        require(state == RaffleState.CLOSED, "Invalid raffle state");
        require(block.timestamp >= nextStepOn, "Cant calculate winner yet");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        state = RaffleState.CALCULATING_WINNER;
        requestRandomness(keyHash, fee);
    }

    function sendFundsToWinner() external {
      require(winner != address(0), "Invalid winner address");
      if (state == RaffleState.CLOSED) state = RaffleState.CLAIMED;
      require(state == RaffleState.CLAIMED, "Invalid state");

      winner.transfer(address(this).balance);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        if (state == RaffleState.FUNDING) {
            if (randomness % 7 == 0) state = RaffleState.FUND_OVER;
        } else if (state == RaffleState.CALCULATING_WINNER) {
            uint16 total = uint16(tokenAPI.totalSupply());
            uint16 idx = uint16(randomness % total) + 1;

            state = RaffleState.CLOSED;
            winner = payable(tokenAPI.ownerOf(idx));
            nextStepOn = block.timestamp + 30 days;
        }
    }

    receive() external payable {}
}