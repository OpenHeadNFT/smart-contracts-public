// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DateTimeAPI {
        function getYear(uint timestamp) pure external returns (uint16);
        function getMonth(uint timestamp) pure external returns (uint8);
        function getDaysInMonth(uint8 month, uint16 year) pure external returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) pure external returns (uint timestamp);
}
