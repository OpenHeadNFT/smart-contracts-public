// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTimeAPI.sol";
import "./MonthlyRaffle.sol";

contract MonthlyRaffleManager {
  mapping(string => address payable) public raffles;
  address immutable public baseRaffle;
  DateTimeAPI immutable public dateTime;
  address immutable public vrfCoordinator;
  IERC20 immutable public link;

  constructor(address _baseRaffle, DateTimeAPI _datetime, address _vrfCoordinator, IERC20 _link) {
    baseRaffle = _baseRaffle;
    dateTime = _datetime;
    vrfCoordinator = _vrfCoordinator;
    link = _link;
  }

  receive() external payable {
    uint8 month = dateTime.getMonth(block.timestamp);
    uint16 year = dateTime.getYear(block.timestamp);
    string memory key = string(abi.encodePacked(Strings.toString(month), '-', Strings.toString(year)));

    if (raffles[key] == address(0)) {
      address payable raffle = payable(Clones.clone(baseRaffle));
      uint stopFundingOn = dateTime.toTimestamp(year, month + 1, 1);
      uint endOn = dateTime.toTimestamp(year, month + 1, dateTime.getDaysInMonth(month, year));

      link.approve(raffle, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
      MonthlyRaffle(raffle).initialize(address(this), stopFundingOn, endOn, vrfCoordinator, address(link));
      raffles[key] = raffle;
    }

    (bool success, ) = raffles[key].call{value: msg.value}("");
    require(success, "Transfer failed.");
  }


}