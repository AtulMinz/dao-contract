// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {FundDAO} from "../src/FundDAO.sol";
import {DAOToken} from "../src/DAOToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

contract DAOTokenTest is Test {
    FundDAO fundDao;
    DAOToken token;
    TimeLock timelock;
    address USER = makeAddr("USER");
    IGovernor iGovernor;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    function setUp() public {
        token = new DAOToken();
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        fundDao = new FundDAO(token, timelock);
    }

    function testMintToken() external {
        vm.prank(USER);
        token.mint(USER, 100e18);
    }

    function testCreateProposal() external {
        vm.prank(USER);
        token.mint(USER, 100e18);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mint(address,uint256)", USER, 100e18);

        vm.prank(USER);
        uint256 proposalId = fundDao.propose(targets, values, calldatas, description);

        assertGt(proposalId, 0, "Proposal ID should be non-zero");
        assertEq(uint256(fundDao.state(proposalId)), uint256(0), "Proposal should be in pending state");

        assertEq(fundDao.proposalThreshold(), 0, "Proposal threshold should be 0");
    }

    function testVotingDelay() external view {
        uint256 delay = fundDao.votingDelay();
        assertEq(delay, 300, "Voting Delay");
    }

    function testVotingPeriod() external view {
        uint256 votingPeriod = fundDao.votingPeriod();
        console.log(votingPeriod);
    }

    function testActiveProposal() external {
        vm.prank(USER);
        token.mint(USER, 100e18);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Testing Active proposal";

        bytes32 byteDescription = keccak256(bytes(description));

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mint(address,uint256)", USER, 100e18);

        vm.prank(USER);
        uint256 proposalId = fundDao.propose(targets, values, calldatas, description);
        uint256 proposalHash = fundDao.hashProposal(targets, values, calldatas, byteDescription);

        console.log("Proposal Hash", proposalHash);
        console.log("Proposal ID", proposalId);

        assertEq(proposalId, proposalHash, "Proposal ID Mismatch");

        //Active block as time is set to block 300. So in the nest block the status will be active.
        vm.roll(block.number + 301);

        assertEq(uint256(fundDao.state(proposalId)), uint256(1), "Proposal in Active state");
    }

    function testVotingPower() external {
        vm.prank(USER);
        token.mint(USER, 100e18);
        console.log(token.balanceOf(USER));

        vm.prank(USER);
        token.delegate(USER);
        uint256 delegrationBlock = block.number;

        vm.roll(block.number + 301);
        uint256 userVotes = fundDao.getVotes(USER, delegrationBlock);
        console.log(userVotes);
        assertEq(userVotes, 100e18, "USER should have 100e18 votes after delegate block");
    }

    function testUserVoteConfirmed() external {
        vm.prank(USER);
        token.mint(USER, 100e18);
        vm.prank(USER);
        token.delegate(USER);

        uint256 delegateblock = block.number;

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Testing Voting succeed";

        bytes32 descriptionHash = keccak256(bytes(description));

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mint(address,uint256)", USER, 100e18);

        vm.prank(USER);
        uint256 proposalId = fundDao.propose(targets, values, calldatas, description);
        uint256 proposalHash = fundDao.hashProposal(targets, values, calldatas, descriptionHash);

        assertEq(proposalId, proposalHash, "Proposal ID Mismatch");

        vm.roll(delegateblock + 301);
        assertEq(uint256(fundDao.state(proposalId)), uint256(1), "Proposal Active");

        vm.prank(USER);
        fundDao.castVote(proposalId, 1);
        assertTrue(fundDao.hasVoted(proposalId, USER), "USER should have voted");

        vm.roll(block.number + 300);
        console.log(uint256(proposalId));
        assertEq(uint256(fundDao.state(proposalId)), 4, "Proposal Passed");
    }
}
