// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BlindAuction.sol";
import "../src/MockToke.sol";

contract Auctionn is Test {
    BlindAuction auctionF;
    MockToke mockNFT;

    address owner = mkaddr("owner");

    address auctioner1 = mkaddr("auctioner1");
    address auctioner2 = mkaddr("auctioner2");

    address bidder1 = mkaddr("bidder1");
    address bidder2 = mkaddr("bidder2");
    address bidder3 = mkaddr("bidder3");

    function setUp() public {
        vm.startPrank(owner);
        auctionF = new BlindAuction();
        mockNFT = new MockToke();
        vm.stopPrank();
    }

    function testMintNFt() public {
        vm.startPrank(owner);
        mockNFT.safeMint(auctioner1, "blindSpot");
        mockNFT.safeMint(auctioner2, "Legacy");
        mockNFT.balanceOf(auctioner1);
        mockNFT.balanceOf(auctioner2);
        vm.stopPrank();
    }

    function testCreateAuction() public {
        testMintNFt();
        vm.deal(auctioner1, 100 ether);
        vm.deal(auctioner2, 100 ether);
        vm.startPrank(auctioner1);
        mockNFT.approve(address(auctionF), 0);
        auctionF.createAuction{value: 0.02 ether}(
            address(mockNFT),
            "Aitch5",
            0
        );
        vm.stopPrank();

        vm.startPrank(auctioner2);
        mockNFT.approve(address(auctionF), 1);
        auctionF.createAuction{value: 0.02 ether}(
            address(mockNFT),
            "CarlsPro",
            1
        );
        vm.stopPrank();
    }

    function testPlaceBid() public {
        testCreateAuction();
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        vm.deal(bidder3, 100 ether);

        vm.startPrank(bidder1);
        auctionF.BidForItem{value: 2 ether}(1);
        auctionF.BidForItem{value: 2 ether}(2);
        vm.stopPrank();

        vm.startPrank(bidder2);
        auctionF.BidForItem{value: 5 ether}(1);
        auctionF.BidForItem{value: 6 ether}(2);
        vm.stopPrank();

        vm.startPrank(bidder3);
        auctionF.BidForItem{value: 4 ether}(1);
        auctionF.BidForItem{value: 9 ether}(2);
        vm.stopPrank();

        // vm.startPrank(bidder3);
        // auctionF.BidForItem{value: 10 ether}(1);
        // auctionF.BidForItem{value: 20 ether}(2);
        // vm.stopPrank();
    }

    function testWinner() public {
        testPlaceBid();
        vm.warp(3 minutes);
        vm.startPrank(owner);
        auctionF.declareWinner(1);
        auctionF.declareWinner(2);
        vm.stopPrank();
        auctionF.uniqueAuction(1);
        auctionF.uniqueAuction(2);
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
