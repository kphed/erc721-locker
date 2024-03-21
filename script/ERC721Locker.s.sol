// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ERC721Locker} from "src/ERC721Locker.sol";

contract ERC721LockerScript is Script {
    function run() public {
        vm.broadcast(vm.envUint("PRIVATE_KEY"));

        new ERC721Locker();
    }
}
