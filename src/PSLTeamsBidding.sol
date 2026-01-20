// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PSLTeams} from "./PSLTeams.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PSLTeamsBidding is Ownable(msg.sender) {
    PSLTeams public pslteams;
    IERC20 public immutable i_paymentTokenPKR;

    event TeamListed(uint256 tokenId, uint256 basePrice);
    event TeamUnListed(uint256 tokenId);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionExtended(uint256 tokenId, uint256 newDeadline);
    event AuctionSettled(uint256 tokenId, address winner, uint256 price);

    struct Listing {
        uint256 basePrice;
        uint256 currentBidPrice;
        uint256 auctionEnd;
        address highestBidder;
        bool listed;
    }

    uint256 public constant S_AUCTION_EXTENSION_DURATION = 5 minutes;
    uint256 public constant S_BASE_PRICE = 1_000_000_000 * 10 ** 18;

    mapping(uint256 => Listing) public listings;

    modifier isListed(uint256 tokenId) {
        require(listings[tokenId].listed, "TEAM NOT LISTED");
        _;
    }

    constructor(address _pslteams, address _paymentTokenPKR) {
        pslteams = PSLTeams(_pslteams);
        i_paymentTokenPKR = IERC20(_paymentTokenPKR);
    }

    function listTeam(uint256 tokenId, uint256 _basePrice) public onlyOwner {
        require(_basePrice == S_BASE_PRICE, "BASE PRICE MUST BE 100CR");

        pslteams.transferFrom(msg.sender, address(this), tokenId);

        listings[tokenId] = Listing({
            basePrice: _basePrice,
            currentBidPrice: 0,
            auctionEnd: block.timestamp + S_AUCTION_EXTENSION_DURATION,
            highestBidder: address(0),
            listed: true
        });

        emit TeamListed(tokenId, _basePrice);
    }

    function unlistTeam(uint256 tokenId) public isListed(tokenId) onlyOwner {
        require(listings[tokenId].currentBidPrice == 0, "CANNOT UNLIST THIS TEAM, BIDS EXIST");

        listings[tokenId].listed = false;

        pslteams.transferFrom(address(this), msg.sender, tokenId);

        emit TeamUnListed(tokenId);
    }

    function placeBid(uint256 tokenId, uint256 amount) external isListed(tokenId) {
        Listing storage listing = listings[tokenId];
        require(block.timestamp < listing.auctionEnd, "AUCTION IS OVER");

        address previousBidder = listing.highestBidder;
        uint256 previousBidderAmount = listing.currentBidPrice;

        //First Bid
        if (previousBidderAmount == 0) {
            require(amount >= listing.basePrice, "BID MUST MEET BASE PRICE");
        } else {
            require(amount > previousBidderAmount, "BID MUST BE HIGHER THAN CURRENT");
        }

        bool success = i_paymentTokenPKR.transferFrom(msg.sender, address(this), amount);
        require(success, "TRANSFER FROM FAILED");

        if (previousBidder != address(0)) {
            bool refundSuccess = i_paymentTokenPKR.transfer(previousBidder, previousBidderAmount);
            require(refundSuccess, "REFUND FAILED");
        }

        listing.currentBidPrice = amount;
        listing.highestBidder = msg.sender;
        listing.auctionEnd = listing.auctionEnd + S_AUCTION_EXTENSION_DURATION;

        emit BidPlaced(tokenId, msg.sender, amount);
        emit AuctionExtended(tokenId, listing.auctionEnd);
    }

    function settleAuction(uint256 tokenId) external isListed(tokenId) {
        Listing storage listing = listings[tokenId];

        require(listing.auctionEnd >= block.timestamp, "AUCTION IS NOT OVER");
        require(listing.currentBidPrice > 0, "NO BIDS PLACED");

        _executeSale(tokenId);
    }

    function _executeSale(uint256 tokenId) internal {
        Listing storage listing = listings[tokenId];

        listing.listed = false;

        pslteams.transferFrom(address(this), listing.highestBidder, tokenId);

        bool paySeller = i_paymentTokenPKR.transfer(owner(), listing.currentBidPrice);
        require(paySeller, "PAYMENT TO SELLER FAILED");

        emit AuctionSettled(tokenId, listing.highestBidder, listing.currentBidPrice);
    }
}
