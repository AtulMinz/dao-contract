// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {FundDAO} from "../src/FundDAO.sol";
import {DAOToken} from "../src/DAOToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DAOTokenTest is Test {
    FundDAO fundDao;
    DAOToken token;
    TimeLock timelock;
    address USER = makeAddr("USER");

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
}