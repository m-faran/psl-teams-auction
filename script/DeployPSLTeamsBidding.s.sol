// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PSLTeamsBidding} from "../src/PSLTeamsBidding.sol";
import {PSLTeams} from "../src/PSLTeams.sol";

contract DeployPSLTeamsBidding is Script {
    PSLTeamsBidding public pslteamsbidding;
    PSLTeams public pslteams;
    
    // FIX 1: Removed quotes. This is now a valid address literal.
    address public pkrToken = 0x902767592ADB84efECD3Eb44A8D6Bd77B0632b81;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        pslteams = new PSLTeams();

        pslteamsbidding = new PSLTeamsBidding(address(pslteams), pkrToken);

        vm.stopBroadcast();

        console.log("------------------------------------------------");
        console.log("Deployment Successful");
        console.log("------------------------------------------------");
        console.log("PSL Teams NFT Address:", address(pslteams));
        console.log("PSL Bidding Address:  ", address(pslteamsbidding));
        console.log("Owner Account:        ", vm.addr(deployerPrivateKey));
        console.log("------------------------------------------------");
    }
}