// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "ds-test/test.sol";
import {DecentralizedVoting} from "../src/DCV.sol";

import "forge-std/Vm.sol";

contract DSVTest is DSTest {
    DecentralizedVoting voting;
    Vm vm = Vm(HEVM_ADDRESS);
    address owner = address(this);

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    address candidate1 = address(4);
    address candidate2 = address(5);

    //setup function
    function setUp() public {
        voting = new DecentralizedVoting();
    }

    //testing Register Function
    function isVoterRegistered(address voter) internal view returns (bool) {
        (bool isRegistered,,) = voting.voters(voter);
        return isRegistered;
    }

    function testRegisterVoter() public {
        //user 1 registration
        vm.prank(user1);
        voting.registerVoter();
        assertTrue(isVoterRegistered(user1));

        //attempting to register again
        vm.expectRevert(DecentralizedVoting.AlreadyRegistered.selector);
        vm.prank(user1);
        voting.registerVoter();

        //user2 registration
        vm.prank(user2);
        voting.registerVoter();
        assertTrue(isVoterRegistered(user2));
    }

    //testing addCandidate function
    function testAddCandidate() public {
        // adding candidate1
        vm.prank(owner);
        voting.addCandidate(user1);
        assertEq(voting.getCandidateCount(), 1); //test getCandidateCount function
        (address addedCandidate1, uint256 voteCount1) = voting.getCandidate(0);
        assertEq(addedCandidate1, user1);
        assertEq(voteCount1, 0); //test getCandidate function

        //adding candidate2
        vm.prank(owner);
        voting.addCandidate(user2);
        (address addedCandidate2, uint256 voteCount2) = voting.getCandidate(1);
        assertEq(addedCandidate2, user2);
        assertEq(voteCount2, 0);

        // adding candidate1 again reverts
        vm.expectRevert(DecentralizedVoting.CandidateAlreadyAdded.selector);
        vm.prank(owner);
        voting.addCandidate(user1);
    }

    //testing vote function
    function testVoteFunction() public {
        vm.prank(owner);
        voting.addCandidate(candidate1);
        vm.prank(owner);
        voting.addCandidate(candidate2);
        vm.prank(user1);
        voting.registerVoter();
        vm.prank(user2);
        voting.registerVoter();

        //successful voting
        vm.prank(user1);
        voting.vote(0);
        (, uint256 voteCount) = voting.getCandidate(0);
        assertEq(voteCount, 1);

        //getCandidate function
        (address addedCandidate1, uint256 vote1) = voting.getCandidate(0);
        assertEq(addedCandidate1, candidate1);
        assertEq(vote1, 1);
        (address addedCandidate2, uint256 vote2) = voting.getCandidate(1);
        assertEq(addedCandidate2, candidate2);
        assertEq(vote2, 0);

        //vote from unregistered voter
        vm.expectRevert(DecentralizedVoting.NotRegistered.selector);
        vm.prank(user3);
        voting.vote(0);

        //re-voting by same voter
        vm.expectRevert(DecentralizedVoting.AlreadyVoted.selector);
        vm.prank(user1);
        voting.vote(1);

        //voting after election ended + testing endElectionFunction
        vm.prank(owner);
        voting.endElection();
        assertTrue(voting.electionEnded());
        vm.expectRevert(DecentralizedVoting.ElectionEndedError.selector);
        vm.prank(user2);
        voting.vote(1);
    }

    //testing resetElection function
    function testResetElection() public {
        vm.prank(owner);
        voting.addCandidate(candidate1);
        vm.prank(user1);
        voting.registerVoter();

        //end election
        vm.prank(owner);
        voting.endElection();
        assertTrue(voting.electionEnded());

        //reset election
        vm.prank(owner);
        voting.resetElection();
        assertTrue(!voting.electionEnded());

        //candidates count should be 0
        assertEq(voting.getCandidateCount(), 0);

        //end election
        vm.prank(owner);
        voting.endElection();
        assertTrue(voting.electionEnded());

        //reset the election again
        vm.prank(owner);
        voting.resetElection();
        assertTrue(!voting.electionEnded());

        //resetting the election without ending it
        vm.expectRevert(DecentralizedVoting.ElectionNotEndedYet.selector);
        vm.prank(owner);
        voting.resetElection();
    }

    //testing getWinner function
    function testGetWinner() public {
        //no candidates case
        vm.prank(owner);
        voting.endElection();
        (address noWinner, uint256 noVotes, string memory noResult) = voting.getWinner();
        assertEq(noWinner, address(0));
        assertEq(noVotes, 0);
        assertEq(noResult, "no Candidate");

        //election ended with a clear winner
        vm.prank(owner);
        voting.resetElection();
        vm.prank(user1);
        voting.registerVoter();
        vm.prank(user2);
        voting.registerVoter();
        vm.prank(owner);
        voting.addCandidate(candidate1);
        vm.prank(owner);
        voting.addCandidate(candidate2);
        vm.prank(user1);
        voting.vote(0);
        vm.prank(user2);
        voting.vote(0);
        vm.prank(owner);
        voting.endElection();
        (address winner, uint256 voteCount, string memory result) = voting.getWinner();
        assertEq(winner, candidate1);
        assertEq(voteCount, 2);
        assertEq(result, "winner");

        //election ended with a tie
        vm.prank(owner);
        voting.resetElection();
        vm.prank(owner);
        voting.addCandidate(candidate1);
        vm.prank(owner);
        voting.addCandidate(candidate2);
        vm.prank(user1);
        voting.vote(0);
        vm.prank(user2);
        voting.vote(1);
        vm.prank(owner);
        voting.endElection();
        (address tieWinner, uint256 tieVotes, string memory tieResult) = voting.getWinner();
        assertEq(tieWinner, address(0));
        assertEq(tieVotes, 1);
        assertEq(tieResult, "no winner - tied");

        //election not ended case
        vm.prank(owner);
        voting.resetElection();
        vm.prank(owner);
        voting.addCandidate(candidate1);
        vm.expectRevert(DecentralizedVoting.ElectionNotEndedYet.selector);
        voting.getWinner();
    }
}
