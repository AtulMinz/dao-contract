// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
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
        token.mint(USER, 100e18);

        vm.prank(USER);
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        fundDao = new FundDAO(token, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();
    }

    function testMintToken() external {
        vm.prank(USER);
        token.mint(USER, 100e18);
    }

    function testCreateProposal() external {
        vm.prank(USER);
        token.mint(USER, 100e18);

        iGovernor = IGovernor(address(fundDao));

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

    function testProposalCreated() external {
        vm.prank(USER);
        token.mint(USER, 100e18);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal Created";

        bytes32 byteDescription = bytes32(abi.encode(description));

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mint(address,uint256)", USER, 100e18);

        vm.prank(USER);
        fundDao.propose(targets, values, calldatas, description);

        uint256 proposalId = fundDao.hashProposal(targets, values, calldatas, byteDescription);
        vm.expectEmit();

        vm.prank(USER);
        assertEq(uint256(fundDao.state(proposalId)), uint256(1), "Proposal in Active state");
    }
}
