// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTimeAPI.sol";
import "./WeeklyRaffle.sol";

contract WeeklyRaffleManager {
  mapping(string => address payable[4]) public raffles;
  address immutable public baseRaffle;
  DateTimeAPI immutable public dateTime;
  address immutable public vrfCoordinator;
  IERC20 immutable public link;

  constructor(address _baseRaffle, DateTimeAPI _datetime, address _vrfCoordinator, IERC20 _link) {
    baseRaffle = _baseRaffle;
    dateTime = _datetime;
    link = _link;
    vrfCoordinator = _vrfCoordinator;
  }

  receive() external payable {
    uint8 month = dateTime.getMonth(block.timestamp);
    uint16 year = dateTime.getYear(block.timestamp);
    string memory key = string(abi.encodePacked(Strings.toString(month), '-', Strings.toString(year)));

    for (uint8 i = 0; i < 4; ++i) {
        if (raffles[key][i] == address(0)) {
            address payable raffle = payable(Clones.clone(baseRaffle));
            uint stopFundingOn = dateTime.toTimestamp(year, month + 1, i * 7 + 1);
            uint endOn = stopFundingOn + 7 days;

            link.approve(raffle, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            WeeklyRaffle(raffle).initialize(address(this), stopFundingOn, endOn, vrfCoordinator, address(link));
            raffles[key][i] = raffle;
        }

        (bool success, ) = raffles[key][i].call{value: msg.value / 4}("");
        require(success, "Transfer failed.");
    }
  }
}