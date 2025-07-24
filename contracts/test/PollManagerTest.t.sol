// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/PollManager.sol";
import "../src/VotingToken.sol";


contract PollManagerTest is Test {

    PollManager pollManager;
    VotingToken votingToken;

    event PollCreated(uint indexed pollId, string title, uint256 deadline);
    event TokenMinted(uint indexed pollId, address indexed user, uint256 amount);

    function setUp() public {
        // Deploy VotingToken with an initial supply of 1000 tokens
        votingToken = new VotingToken(1000 * 10 ** 18);

        // Deploy PollManager
        pollManager = new PollManager();
        
        // Transfer ownership of the VotingToken to the PollManager contract
        // This is needed because only the owner can mint tokens
        votingToken.transferOwnership(address(pollManager));
        
        // Set the VotingToken address in PollManager
        pollManager.setVotingToken(address(votingToken));
    }

    function testIfPollCreationEmitsEvent() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        vm.expectEmit(true, true, false, true);
        emit PollCreated(0, "Do you like swimming?", block.timestamp + duration);

        pollManager.createPoll("Do you like swimming?", options, duration);
    }   

    function testIfMintTokenForPollEmitsEvent() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Do you like swimming?", options, duration);

        // The test contract is the one calling mintTokenForPoll, so we expect the TokenMinted event
        // to be emitted with the test contract's address as the user
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(0, address(this), 1 * 10 ** 18);

        // This will emit the TokenMinted event with msg.sender as the test contract's address
        pollManager.mintTokenForPoll(0);
    }

    function testIfTokenBurnsAfterVoting() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Do you like swimming?", options, duration);

        uint256 initialBalance = votingToken.balanceOf(address(this));

        pollManager.mintTokenForPoll(0);

        // Approve PollManager to burn tokens on behalf of this test contract
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        pollManager.vote(0, "yes");

        // After minting and then burning 1 VT, the balance should return to the initial balance
        assertEq(votingToken.balanceOf(address(this)), initialBalance);
    } 

    function testIfWinnerIsCorrect() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Do you like swimming?", options, duration);

        // Create multiple voters using vm.prank to simulate different addresses
        address voter1 = address(0x1);
        address voter2 = address(0x2);
        address voter3 = address(0x3);

        // Voter 1 votes "yes"
        vm.startPrank(voter1);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, "yes");
        vm.stopPrank();

        // Voter 2 votes "yes" 
        vm.startPrank(voter2);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, "yes");
        vm.stopPrank();

        // Voter 3 votes "no"
        vm.startPrank(voter3);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, "no");
        vm.stopPrank();

        // Check the winner - "yes" should win with 2 votes vs "no" with 1 vote
        string memory winner = pollManager.getWinnerOption(0);
        assertEq(winner, "yes");

        // Also verify the vote counts
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 2); // "yes" should have 2 votes
        assertEq(results[1], 1); // "no" should have 1 vote
    }
    
}