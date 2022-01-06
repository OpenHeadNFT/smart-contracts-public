// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenHeadTreasury is Ownable {
  uint8 constant public MIN_WEEKLY_SHARE = 10;
  uint8 constant public MIN_MONTHLY_SHARE = 50;

  address payable immutable public weeklyRaffles;
  address payable immutable public monthlyRaffles;
  address payable public teamAddr;

  uint8 public weeklyShare;
  uint8 public monthlyShare;

  constructor(address payable _weeklyRaffles, address payable _monthlyRaffles, address payable _teamAddr) {
    weeklyRaffles = _weeklyRaffles;
    monthlyRaffles = _monthlyRaffles;
    teamAddr = _teamAddr;

    weeklyShare = MIN_WEEKLY_SHARE;
    monthlyShare = MIN_MONTHLY_SHARE;
  }

  function setWeeklyShare(uint8 percentage) external onlyOwner {
    require(percentage >= MIN_WEEKLY_SHARE, "Share cant be lower than minimum");
    require((percentage + monthlyShare) <= 100, "Total share can't be higher than 100%");

    weeklyShare = percentage;
  }

  function setMonthlyShare(uint8 percentage) external onlyOwner {
    require(percentage >= MIN_MONTHLY_SHARE, "Share cant be lower than minimum");
    require((percentage + weeklyShare) <= 100, "Total share can't be higher than 100%");

    monthlyShare = percentage;
  }

  function setTeamAddress(address payable _teamAddr) external onlyOwner {
    teamAddr = _teamAddr;
  }

  receive() external payable {
    uint balance = msg.value;
    uint monthly = balance * monthlyShare / 100;
    uint weekly = balance * weeklyShare / 100;
    uint rest = balance - monthly - weekly;

    (bool monthlySuccess, ) = monthlyRaffles.call{value: monthly}("");
    require(monthlySuccess, "Transfer failed.");

    (bool weeklySuccess, ) = weeklyRaffles.call{value: weekly}("");
    require(weeklySuccess, "Transfer failed.");

    (bool teamSuccess, ) = teamAddr.call{value: rest}("");
    require(teamSuccess, "Transfer failed.");
  }
}