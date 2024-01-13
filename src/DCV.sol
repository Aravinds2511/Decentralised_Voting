// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
GITHUB LINK: https://github.com/Aravinds2511/Decentralised_Voting.git

DESIGN OF THE CONTRACT:

Owner Management: The contract designates an owner (typically the creator of the contract) 
                  who has special privileges, like adding candidates.

Voter Registration: Individuals can register as voters. Once registered, they can participate in the election.

Candidate Management: The owner can add candidates to the election. Each candidate is identified by an address.

Voting Mechanism: Registered voters can vote for candidates. Each voter is restricted to one vote, and voting 
                  is not possible after the election has ended.

Election Control: The owner can end the election. Once the election is ended, no further voting can occur.

Winner Determination: After the election ends, the contract can determine the winner based on the highest vote count. 
                      In case of a tie, the contract indicates no clear winner.

Election Reset: The owner can reset the election for a new round, retaining the voter registrations but resetting votes and candidates.

Event Logging: Events are emitted for various activities like voter registration, candidate addition, vote casting, 
               ending the election, and resetting the election.

Access Control and Error Handling: The contract includes checks and custom errors to handle unauthorized actions, non-registered voters, 
                                   repeat voting, invalid candidate IDs, and other erroneous scenarios. 
*/

contract DecentralizedVoting {
    /////////Errors/////////

    error OnlyOwner();
    error AlreadyRegistered();
    error NotRegistered();
    error AlreadyVoted();
    error ElectionEndedError();
    error ElectionNotEndedYet();
    error InvalidCandidateID();
    error CandidateAlreadyAdded();

    //////////Events/////////

    event VoterRegistered(address voterAddress);
    event CandidateAdded(uint256 candidateId, address candidate);
    event VoteCasted(address voter, uint256 candidateId);
    event ElectionEnded();
    event ElectionReset();

    /////////State Variables////////

    address public owner;
    bool public electionEnded;
    address[] public winners;
    address[] private voterAddresses;
    Candidate[] public candidates;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
    }

    struct Candidate {
        address candidate;
        uint256 voteCount;
    }

    mapping(address => Voter) public voters;

    ////////Modifiers//////////

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyRegistered() {
        if (!voters[msg.sender].isRegistered) revert NotRegistered();
        _;
    }

    modifier notVoted() {
        if (voters[msg.sender].hasVoted) revert AlreadyVoted();
        _;
    }

    modifier electionNotEnded() {
        if (electionEnded) revert ElectionEndedError();
        _;
    }

    ////////Constructor/////////

    constructor() {
        owner = msg.sender;
    }

    //////////Functions////////

    function registerVoter() public {
        if (voters[msg.sender].isRegistered) revert AlreadyRegistered();
        voters[msg.sender].isRegistered = true;
        voterAddresses.push(msg.sender);
        emit VoterRegistered(msg.sender);
    }

    function addCandidate(address _candidate) public onlyOwner {
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].candidate == _candidate) revert CandidateAlreadyAdded();
        }

        candidates.push(Candidate(_candidate, 0));
        emit CandidateAdded(candidates.length - 1, _candidate);
    }

    function vote(uint256 _candidateId) public onlyRegistered notVoted electionNotEnded {
        if (_candidateId >= candidates.length) revert InvalidCandidateID();

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        candidates[_candidateId].voteCount++;

        emit VoteCasted(msg.sender, _candidateId);
    }

    function endElection() public onlyOwner {
        electionEnded = true;
        (address winner,,) = getWinner();
        winners.push(winner);
        emit ElectionEnded();
    }

    function resetElection() public onlyOwner {
        if (!electionEnded) revert ElectionNotEndedYet();

        delete candidates;
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            voters[voterAddresses[i]].hasVoted = false;
        }
        //didn't delete voter array since registration can be done once for all elections//
        electionEnded = false;

        emit ElectionReset();
    }

    function getWinner() public view returns (address, uint256, string memory) {
        if (!electionEnded) revert ElectionNotEndedYet();
        if (candidates.length == 0) {
            return (address(0), 0, "no Candidate");
        }

        uint256 winningVoteCount = 0;
        address winningCandidate;
        string memory result;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount == winningVoteCount) {
                winningCandidate = address(0);
                result = "no winner - tied";
            }
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidate = candidates[i].candidate;
                result = "winner";
            }
        }

        return (winningCandidate, winningVoteCount, result);
    }

    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 _candidateId) public view returns (address, uint256) {
        if (_candidateId >= candidates.length) revert InvalidCandidateID();
        return (candidates[_candidateId].candidate, candidates[_candidateId].voteCount);
    }
}
