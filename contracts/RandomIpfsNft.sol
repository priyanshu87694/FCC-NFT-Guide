// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NeedMoreETH ();
error RandomIpfsNft__TransferFailed ();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {

    // Type Declaration
    enum Breed {PUG, SHIBA_INU, ST_BERNARD}

    // Events
    event NftRequested (uint256 indexed requestId, address requester);
    event NftMinted (Breed dogBreed, address minter);

    // ChainLink variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Helper Variables
    mapping (uint256 => address) public s_requestIdToOwner;

    // NFT varriables
    uint256 private s_tokenCounter;
    string[] internal s_dogTokenUris;
    uint256 internal i_mintFee;

    constructor (
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        string[3] memory dogTokenUris,
        uint256 mintFee
    ) VRFConsumerBaseV2 (vrfCoordinatorV2) ERC721 ("RandomIpfsNft", "RIN") {
        i_vrfCoordinatorV2 = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_dogTokenUris = dogTokenUris;
        i_mintFee = mintFee;
    }

    function requestNft () public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreETH();
        }
        requestId = i_vrfCoordinatorV2.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToOwner[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords (uint256 requestId, uint256[] memory randomWords) internal override {
        //
        address owner = s_requestIdToOwner[requestId];
        uint256 newTokenId = s_tokenCounter;
        uint256 moddedRng = randomWords[0] % 100;
        Breed dogBreed = getBreedFromModedRng(moddedRng);
        _safeMint(owner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(dogBreed)]);
        // s_tokenCounter += 1;
        emit NftMinted(dogBreed, owner);
    }

    function withdraw () public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

    function getBreedFromModedRng (uint256 moddedRng) public pure returns (Breed) {
        uint256 cummalativeSum = 0;
        uint8[3] memory chanceArray = getChanceArray();
        for (uint256 i=0; i<chanceArray.length; i++) {
            if (moddedRng >= cummalativeSum && moddedRng < cummalativeSum + chanceArray[i]) {
                return Breed(i);
            }
            cummalativeSum += chanceArray[i];
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

    function getChanceArray () public pure returns (uint8[3] memory) {
        return [10, 30, 100];
    }

    function getMintFee () public view returns (uint256) {
        return i_mintFee;
    }

    function getTokenUris (uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getTokenCounter () public view returns (uint256) {
        return s_tokenCounter;
    }

}