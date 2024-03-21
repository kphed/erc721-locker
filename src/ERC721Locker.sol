// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solady/tokens/ERC721.sol";

contract ERC721Locker {
    struct LockDetails {
        uint256 id;
        uint256 expiry;
    }

    mapping(address owner => mapping(address token => LockDetails)) locks;

    event Lock(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 id,
        uint256 expiry
    );

    error InvalidAddress();
    error InvalidLockDuration();

    /**
     * @notice Lock an ERC721 token for a specified duration.
     * @param  to            address  Account which can withdraw the token after the lock expires.
     * @param  token         address  ERC721 token contract address.
     * @param  id            uint256  Token ID.
     * @param  lockDuration  uint256  Lock duration in seconds (starting from the current timestamp).
     */
    function lock(
        address to,
        address token,
        uint256 id,
        uint256 lockDuration
    ) external {
        if (to == address(0)) revert InvalidAddress();
        if (lockDuration == 0) revert InvalidLockDuration();

        // Will revert if the token is the zero address, or if `msg.sender` does not own `id`.
        ERC721(token).transferFrom(msg.sender, address(this), id);

        uint256 expiry = block.timestamp + lockDuration;
        locks[to][token] = LockDetails({id: id, expiry: expiry});

        emit Lock(msg.sender, to, token, id, expiry);
    }
}
