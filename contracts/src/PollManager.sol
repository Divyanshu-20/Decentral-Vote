// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VotingToken.sol";

/**
 * @title PollManager
 * @dev Manages decentralized voting polls with token-based voting system
 * @notice Users can create polls, mint voting tokens, and vote using option indices
 */
contract PollManager is Ownable {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Poll {
        uint256 id;
        string title;
        string[] options;
        uint256 deadline;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Array of all polls
    Poll[] public polls;

    /// @notice VotingToken contract instance
    VotingToken public votingToken;

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Track if a user has voted in a poll: pollId => user => hasVoted
    mapping(uint => mapping(address => bool)) public hasVoted;

    /// @notice Track vote counts for each option in a poll: pollId => optionString => voteCount
    mapping(uint => mapping(string => uint)) public voteCounts;

    /// @notice Track if user has minted token for a specific poll: pollId => user => hasMinted
    mapping(uint => mapping(address => bool)) public hasMintedForPoll;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PollCreated(uint indexed pollId, string title, uint256 deadline);
    event TokenMinted(uint indexed pollId, address indexed user, uint256 amount);
    event VoteCast(uint indexed pollId, address indexed voter, string choice);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
        // VotingToken will be set after deployment
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the VotingToken contract address (can only be called once)
     * @param votingTokenAddress Address of the VotingToken contract
     */
    function setVotingToken(address votingTokenAddress) external onlyOwner {
        require(address(votingToken) == address(0), "VotingToken already set");
        votingToken = VotingToken(votingTokenAddress);
    }

    /**
     * @notice Create a new poll
     * @param _title Title of the poll
     * @param _options Array of option strings
     * @param _duration Duration in seconds from current time
     */
    function createPoll(
        string memory _title,
        string[] memory _options,
        uint256 _duration
    ) external onlyOwner {
        Poll memory newPoll = Poll({
            id: polls.length,
            title: _title,
            options: _options,
            deadline: block.timestamp + _duration
        });
        polls.push(newPoll);
        
        emit PollCreated(polls.length - 1, _title, block.timestamp + _duration);
    }

    /**
     * @notice Mint voting token for a specific poll
     * @param pollId ID of the poll
     */
    function mintTokenForPoll(uint pollId) external {
        require(pollId < polls.length, "Poll does not exist");
        require(!hasMintedForPoll[pollId][msg.sender], "Already minted for this poll");
        require(block.timestamp < polls[pollId].deadline, "Poll is closed");
        
        hasMintedForPoll[pollId][msg.sender] = true;
        votingToken.mint(msg.sender, 1 * 10**18); // 1 VT token
        
        emit TokenMinted(pollId, msg.sender, 1 * 10**18);
    }

    /**
     * @notice Vote for an option using its index (gas-optimized)
     * @param pollId ID of the poll
     * @param optionIndex Index of the option to vote for
     */
    function vote(uint pollId, uint optionIndex) external {
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

    /**
     * @notice Mint token and vote in a single transaction
     * @param pollId ID of the poll
     * @param optionIndex Index of the option to vote for
     */
    function mintAndVote(uint pollId, uint optionIndex) external {
        // Mint if user hasn't minted for this specific poll
        if (!hasMintedForPoll[pollId][msg.sender]) {
            // Inline minting logic to avoid external call issues
            require(pollId < polls.length, "Poll does not exist");
            require(block.timestamp < polls[pollId].deadline, "Poll is closed");
            
            hasMintedForPoll[pollId][msg.sender] = true;
            votingToken.mint(msg.sender, 1 * 10**18); // 1 VT token
            
            emit TokenMinted(pollId, msg.sender, 1 * 10**18);
        }
        
        // Then vote - inline voting logic
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

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get total number of polls
     * @return Total number of polls created
     */
    function getTotalPolls() external view returns (uint) {
        return polls.length;
    }

    /**
     * @notice Get the winning option of a poll
     * @param pollId ID of the poll
     * @return winnerOption String of the winning option
     */
    function getWinnerOption(uint pollId) external view returns (string memory winnerOption) {
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

    /**
     * @notice Get poll details
     * @param pollId ID of the poll
     * @return title Poll title
     * @return options Array of option strings
     * @return deadline Poll deadline timestamp
     */
    function pollDetails(uint pollId) external view returns (
        string memory title,
        string[] memory options,
        uint256 deadline
    ) {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];
        return (poll.title, poll.options, poll.deadline);
    }

    /**
     * @notice Get poll results (vote counts for each option)
     * @param pollId ID of the poll
     * @return Array of vote counts corresponding to each option
     */
    function pollResults(uint pollId) external view returns (uint[] memory) {
        require(pollId < polls.length, "Poll does not exist");
        Poll storage poll = polls[pollId];
        uint[] memory results = new uint[](poll.options.length);
        for (uint i = 0; i < poll.options.length; i++) {
            results[i] = voteCounts[pollId][poll.options[i]];
        }
        return results;
    }

    /**
     * @notice Check if a poll is currently open for voting
     * @param pollId ID of the poll
     * @return True if poll is open, false otherwise
     */
    function isPollOpen(uint pollId) external view returns (bool) {
        require(pollId < polls.length, "Poll does not exist");
        return block.timestamp < polls[pollId].deadline;
    }

    /**
     * @notice Check if user needs to approve tokens for voting
     * @param user Address of the user
     * @return True if approval is needed, false otherwise
     */
    function needsTokenApproval(address user) external view returns (bool) {
        return votingToken.allowance(user, address(this)) < 1 * 10**18;
    }

    /**
     * @notice Get required approval amount for voting
     * @return Required approval amount in wei
     */
    function getRequiredApproval() external pure returns (uint256) {
        return 1 * 10**18; // 1 VT token
    }
}