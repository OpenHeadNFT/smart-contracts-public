// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OpenHeadToken is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant PUBLIC_TOKENS = 9750;
  uint256 public constant GIFT_TOKENS = 250;
  uint256 public constant MAX_TOKENS = 10000;
  uint256 public constant PRICE = 0.07 ether;
  uint256 public constant TO_RAFFLE = 10256410256410256 wei;
  uint256 public constant MAX_PER_MINT = 5;
  uint256 public constant PRESALE_LIMIT = 2;

  address payable public immutable teamAddr;
  address payable public immutable initialRaffle;
  string public provenance;
  string public tokenBaseURI;
  bytes32 public merkleRoot;

  bool public saleLive;
  bool public presaleLive;
  mapping(address => uint256) public presalePurchases;

  bool public revealed;
  uint256 public startingIndex;
  uint256 public startingIndexBlock;
  uint256 public giftedAmount;
  uint256 public publicAmount;


  constructor(address _teamAddr, address _initialRaffle, string memory _tokenBaseURI, string memory _provenance, bytes32 _merkleRoot) ERC721("Open Head NFT", "OH") {
    teamAddr = payable(_teamAddr);
    initialRaffle = payable(_initialRaffle);
    tokenBaseURI = _tokenBaseURI;
    provenance = _provenance;
    merkleRoot = _merkleRoot;
  }

  function allPublicMinted() view public returns (bool) {
    return publicAmount == PUBLIC_TOKENS;
  }

  function isWhitelisted(address account, bytes32[] calldata merkleProof) public view returns(bool) {
    bytes32 node = keccak256(abi.encodePacked(account));
    return MerkleProof.verify(merkleProof, merkleRoot, node);
  }

  function togglePresaleStatus() external onlyOwner {
    presaleLive = !presaleLive;
  }

  function toggleSaleStatus() external onlyOwner {
    saleLive = !saleLive;
  }

  function setTokenBaseURI(string calldata URI) external onlyOwner {
    tokenBaseURI = URI;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function reveal() external onlyOwner {
    require(!revealed, "Already revealed!");
    revealed = true;
  }

  function setStartingIndex() public {
    require(startingIndex == 0, "Starting index is already set");
    require(startingIndexBlock != 0, "Starting index block must be set");

    startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKENS;
    if (startingIndex == 0) {
      startingIndex = 1;
    }
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Unexistent token");

    string memory sequenceId;

    if (startingIndex > 0) {
      sequenceId = ((tokenId + startingIndex) % MAX_TOKENS).toString();
    } else {
      sequenceId = "-1";
    }

    return string(abi.encodePacked(tokenBaseURI, sequenceId));
  }

  function mintHeads(uint amount) external payable {
    require(saleLive, "Sale is not active");
    require(totalSupply() < MAX_TOKENS, "Sold out");
    require(publicAmount + amount <= PUBLIC_TOKENS, "All public tokens sold out");
    require(amount > 0 && amount <= MAX_PER_MINT, "Invalid amount");
    require(PRICE * amount <= msg.value, "Insufficient ETH");

    uint toTransfer = TO_RAFFLE * amount;
    initialRaffle.transfer(toTransfer);
    teamAddr.transfer(msg.value - toTransfer);

    for(uint i = 0; i < amount; i++) {
      publicAmount++;
      _safeMint(msg.sender, totalSupply() + 1);
    }

    if (startingIndexBlock == 0 && (allPublicMinted() || revealed)) {
      startingIndexBlock = block.number;
    }
  }

  function mintPresaleHeads(uint amount, bytes32[] calldata proof) external payable {
    require(presaleLive, "Presale is not active");
    require(isWhitelisted(msg.sender, proof) == true, "Not in the whitelist");
    require(totalSupply() < MAX_TOKENS, "Sold out");
    require(publicAmount + amount <= PUBLIC_TOKENS, "All public tokens sold out");
    require(amount > 0 && amount <= PRESALE_LIMIT, "Invalid amount");
    require(presalePurchases[msg.sender] + amount <= PRESALE_LIMIT, "Exceeded presale limit");
    require(PRICE * amount <= msg.value, "Insufficient ETH");

    uint toTransfer = TO_RAFFLE * amount;
    initialRaffle.transfer(toTransfer);
    teamAddr.transfer(msg.value - toTransfer);

    for(uint i = 0; i < amount; i++) {
      publicAmount++;
      presalePurchases[msg.sender]++;
      _safeMint(msg.sender, totalSupply() + 1);
    }
  }

  function gift(address[] calldata receivers) external onlyOwner {
    require(totalSupply() < MAX_TOKENS, "Sold out");
    require(giftedAmount + receivers.length <= GIFT_TOKENS, "Run out of gift tokens");

    for (uint256 i = 0; i < receivers.length; i++) {
      giftedAmount++;
      _safeMint(receivers[i], totalSupply() + 1);
    }
  }
}