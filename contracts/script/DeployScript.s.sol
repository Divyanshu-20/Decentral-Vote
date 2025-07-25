// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../src/PollManager.sol";
import "../src/VotingToken.sol";
import "forge-std/Script.sol";
import "./HelperConfig.s.sol";

contract DeployScript is Script {
    HelperConfig public helperConfig;

    function run() external {
        helperConfig = new HelperConfig();
        // Get the network configuration
        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();
        
        // Start broadcasting with the private key
        vm.startBroadcast(activeNetworkConfig.privateKey);    
        // Deploy the contracts
        deployContracts();
        vm.stopBroadcast();
    }

    function deployContracts() public returns (VotingToken, PollManager) {
        // Deploy VotingToken with an initial supply of 1000 tokens
        VotingToken votingToken = new VotingToken(1000 * 10 ** 18);

        // Deploy PollManager
        PollManager pollManager = new PollManager();
        
        // Transfer ownership of VotingToken to PollManager
        // This allows PollManager to mint tokens for polls
        votingToken.transferOwnership(address(pollManager));
        
        // Set the VotingToken address in PollManager
        pollManager.setVotingToken(address(votingToken));

        return (votingToken, pollManager);
    }
}