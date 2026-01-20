//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {PSLTeamsBidding} from "../src/PSLTeamsBidding.sol";
import {PSLTeams} from "../src/PSLTeams.sol";
import {MockPKR} from "./mocks/MockPKR.sol";

contract PSLTeamsBiddingTest is Test {
    PSLTeamsBidding pslTeamsBidding;
    PSLTeams pslTeams;
    MockPKR pkr;

    address public constant OWNER = address(0x01);
    address public constant BIDDER_1 = address(0x02);
    address public constant BIDDER_2 = address(0x03);

    uint256 public constant TOKEN_ID = 0;
    uint256 public constant BASE_PRICE = 1_000_000_000 * 1e18; 

    function setUp() public {
        vm.startPrank(OWNER);
        
        pkr = new MockPKR();
        pslTeams = new PSLTeams();
        pslTeamsBidding = new PSLTeamsBidding(address(pslTeams), address(pkr));

        pkr.mint(BIDDER_1, 5_000_000_000 * 1e18);
        pkr.mint(BIDDER_2, 5_000_000_000 * 1e18);

        vm.stopPrank();

        vm.prank(BIDDER_1);
        pkr.approve(address(pslTeamsBidding), type(uint256).max);

        vm.prank(BIDDER_2);
        pkr.approve(address(pslTeamsBidding), type(uint256).max);
    }

    function _mintAndApprove() internal {
        vm.startPrank(OWNER);
        pslTeams.mintPSLTeam("ipfs://metadata");
        pslTeams.approve(address(pslTeamsBidding), TOKEN_ID);
        vm.stopPrank();
    }

    function test_Sanity_ListTeam() public {
        _mintAndApprove();

        vm.startPrank(OWNER);
        pslTeamsBidding.listTeam(TOKEN_ID, BASE_PRICE);
        vm.stopPrank();

        console2.log("CONTRACT OWNER:", address(pslTeamsBidding));
        console2.log("NFT Owner after listing:", pslTeams.ownerOf(TOKEN_ID));

        // Check 1: Does the contract own the NFT now?
        assertEq(pslTeams.ownerOf(TOKEN_ID), address(pslTeamsBidding));
        
        // Check 2: Is the struct updated?
        (uint256 price, , , , bool listed) = pslTeamsBidding.listings(TOKEN_ID);

        console2.log("Listing base price:", price);
        console2.log("Is listed:", listed);

        assertTrue(listed);
        assertEq(price, BASE_PRICE);
    }

    function test_Sanity_PlaceBid() public {
        // 1. Setup
        _mintAndApprove();
        vm.prank(OWNER);
        pslTeamsBidding.listTeam(TOKEN_ID, BASE_PRICE);

        console2.log("Bidder 1 balance before bid:", pkr.balanceOf(BIDDER_1));

        // 2. Bidder 1 Places Bid
        vm.prank(BIDDER_1);
        pslTeamsBidding.placeBid(TOKEN_ID, BASE_PRICE); // Bid exactly base price

        console2.log("Bidder 1 balance after bid:", pkr.balanceOf(BIDDER_1));

        // Check 1: Did the contract receive the money?
        assertEq(pkr.balanceOf(address(pslTeamsBidding)), BASE_PRICE);
        
        console2.log("Contract balance after bid:", pkr.balanceOf(address(pslTeamsBidding)));

        // Check 2: Is the highest bidder updated?
        ( , uint256 currentBid, , address highestBidder, ) = pslTeamsBidding.listings(TOKEN_ID);
        assertEq(highestBidder, BIDDER_1);
        assertEq(currentBid, BASE_PRICE);

        console2.log("Current bid:", currentBid);
        console2.log("Highest bidder:", highestBidder);
    }

    function test_Sanity_OutbidAndRefund() public {
        // 1. Setup & First Bid
        _mintAndApprove();
        vm.prank(OWNER);
        pslTeamsBidding.listTeam(TOKEN_ID, BASE_PRICE);

        vm.prank(BIDDER_1);
        pslTeamsBidding.placeBid(TOKEN_ID, BASE_PRICE);
        
        uint256 bidder1BalanceAfterFirstBid = pkr.balanceOf(BIDDER_1);

        console2.log("Bidder 1 balance after first bid:", bidder1BalanceAfterFirstBid);

        // 2. Bidder 2 Outbids (Base Price + 1)
        uint256 newBid = BASE_PRICE + 1e18;

        console2.log("Bidder 2 bidding amount:", newBid);

        vm.prank(BIDDER_2);
        pslTeamsBidding.placeBid(TOKEN_ID, newBid);

        console2.log("Bidder 1 balance after refund:", pkr.balanceOf(BIDDER_1));

        console2.log("Contract balance after outbid:", pkr.balanceOf(address(pslTeamsBidding)));

        // Check 1: Did Bidder 1 get refunded?
        // Their balance should be back to what it was before they bid (Original Mint Amount)
        // OR: Current Balance == BalanceAfterBid + RefundedAmount
        assertEq(pkr.balanceOf(BIDDER_1), bidder1BalanceAfterFirstBid + BASE_PRICE);

        // Check 2: Does contract hold only the NEW bid amount? (Not both)
        assertEq(pkr.balanceOf(address(pslTeamsBidding)), newBid);
        
        // Check 3: Is Bidder 2 the winner?
        ( , , , address highestBidder, ) = pslTeamsBidding.listings(TOKEN_ID);
        
        console2.log("Highest bidder after outbid:", highestBidder);

        assertEq(highestBidder, BIDDER_2);
    }

    function test_Sanity_SettleAuction() public {
        // 1. Setup & Bid
        _mintAndApprove();
        vm.prank(OWNER);
        pslTeamsBidding.listTeam(TOKEN_ID, BASE_PRICE);

        vm.prank(BIDDER_1);
        pslTeamsBidding.placeBid(TOKEN_ID, BASE_PRICE);

        // 2. Fast Forward Time (Auction Duration + 1 second)
        // We read the duration from the contract to be safe
        uint256 duration = pslTeamsBidding.S_AUCTION_EXTENSION_DURATION();

        console2.log("Auction extension duration:", duration);

        vm.warp(block.timestamp + duration + 1);

        console2.log("Settling auction...");

        // 3. Settle
        pslTeamsBidding.settleAuction(TOKEN_ID);

        console2.log("NFT owner after settle:", pslTeams.ownerOf(TOKEN_ID));
        console2.log("Owner PKR balance:", pkr.balanceOf(OWNER));

        // Check 1: Does Bidder 1 own the NFT?
        assertEq(pslTeams.ownerOf(TOKEN_ID), BIDDER_1);

        // Check 2: Did the Owner get paid?
        assertEq(pkr.balanceOf(OWNER), BASE_PRICE);

        // Check 3: Is the listing closed?
        ( , , , , bool listed) = pslTeamsBidding.listings(TOKEN_ID);

        console2.log("Is listing still active?", listed);

        assertFalse(listed);
    }
}