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

    function testReateAuction() public {
        testMintNFt();
        vm.deal(auctioner1, 100 ether);
        vm.deal(auctioner2, 100 ether);
        vm.startPrank(auctioner1);
        mockNFT.approve(address(auctionF), 0);
        auctionF.createAuction{value: 0.02 ether}(address(mockNFT), "Dykes", 0);
        vm.stopPrank();

        vm.startPrank(auctioner2);
        mockNFT.approve(address(auctionF), 1);
        auctionF.createAuction{value: 0.02 ether}(address(mockNFT), "Dykes", 1);
        vm.stopPrank();
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
