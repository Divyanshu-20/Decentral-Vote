// PollManager.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VotingToken.sol";


contract PollManager is Ownable {
    struct Poll {
        uint256 id;
        string title;
        string[] options;
        uint256 deadline;
    }

    Poll[] public polls;
         
    // Track if a user has voted in a poll
    //For each poll ID (a number), store a mapping of user addresses to a boolean: true if they've voted, false if they haven't."
    mapping(uint => mapping(address => bool)) public hasVoted;
    //hasVoted[0][0xABC] → true

    // Track vote counts for each option in a poll
    //For each poll ID, track how many votes each option string received.
    mapping(uint => mapping(string => uint)) public voteCounts;
    
    // Track if user has minted token for a specific poll
    mapping(uint => mapping(address => bool)) public hasMintedForPoll;

    VotingToken public votingToken;

    // Events
    event PollCreated(uint indexed pollId, string title, uint256 deadline);
    event TokenMinted(uint indexed pollId, address indexed user, uint256 amount);
    event VoteCast(uint indexed pollId, address indexed voter, string choice);

    constructor() Ownable(msg.sender) {
        // VotingToken will be set after deployment
    }

    function setVotingToken(address votingTokenAddress) public onlyOwner {
        require(address(votingToken) == address(0), "VotingToken already set");
        votingToken = VotingToken(votingTokenAddress);
    }

    function createPoll(
        string memory _title,
        string[] memory _options,
        uint256 _duration
    ) public onlyOwner {
        // Create a new poll
        Poll memory newPoll = Poll({
            id: polls.length,
            title: _title,
            options: _options,
            deadline: block.timestamp + _duration
        });
        polls.push(newPoll);
        
        emit PollCreated(polls.length - 1, _title, block.timestamp + _duration);
    }

    function mintTokenForPoll(uint pollId) public {
        require(pollId < polls.length, "Poll does not exist");
        require(!hasMintedForPoll[pollId][msg.sender], "Already minted for this poll");
        require(block.timestamp < polls[pollId].deadline, "Poll is closed");
        
        hasMintedForPoll[pollId][msg.sender] = true;
        votingToken.mint(msg.sender, 1 * 10**18); // 1 VT token
        
        emit TokenMinted(pollId, msg.sender, 1 * 10**18);
    }

    function vote(uint pollId, string memory choice) public {
        require(pollId < polls.length, "Poll does not exist");
        //Thinking block: Whenever user vote - our app needs to interact with the poll itself, best way to get specific poll
        Poll storage poll = polls[pollId];

        require(block.timestamp < poll.deadline, "Poll is closed");
        require(!hasVoted[pollId][msg.sender], "Already voted"); //already voted will be shown if require retuns false
        require(votingToken.balanceOf(msg.sender) > 0, "No tokens to vote");
        
        bool validOption = false;
        for (uint i = 0; i < poll.options.length; i++) {
            if (keccak256(bytes(poll.options[i])) == keccak256(bytes(choice))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option");

        hasVoted[pollId][msg.sender] = true;
        voteCounts[pollId][choice] += 1;
        
        emit VoteCast(pollId, msg.sender, choice);
        votingToken.burnFrom(msg.sender, 1 * 10**18);
    }

    // Gas-optimized version using option index instead of string comparison
    function voteByIndex(uint pollId, uint optionIndex) public {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];

        require(block.timestamp < poll.deadline, "Poll is closed");
        require(!hasVoted[pollId][msg.sender], "Already voted");
        require(votingToken.balanceOf(msg.sender) > 0, "No tokens to vote");
        require(optionIndex < poll.options.length, "Invalid option index");

        hasVoted[pollId][msg.sender] = true;
        voteCounts[pollId][poll.options[optionIndex]] += 1;
        
        emit VoteCast(pollId, msg.sender, poll.options[optionIndex]);
        votingToken.burnFrom(msg.sender, 1 * 10**18);
    }

    function mintAndVote(uint pollId, string memory choice) public {
        // Mint if user hasn't minted for this specific poll
        if (!hasMintedForPoll[pollId][msg.sender]) {
            mintTokenForPoll(pollId);
        }
        
        // Then vote
        vote(pollId, choice);
    }

    function mintAndVoteByIndex(uint pollId, uint optionIndex) public {
        // Mint if user hasn't minted for this specific poll
        if (!hasMintedForPoll[pollId][msg.sender]) {
            mintTokenForPoll(pollId);
        }
        
        // Then vote
        voteByIndex(pollId, optionIndex);
    }

    function getTotalPolls() public view returns (uint) {
        return polls.length;
    }

    function getWinnerOption(uint pollId) public view returns (string memory winnerOption) {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];
        require(poll.options.length > 0, "Poll has no options");
        
        uint maxVotes = 0;
        uint winnerIndex = 0;
        for (uint i = 0; i < poll.options.length; i++) {
            uint count = voteCounts[pollId][poll.options[i]];
            if (count > maxVotes) {
                maxVotes = count;
                winnerIndex = i;
            }
        }
        winnerOption = poll.options[winnerIndex];
        // Note: In case of tie votes, returns the first option with maximum votes
    }

    function pollDetails(uint pollId) public view returns (
        string memory title,
        string[] memory options,
        uint256 deadline
    ) {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];
        return (poll.title, poll.options, poll.deadline);
    }

    function pollResults(uint pollId) public view returns (uint[] memory) {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];
        uint[] memory results = new uint[](poll.options.length);
        for (uint i = 0; i < poll.options.length; i++) {
            results[i] = voteCounts[pollId][poll.options[i]];
        }
        return results;
    }

    function isPollOpen(uint pollId) public view returns (bool) {
        require(pollId < polls.length, "Poll does not exist");
        return block.timestamp < polls[pollId].deadline;
    }

    // Helper function to check if user needs to approve tokens for voting
    function needsTokenApproval(address user) public view returns (bool) {
        return votingToken.allowance(user, address(this)) < 1 * 10**18;
    }

    // Function to get required approval amount
    function getRequiredApproval() public pure returns (uint256) {
        return 1 * 10**18; // 1 VT token
    }
}