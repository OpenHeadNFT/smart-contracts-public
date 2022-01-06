// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DateTimeAPI {
        function isLeapYear(uint16 year) pure external returns (bool);
        function getYear(uint timestamp) pure external returns (uint16);
        function getMonth(uint timestamp) pure external returns (uint8);
        function getDaysInMonth(uint8 month, uint16 year) pure external returns (uint8);
        function getDay(uint timestamp) pure external returns (uint8);
        function getHour(uint timestamp) pure external returns (uint8);
        function getMinute(uint timestamp) pure external returns (uint8);
        function getSecond(uint timestamp) pure external returns (uint8);
        function getWeekday(uint timestamp) pure external returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) pure external returns (uint timestamp);
}
