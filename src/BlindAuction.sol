// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

// import "lib/forge-std/src/Vm.sol";

contract BlindAuction {
    address owner;

    struct AuctionDetails {
        address auctionCreator;
        string auctionName;
        address nftContractAddr;
        uint nftID;
        uint openingTime;
        uint duration;
        address winnerAddress;
        uint highestBid;
    }

    struct Bidders {
        uint auctionId;
        address bidderAddr;
        uint bidAmount;
    }

    uint auctionID;
    uint creationCharge = 0.02 ether;

    //takes in auctionID and returns a struct of corresponding auction details.
    mapping(uint => AuctionDetails) public uniqueAuctionSummary;

    // holds an array of all created auctions.
    AuctionDetails[] public allAuctionDetails;

    // takes in auctionID and creates an array of bidders detail struct for the auctionID
    mapping(uint => Bidders[]) public uniqueAuctionPool;

    // holds an array of auction IDs
    uint[] public arrID;

    //takes in msg.sender and auctionID to give the bid amount for the auctionID
    mapping(address => mapping(uint => uint)) public userBid;

    //takes in an address and auctionID and returns a bool to confirm if msg.sender has bidded before.
    mapping(address => mapping(uint => bool)) public hasBidded;

    constructor() {
        owner = msg.sender;
    }

    function uniqueAuction(
        uint _auctionID
    ) public view returns (AuctionDetails memory details) {
        details = uniqueAuctionSummary[_auctionID];
    }

    function createAuction(
        address _nftContract,
        string memory _auctionName,
        uint _nftID
    ) public payable {
        require(msg.sender != address(0), "Unauthorized address");
        require(_nftContract != address(0), "Address Zero prohibited");
        // get the size/number of created auctions...
        uint idArrSize = arrID.length;
        for (uint i = 0; i < idArrSize; i++) {
            //loops through id array and ensure item has not been listed by checking nft and id....
            require(
                uniqueAuctionSummary[i].nftContractAddr != _nftContract &&
                    uniqueAuctionSummary[i].nftID != _nftID,
                "item has been listed"
            );
        }
        // checks for minimum auction listing price
        require(
            msg.value >= creationCharge,
            "Auction Creation charge is 0.02 ethers"
        );

        //initiializes struct uniqueAuctionSummary struct....
        AuctionDetails memory newAuction = AuctionDetails(
            msg.sender,
            _auctionName,
            _nftContract,
            _nftID,
            block.timestamp,
            100 seconds,
            0x0000000000000000000000000000000000000000,
            0
        );
        auctionID++;
        arrID.push(auctionID);
        uniqueAuctionSummary[auctionID] = newAuction;
        allAuctionDetails.push(newAuction);

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _nftID);
    }

    function BidForItem(uint _auctionId) public payable {
        require(msg.sender != owner, "Auction cannot bid for item");
        require(
            hasBidded[msg.sender][_auctionId] == false,
            "You cam't bid twice"
        );
        require(msg.value > 0, "Nothing is free");
        require(
            msg.sender != uniqueAuctionSummary[_auctionId].auctionCreator,
            "can not bid for this item!!!"
        );
        require(
            block.timestamp <=
                uniqueAuctionSummary[_auctionId].openingTime +
                    uniqueAuctionSummary[_auctionId].duration,
            "Bidding has ended!!!"
        );

        userBid[msg.sender][_auctionId] = msg.value;
        Bidders memory _bidderDetails = Bidders(
            _auctionId,
            msg.sender,
            msg.value
        );

        uniqueAuctionPool[_auctionId].push(_bidderDetails);

        if (msg.value > uniqueAuctionSummary[_auctionId].highestBid) {
            uniqueAuctionSummary[_auctionId].highestBid = (msg.value);
            uniqueAuctionSummary[_auctionId].winnerAddress = msg.sender;
        }

        // bytes32 take = keccak256(abi.encodePacked(msg.value));

        hasBidded[msg.sender][_auctionId] = true;
    }

    function declareWinner(uint _auctionID) public payable {
        require(
            uniqueAuctionSummary[_auctionID].auctionCreator == msg.sender ||
                owner == msg.sender,
            "Only auction creator or contract Owner can call this function"
        );
        require(
            block.timestamp >
                uniqueAuctionSummary[_auctionID].openingTime +
                    uniqueAuctionSummary[_auctionID].duration,
            "Bidding still in progress"
        );

        Bidders[] memory uniquePool = uniqueAuctionPool[_auctionID];
        uint uniquePoolSize = uniquePool.length;
        address _winner = uniqueAuctionSummary[_auctionID].winnerAddress;
        for (uint i = 0; i < uniquePoolSize; i++) {
            address _bidder = uniquePool[i].bidderAddr;
            if (_bidder != _winner) {
                uint amount = uniquePool[i].bidAmount;
                (bool sent, bytes memory data) = payable(address(_bidder)).call{
                    value: amount
                }("");
                require(sent, "failed to send ether");
            }
        }

        address _nftAddr = uniqueAuctionSummary[_auctionID].nftContractAddr;
        uint _nftId = uniqueAuctionSummary[_auctionID].nftID;

        IERC721(_nftAddr).transferFrom(address(this), _winner, _nftId);
    }
}
