//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract DAOToken is ERC20, ERC20Votes, ERC20Permit {

    constructor() ERC20("DAOToken", "DT") ERC20Permit("DAOTOken") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function _update(address to, address from, uint256 amount) internal override(ERC20Votes, ERC20) {
        super._update(to, from, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal {}

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns(uint256) {
        super.nonces(owner);
    }
}