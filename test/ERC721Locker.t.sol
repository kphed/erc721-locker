// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC721Locker} from "src/ERC721Locker.sol";

contract TestERC721 is ERC721 {
    function name() public pure override returns (string memory) {
        return "Test";
    }

    function symbol() public pure override returns (string memory) {
        return "TEST";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract ERC721LockerTest is Test {
    TestERC721 public immutable testToken = new TestERC721();
    ERC721Locker public immutable locker = new ERC721Locker();

    function testCannotLockInvalidAddress() external {
        address to = address(0);
        address token = address(testToken);
        uint256 id = 0;
        uint256 lockDuration = 1 days;

        vm.expectRevert(ERC721Locker.InvalidAddress.selector);

        locker.lock(to, token, id, lockDuration);
    }

    function testCannotLockInvalidLockDuration() external {
        address to = address(this);
        address token = address(testToken);
        uint256 id = 0;
        uint256 lockDuration = 0;

        vm.expectRevert(ERC721Locker.InvalidLockDuration.selector);

        locker.lock(to, token, id, lockDuration);
    }

    function testCannotLockInvalidToken() external {
        address to = address(this);
        address token = address(0);
        uint256 id = 0;
        uint256 lockDuration = 1 days;

        vm.expectRevert();

        locker.lock(to, token, id, lockDuration);
    }

    function testCannotLockTokenDoesNotExist() external {
        address to = address(this);
        address token = address(testToken);
        uint256 id = 0;
        uint256 lockDuration = 1 days;

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);

        testToken.ownerOf(id);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);

        locker.lock(to, token, id, lockDuration);
    }

    function testCannotLockTransferFromIncorrectOwner() external {
        address from = address(0);
        address to = address(this);
        address token = address(testToken);
        uint256 id = 0;
        uint256 lockDuration = 1 days;

        testToken.mint(address(this), id);

        assertTrue(testToken.ownerOf(id) != from);

        vm.prank(from);
        vm.expectRevert(ERC721.TransferFromIncorrectOwner.selector);

        locker.lock(to, token, id, lockDuration);
    }

    function testLock() external {
        address to = address(0xbeef);
        address token = address(testToken);
        uint256 id = 0;
        uint256 lockDuration = 1 days;
        uint256 expiry = block.timestamp + lockDuration;

        testToken.mint(address(this), id);
        testToken.setApprovalForAll(address(locker), true);

        vm.expectEmit(true, true, true, true, address(locker));

        emit ERC721Locker.Lock(address(this), to, token, id, expiry);

        locker.lock(to, token, id, lockDuration);

        ERC721Locker.LockDetails memory lockDetails = locker.getLock(to, token);

        assertEq(address(locker), testToken.ownerOf(id));
        assertEq(id, lockDetails.id);
        assertEq(expiry, lockDetails.expiry);
    }

    function testLockFuzz(
        address from,
        address to,
        uint256 id,
        uint256 lockDuration
    ) external {
        vm.assume(from != address(0) && to != address(0));

        lockDuration = bound(lockDuration, 1, 10_000 days);
        address token = address(testToken);
        uint256 expiry = block.timestamp + lockDuration;

        testToken.mint(from, id);

        vm.startPrank(from);

        testToken.setApprovalForAll(address(locker), true);

        vm.expectEmit(true, true, true, true, address(locker));

        emit ERC721Locker.Lock(from, to, token, id, expiry);

        locker.lock(to, token, id, lockDuration);

        vm.stopPrank();

        ERC721Locker.LockDetails memory lockDetails = locker.getLock(to, token);

        assertEq(address(locker), testToken.ownerOf(id));
        assertEq(id, lockDetails.id);
        assertEq(expiry, lockDetails.expiry);
    }
}
