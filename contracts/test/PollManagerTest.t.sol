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
        // This is needed because only the owner can mint tokens (TEST CONTRACT TO POLLMANAGER)
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
        pollManager.mintTokenForPoll(0); //mintTokenForPoll calls votingToken that's we need pollmanager to be owner
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

    function testIfPollIsOpen() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600; // 1 hour

        pollManager.createPoll("Do you like swimming?", options, duration);

        // Test that poll is open initially
        assertTrue(pollManager.isPollOpen(0));
        
        // Fast forward time by 30 minutes (poll should still be open)
        vm.warp(block.timestamp + 1800); // 1800 seconds = 30 minutes
        assertTrue(pollManager.isPollOpen(0));
        
        // Fast forward time by another 45 minutes (total 75 minutes, past deadline)
        vm.warp(block.timestamp + 2700); // 2700 seconds = 45 minutes
        assertFalse(pollManager.isPollOpen(0));
    }

    function testIfPollDetailsAreAvailable() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600; // 1 hour

        pollManager.createPoll("Do you like swimming?", options, duration);

        (string memory title, string[] memory options_, uint256 deadline) = pollManager.pollDetails(0);
        assertEq(title, "Do you like swimming?");
        assertEq(options_.length, 2);
        assertEq(options_[0], "yes");
        assertEq(options_[1], "no");
        assertEq(deadline, block.timestamp + duration);
    }

    // Test gas-optimized voteByIndex function
    function testVoteByIndex() public {
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";
        uint256 duration = 3600;

        pollManager.createPoll("Test Poll", options, duration);

        // Test voting by index
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        
        // Vote for option at index 1 ("Option B")
        pollManager.voteByIndex(0, 1);

        // Verify the vote was recorded correctly
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 0); // "Option A" should have 0 votes
        assertEq(results[1], 1); // "Option B" should have 1 vote
        assertEq(results[2], 0); // "Option C" should have 0 votes
    }

    function testVoteByIndexWithInvalidIndex() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Test Poll", options, duration);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        // Try to vote with invalid index (should revert)
        vm.expectRevert("Invalid option index");
        pollManager.voteByIndex(0, 2); // Index 2 doesn't exist (only 0 and 1)
    }

    function testMintAndVoteByIndex() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Test Poll", options, duration);

        uint256 initialBalance = votingToken.balanceOf(address(this));

        // Use mintAndVoteByIndex - should mint token and vote in one transaction
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.mintAndVoteByIndex(0, 0); // Vote for "yes" (index 0)

        // Check that vote was recorded
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 1); // "yes" should have 1 vote
        assertEq(results[1], 0); // "no" should have 0 votes

        // Check that token was minted and then burned (balance back to initial)
        assertEq(votingToken.balanceOf(address(this)), initialBalance);

        // Check that user is marked as voted
        assertTrue(pollManager.hasVoted(0, address(this)));
    }

    function testGasEfficiencyComparison() public {
        string[] memory options = new string[](4);
        options[0] = "Very Long Option Name A";
        options[1] = "Very Long Option Name B";
        options[2] = "Very Long Option Name C";
        options[3] = "Very Long Option Name D";
        uint256 duration = 3600;

        pollManager.createPoll("Gas Test Poll", options, duration);

        // Test string-based voting (original method)
        address voter1 = address(0x1);
        vm.startPrank(voter1);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        
        uint256 gasBefore = gasleft();
        pollManager.vote(0, "Very Long Option Name D"); // Vote for last option (worst case)
        uint256 gasUsedString = gasBefore - gasleft();
        vm.stopPrank();

        // Test index-based voting (optimized method)
        address voter2 = address(0x2);
        vm.startPrank(voter2);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        
        gasBefore = gasleft();
        pollManager.voteByIndex(0, 3); // Vote for same option by index
        uint256 gasUsedIndex = gasBefore - gasleft();
        vm.stopPrank();

        // Index-based voting should use less gas
        assertLt(gasUsedIndex, gasUsedString, "Index voting should be more gas efficient");

        // Both votes should be recorded correctly
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[3], 2); // Both votes for option D
    }

    function testWinnerWithIndexVoting() public {
        string[] memory options = new string[](3);
        options[0] = "Alice";
        options[1] = "Bob";
        options[2] = "Charlie";
        uint256 duration = 3600;

        pollManager.createPoll("Best Developer", options, duration);

        // Multiple voters using index-based voting
        address voter1 = address(0x1);
        address voter2 = address(0x2);
        address voter3 = address(0x3);
        address voter4 = address(0x4);

        // Voter 1 votes for Alice (index 0)
        vm.startPrank(voter1);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.voteByIndex(0, 0);
        vm.stopPrank();

        // Voter 2 votes for Bob (index 1)
        vm.startPrank(voter2);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.voteByIndex(0, 1);
        vm.stopPrank();

        // Voter 3 votes for Bob (index 1)
        vm.startPrank(voter3);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.voteByIndex(0, 1);
        vm.stopPrank();

        // Voter 4 votes for Alice (index 0)
        vm.startPrank(voter4);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.voteByIndex(0, 0);
        vm.stopPrank();

        // Check results: Alice=2, Bob=2, Charlie=0 (tie between Alice and Bob)
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 2); // Alice
        assertEq(results[1], 2); // Bob
        assertEq(results[2], 0); // Charlie

        // Winner should be Alice (first option with max votes in case of tie)
        string memory winner = pollManager.getWinnerOption(0);
        assertEq(winner, "Alice");
    }
    
}