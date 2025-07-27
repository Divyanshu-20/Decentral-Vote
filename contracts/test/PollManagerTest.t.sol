// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/PollManager.sol";
import "../src/VotingToken.sol";

/**
 * @title PollManagerTest
 * @dev Test suite for PollManager contract using only option index voting
 */
contract PollManagerTest is Test {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    PollManager pollManager;
    VotingToken votingToken;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PollCreated(uint indexed pollId, string title, uint256 deadline);
    event TokenMinted(uint indexed pollId, address indexed user, uint256 amount);
    event VoteCast(uint indexed pollId, address indexed voter, string choice);

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        // Deploy VotingToken with an initial supply of 1000 tokens
        votingToken = new VotingToken(1000 * 10 ** 18);

        // Deploy PollManager
        pollManager = new PollManager();
        
        // Transfer ownership of the VotingToken to the PollManager contract
        votingToken.transferOwnership(address(pollManager));
        
        // Set the VotingToken address in PollManager
        pollManager.setVotingToken(address(votingToken));
    }

    /*//////////////////////////////////////////////////////////////
                            POLL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testPollCreationEmitsEvent() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        vm.expectEmit(true, true, false, true);
        emit PollCreated(0, "Do you like swimming?", block.timestamp + duration);

        pollManager.createPoll("Do you like swimming?", options, duration);
    }

    function testGetTotalPolls() public {
        assertEq(pollManager.getTotalPolls(), 0);

        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        pollManager.createPoll("Test Poll 1", options, 3600);
        assertEq(pollManager.getTotalPolls(), 1);

        pollManager.createPoll("Test Poll 2", options, 3600);
        assertEq(pollManager.getTotalPolls(), 2);
    }

    function testPollDetails() public {
        string[] memory options = new string[](3);
        options[0] = "Alice";
        options[1] = "Bob";
        options[2] = "Charlie";
        uint256 duration = 3600;

        pollManager.createPoll("Best Developer", options, duration);

        (string memory title, string[] memory returnedOptions, uint256 deadline) = pollManager.pollDetails(0);
        
        assertEq(title, "Best Developer");
        assertEq(returnedOptions.length, 3);
        assertEq(returnedOptions[0], "Alice");
        assertEq(returnedOptions[1], "Bob");
        assertEq(returnedOptions[2], "Charlie");
        assertEq(deadline, block.timestamp + duration);
    }

    /*//////////////////////////////////////////////////////////////
                            TOKEN MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function testMintTokenForPollEmitsEvent() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600;

        pollManager.createPoll("Do you like swimming?", options, duration);

        vm.expectEmit(true, true, false, true);
        emit TokenMinted(0, address(this), 1 * 10 ** 18);

        pollManager.mintTokenForPoll(0);
    }

    function testCannotMintTwiceForSamePoll() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);
        
        pollManager.mintTokenForPoll(0);
        
        vm.expectRevert("Already minted for this poll");
        pollManager.mintTokenForPoll(0);
    }

    function testCannotMintForClosedPoll() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 1; // 1 second

        pollManager.createPoll("Test Poll", options, duration);
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 2);
        
        vm.expectRevert("Poll is closed");
        pollManager.mintTokenForPoll(0);
    }

    /*//////////////////////////////////////////////////////////////
                             VOTING TESTS
    //////////////////////////////////////////////////////////////*/

    function testVoteByIndexBasic() public {
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";
        uint256 duration = 3600;

        pollManager.createPoll("Test Poll", options, duration);

        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        
        // Vote for option at index 1 ("Option B")
        pollManager.vote(0, 1);

        // Verify the vote was recorded correctly
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 0); // "Option A" should have 0 votes
        assertEq(results[1], 1); // "Option B" should have 1 vote
        assertEq(results[2], 0); // "Option C" should have 0 votes

        // Verify user is marked as voted
        assertTrue(pollManager.hasVoted(0, address(this)));
    }

    function testVoteByIndexEmitsEvent() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        vm.expectEmit(true, true, false, true);
        emit VoteCast(0, address(this), "yes");

        pollManager.vote(0, 0); // Vote for "yes" (index 0)
    }

    function testCannotVoteWithInvalidIndex() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        vm.expectRevert("Invalid option index");
        pollManager.vote(0, 2); // Index 2 doesn't exist
    }

    function testCannotVoteTwice() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        pollManager.vote(0, 0);

        // Try to vote again
        vm.expectRevert("Already voted");
        pollManager.vote(0, 1);
    }

    function testCannotVoteWithoutTokens() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);

        // Try to vote without having any tokens
        // This will fail because burnFrom requires sufficient allowance and balance
        vm.expectRevert();
        pollManager.vote(0, 0);
    }

    function testCannotVoteOnClosedPoll() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 1; // 1 second

        pollManager.createPoll("Test Poll", options, duration);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);

        // Fast forward past deadline
        vm.warp(block.timestamp + 2);

        vm.expectRevert("Poll is closed");
        pollManager.vote(0, 0);
    }

    function testTokenBurnsAfterVoting() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);

        uint256 initialBalance = votingToken.balanceOf(address(this));

        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 0);

        // After minting and then burning 1 VT, balance should return to initial
        assertEq(votingToken.balanceOf(address(this)), initialBalance);
    }

    /*//////////////////////////////////////////////////////////////
                        MINT AND VOTE TESTS
    //////////////////////////////////////////////////////////////*/

    function testMintAndVote() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);

        uint256 initialBalance = votingToken.balanceOf(address(this));

        // Use mintAndVote - should mint token and vote in one transaction
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.mintAndVote(0, 0); // Vote for "yes" (index 0)

        // Check that vote was recorded
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 1); // "yes" should have 1 vote
        assertEq(results[1], 0); // "no" should have 0 votes

        // Check that token was minted and then burned (balance back to initial)
        assertEq(votingToken.balanceOf(address(this)), initialBalance);

        // Check that user is marked as voted and minted
        assertTrue(pollManager.hasVoted(0, address(this)));
        assertTrue(pollManager.hasMintedForPoll(0, address(this)));
    }

    function testMintAndVoteWhenAlreadyMinted() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";

        pollManager.createPoll("Test Poll", options, 3600);

        // First mint manually
        pollManager.mintTokenForPoll(0);
        
        // Then use mintAndVote - should not mint again, just vote
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.mintAndVote(0, 1);

        // Verify vote was recorded
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[1], 1); // "no" should have 1 vote
    }

    /*//////////////////////////////////////////////////////////////
                            POLL STATUS TESTS
    //////////////////////////////////////////////////////////////*/

    function testIsPollOpen() public {
        string[] memory options = new string[](2);
        options[0] = "yes";
        options[1] = "no";
        uint256 duration = 3600; // 1 hour

        pollManager.createPoll("Test Poll", options, duration);

        // Test that poll is open initially
        assertTrue(pollManager.isPollOpen(0));
        
        // Fast forward time by 30 minutes (poll should still be open)
        vm.warp(block.timestamp + 1800);
        assertTrue(pollManager.isPollOpen(0));
        
        // Fast forward time past deadline
        vm.warp(block.timestamp + 2700);
        assertFalse(pollManager.isPollOpen(0));
    }

    /*//////////////////////////////////////////////////////////////
                            WINNER TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetWinnerOptionSingleVote() public {
        string[] memory options = new string[](3);
        options[0] = "Alice";
        options[1] = "Bob";
        options[2] = "Charlie";

        pollManager.createPoll("Best Developer", options, 3600);

        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 1); // Vote for Bob

        string memory winner = pollManager.getWinnerOption(0);
        assertEq(winner, "Bob");
    }

    function testGetWinnerOptionMultipleVotes() public {
        string[] memory options = new string[](3);
        options[0] = "Alice";
        options[1] = "Bob";
        options[2] = "Charlie";

        pollManager.createPoll("Best Developer", options, 3600);

        // Create multiple voters
        address voter1 = address(0x1);
        address voter2 = address(0x2);
        address voter3 = address(0x3);
        address voter4 = address(0x4);

        // Voter 1 votes for Alice (index 0)
        vm.startPrank(voter1);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 0);
        vm.stopPrank();

        // Voter 2 votes for Bob (index 1)
        vm.startPrank(voter2);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 1);
        vm.stopPrank();

        // Voter 3 votes for Bob (index 1)
        vm.startPrank(voter3);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 1);
        vm.stopPrank();

        // Voter 4 votes for Alice (index 0)
        vm.startPrank(voter4);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 0);
        vm.stopPrank();

        // Check results: Alice=2, Bob=2, Charlie=0
        uint[] memory results = pollManager.pollResults(0);
        assertEq(results[0], 2); // Alice
        assertEq(results[1], 2); // Bob
        assertEq(results[2], 0); // Charlie

        // In case of tie, should return first option with max votes (Alice)
        string memory winner = pollManager.getWinnerOption(0);
        assertEq(winner, "Alice");
    }

    function testGetWinnerOptionClearWinner() public {
        string[] memory options = new string[](3);
        options[0] = "Alice";
        options[1] = "Bob";
        options[2] = "Charlie";

        pollManager.createPoll("Best Developer", options, 3600);

        // Create voters with Bob getting most votes
        address voter1 = address(0x1);
        address voter2 = address(0x2);
        address voter3 = address(0x3);

        // Alice gets 1 vote
        vm.startPrank(voter1);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 0);
        vm.stopPrank();

        // Bob gets 2 votes
        vm.startPrank(voter2);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 1);
        vm.stopPrank();

        vm.startPrank(voter3);
        pollManager.mintTokenForPoll(0);
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        pollManager.vote(0, 1);
        vm.stopPrank();

        string memory winner = pollManager.getWinnerOption(0);
        assertEq(winner, "Bob");
    }

    /*//////////////////////////////////////////////////////////////
                            UTILITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testNeedsTokenApproval() public {
        assertTrue(pollManager.needsTokenApproval(address(this)));
        
        votingToken.approve(address(pollManager), 1 * 10 ** 18);
        assertFalse(pollManager.needsTokenApproval(address(this)));
    }

    function testGetRequiredApproval() public view {
        assertEq(pollManager.getRequiredApproval(), 1 * 10 ** 18);
    }

    /*//////////////////////////////////////////////////////////////
                            ERROR TESTS
    //////////////////////////////////////////////////////////////*/

    function testCannotGetDetailsOfNonexistentPoll() public {
        vm.expectRevert("Poll does not exist");
        pollManager.pollDetails(0);
    }

    function testCannotGetResultsOfNonexistentPoll() public {
        vm.expectRevert("Poll does not exist");
        pollManager.pollResults(0);
    }

    function testCannotGetWinnerOfNonexistentPoll() public {
        vm.expectRevert("Poll does not exist");
        pollManager.getWinnerOption(0);
    }

    function testCannotCheckIfNonexistentPollIsOpen() public {
        vm.expectRevert("Poll does not exist");
        pollManager.isPollOpen(0);
    }

    function testCannotMintForNonexistentPoll() public {
        vm.expectRevert("Poll does not exist");
        pollManager.mintTokenForPoll(0);
    }

    function testCannotVoteOnNonexistentPoll() public {
        vm.expectRevert("Poll does not exist");
        pollManager.vote(0, 0);
    }
}