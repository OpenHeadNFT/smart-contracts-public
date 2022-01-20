// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import './VRFConsumerBase.sol';

contract WeeklyRaffle is VRFConsumerBase {
    enum RaffleState { FUNDING, FUND_OVER, CALCULATING_WINNER, CLOSED }
    bytes32 immutable private keyHash;
    uint256 immutable private fee;

    IERC721Enumerable immutable public tokenAPI;
    address public manager;
    uint public endsOn;
    uint public nextStepOn;
    bool isUninitializable;

    RaffleState public state;
    address payable public winner;

    constructor(IERC721Enumerable _tokenAddr, bytes32 _keyHash, uint _fee) {
        tokenAPI = _tokenAddr;
        keyHash = _keyHash;
        fee = _fee;
        isUninitializable = true;
    }

    function initialize(address _manager, uint _stopFundingOn, uint _endsOn, address _vrfCoordinator, address link) external {
        require(!isUninitializable, "Contract is not initializable");

        super.initialize(_vrfCoordinator, link);

        isUninitializable = true;
        manager = _manager;
        nextStepOn = _stopFundingOn;
        endsOn = _endsOn;
    }

    function requestRandom() private {
        if (LINK.balanceOf(address(this)) < fee) {
            LINK.transferFrom(manager, address(this), fee);
        }

        requestRandomness(keyHash, fee);
    }

    function doIRaffleToday() external {
        require(block.timestamp >= nextStepOn, "Cant try to raffle yet");
        require(state == RaffleState.FUNDING, "Invalid raffle state");

        if (block.timestamp >= endsOn) {
            state = RaffleState.FUND_OVER;
        } else {
            requestRandom();
            nextStepOn = block.timestamp + 1 days;
        }

    }

    function triggerCalculateWinner() external {
        require(state == RaffleState.FUND_OVER, "Invalid raffle state");

        state = RaffleState.CALCULATING_WINNER;
        requestRandom();
    }

    function sendFundsBackToManager() external {
      require(state == RaffleState.CLOSED, "Invalid state");
      require(block.timestamp >= nextStepOn, "Cant send funds back to manager yet");

      payable(manager).transfer(address(this).balance);
    }

    function sendFundsToWinner() external {
      require(state == RaffleState.CLOSED, "Invalid state");
      require(winner != address(0), "Invalid winner address");

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
            LINK.transfer(manager, LINK.balanceOf(address(this)));
        }
    }

    receive() external payable {
        require(state == RaffleState.FUNDING, "Invalid state");
    }
}