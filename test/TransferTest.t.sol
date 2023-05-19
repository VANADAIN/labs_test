// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../src/Transfer.sol";
import "../src/TransferV1.sol";

contract TransferV1Test is Test {
    Transfer public t;
    TransferV1 public tv1;
    OwnableV1 public ownv1;

    address user = vm.addr(1);

    function setUp() public {
        vm.startPrank(user);
        t = new Transfer();
        tv1 = new TransferV1();
        ownv1 = new OwnableV1();
    }

    function testV1() public {
        assertEq(ownv1.getOwner(), user);
        ownv1.setOwner(vm.addr(2)); // ok



        vm.stopPrank();



        vm.prank(vm.addr(3));
        vm.expectRevert("nOwner");
        ownv1.setOwner(vm.addr(1)); // not ok
    }
}