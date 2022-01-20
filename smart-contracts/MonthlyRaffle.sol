// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import './VRFConsumerBase.sol';

contract MonthlyRaffle is VRFConsumerBase {
    enum RaffleState { FUNDING, EXCLUDING, CALCULATING_WINNER, CLOSED }
    uint constant public MAX_EXCLUDED = 1000;
    bytes32 immutable private keyHash;
    uint256 immutable private fee;

    IERC721Enumerable immutable public tokenAPI;
    address immutable public owner;
    address public manager;
    uint public endsOn;
    uint public nextStepOn;
    bool isUninitializable;

    mapping(uint16 => bool) public excluded;
    uint public excludedAmount;
    RaffleState public state;
    address payable public winner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by owner!");
        _;
    }

    constructor(IERC721Enumerable _tokenAddr, bytes32 _keyHash, uint _fee) {
        tokenAPI = _tokenAddr;
        keyHash = _keyHash;
        fee = _fee;
        owner = msg.sender;
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
            state = RaffleState.EXCLUDING;
        } else {
            requestRandom();
        }

        nextStepOn = block.timestamp + 1 days;
    }

    function triggerCalculateWinner() external {
        require(block.timestamp >= nextStepOn, "Cant calculate winner yet");
        require(state == RaffleState.EXCLUDING, "Invalid raffle state");

        state = RaffleState.CALCULATING_WINNER;
        requestRandom();
    }

    function addExcluded(uint16[] calldata toExclude) external onlyOwner {
        require(state == RaffleState.EXCLUDING, "Invalid raffle state");
        require(excludedAmount + toExclude.length <= MAX_EXCLUDED, "Cant exclude that many tokens");

        for(uint i = 0; i < toExclude.length; i++) {
            uint16 entry = toExclude[i];
            require(!excluded[entry], "Already excluded");
            require(entry > 0 && entry <= tokenAPI.totalSupply(), "Invalid excluded entry");

            excluded[entry] = true;
            ++excludedAmount;
        }
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
            if (randomness % 30 == 0) state = RaffleState.EXCLUDING;
        } else if (state == RaffleState.CALCULATING_WINNER) {
            uint16 total = uint16(tokenAPI.totalSupply());
            uint16 idx = uint16(randomness % total) + 1;
            bool op = (randomness % 2) == 1;

            while(excluded[idx]) {
                if (op) idx = (idx % total) + 1;
                else idx = idx == 1 ? total : idx - 1;
            }

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