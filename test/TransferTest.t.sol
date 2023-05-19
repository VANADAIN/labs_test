// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../src/Transfer.sol";
import "../src/TransferV1.sol";

contract TransferTest is Test {
    Transfer public t;
    TransferV1 public tv1;
    OwnableV1 public ownv1;

    address user = vm.addr(1);

    function setUp() public {
        t = new Transfer();
        tv1 = new TransferV1();
        vm.startPrank(user);
        ownv1 = new OwnableV1();
    }

    function testSetOwner() public {
        assertEq(ownv1.getOwner(), user);
        console.log("Owner asserted");

        ownv1.setOwner(vm.addr(2)); // ok
        console.log("Owner is set");

        // vm.stopPrank();
        // vm.prank(vm.addr(3));

        // console.log("Error next");
        // vm.expectRevert("nOwner");
        // ownv1.setOwner(vm.addr(1)); // not ok
    }
}