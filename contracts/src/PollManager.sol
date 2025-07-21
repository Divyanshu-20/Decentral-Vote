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
    }

    function mintTokenForPoll(uint pollId) public {
        require(pollId < polls.length, "Poll does not exist");
        require(!hasMintedForPoll[pollId][msg.sender], "Already minted for this poll");
        require(block.timestamp < polls[pollId].deadline, "Poll is closed");
        
        hasMintedForPoll[pollId][msg.sender] = true;
        votingToken.mint(msg.sender, 1 * 10**18); // 1 VT token
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
    }

    function mintAndVote(uint pollId, string memory choice) public {
        // First mint token if user hasn't minted for this poll
        if (!hasMintedForPoll[pollId][msg.sender] && votingToken.balanceOf(msg.sender) == 0) {
            mintTokenForPoll(pollId);
        }
        
        // Then vote
        vote(pollId, choice);
    }

    function getTotalPolls() public view returns (uint) {
        return polls.length;
    }
}