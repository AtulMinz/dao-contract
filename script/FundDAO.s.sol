// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {FundDAO} from "../src/FundDAO.sol";
import {DAOToken} from "../src/DAOToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract DeployDao is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address deployer;

    // function setUp() public {
    //     deployer = vm.parseAddress("0xbb2fc2143645a32437dc722b4f5652dd94b82eba397b19c8e8f57b387d60127b");
        
    //     if (deployer == address(0)) {
    //         deployer = address(this);
    //     }
    // }

    function run() public {
        vm.startBroadcast();

        DAOToken token = new DAOToken();
        console.log("DAO Token deployed at this address: ", address(token));

        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0);
        executors[0] = address(0);

        address admin = 0xc8667AD0426CBb8671426ae5f39329283062D049;
        TimelockController timeLock = new TimelockController(
            VOTING_DELAY,
            proposers,
            executors,
            admin
        );
        console.log("TimeLockController Deployed: ", address(timeLock));

        FundDAO fundDao = new FundDAO(token, timeLock);
        console.log("DAO Deployed: ", address(fundDao));


        timeLock.grantRole(timeLock.PROPOSER_ROLE(), address(fundDao));

        console.log("Deployment complete!");
        console.log("DAOToken address:", address(token));
        console.log("TimelockController address:", address(timeLock));
        console.log("FundDAO address:", address(fundDao));

        vm.stopBroadcast();
    }
}
