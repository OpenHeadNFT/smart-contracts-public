// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpenHeadToken {
        function totalSupply() external view returns (uint256);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function allPublicMinted() pure external returns (bool);
}
