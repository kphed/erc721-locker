// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "solady/tokens/ERC721.sol";

contract ERC721Locker {
    // Key is the packed abi-encoded hash of the owner, token address, and token ID.
    mapping(bytes32 key => uint256 expiry) public locks;

    event Lock(
        address indexed msgSender,
        address indexed owner,
        address indexed token,
        uint256 id,
        uint256 expiry
    );
    event Unlock(address indexed owner, address indexed token, uint256 id);

    error InvalidAddress();
    error InvalidLockDuration();

    /**
     * @notice Lock an ERC721 token for a specified duration.
     * @param  owner         address  Account which can withdraw the token after the lock expires.
     * @param  token         address  ERC721 token contract address.
     * @param  id            uint256  Token ID.
     * @param  lockDuration  uint256  Lock duration in seconds (starting from the current timestamp).
     */
    function lock(
        address owner,
        address token,
        uint256 id,
        uint256 lockDuration
    ) external {
        if (owner == address(0)) revert InvalidAddress();
        if (lockDuration == 0) revert InvalidLockDuration();

        // Will revert if the token is the zero address, or if `msg.sender` does not own `id`.
        ERC721(token).transferFrom(msg.sender, address(this), id);

        uint256 expiry = block.timestamp + lockDuration;
        locks[keccak256(abi.encodePacked(owner, token, id))] = expiry;

        emit Lock(msg.sender, owner, token, id, expiry);
    }
}
