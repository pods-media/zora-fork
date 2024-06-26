// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockPermissionControl} from "../mock/MockPermissionControl.sol";

contract CreatorPermissionControlTest is Test {
    MockPermissionControl creatorPermissions;

    function setUp() public {
        creatorPermissions = new MockPermissionControl();
    }

    function test_showsNoPermission(uint256 tokenId, address user, uint256 permissionBits) public {
        assertFalse(creatorPermissions.hasAnyPermission(tokenId, user, permissionBits));
    }

    function test_addPermissions(uint256 tokenId, address user) public {
        creatorPermissions.addPermission(tokenId, user, 0x1);
        creatorPermissions.addPermission(tokenId, user, 0x2);
        assertEq(creatorPermissions.getPermissions(tokenId, user), 0x3);
    }

    function test_addPermissionOtherExists(uint256 tokenId, address user, uint256 id) public {
        vm.assume(id != 0x1);
        vm.assume(id != 0x0);
        creatorPermissions.addPermission(tokenId, user, 0x1);
        assertFalse(creatorPermissions.hasPermissions(tokenId, user, id));
    }

    function test_hasAllPermissions(uint256 tokenId, address user) public {
        creatorPermissions.addPermission(tokenId, user, type(uint256).max);
        assertEq(creatorPermissions.getPermissions(tokenId, user), type(uint256).max);
    }

    function test_clearPermissions(uint256 tokenId, address user) public {
        creatorPermissions.addPermission(tokenId, user, type(uint256).max);
        assertEq(creatorPermissions.getPermissions(tokenId, user), type(uint256).max);
        creatorPermissions.clearPermissions(tokenId, user);
        assertEq(creatorPermissions.getPermissions(tokenId, user), 0);
    }

    function test_removePermission(uint256 tokenId, address user) public {
        creatorPermissions.addPermission(tokenId, user, type(uint256).max);
        assertEq(creatorPermissions.getPermissions(tokenId, user), type(uint256).max);
        creatorPermissions.clearPermissions(tokenId, user);
        assertEq(creatorPermissions.getPermissions(tokenId, user), 0);
    }
}
