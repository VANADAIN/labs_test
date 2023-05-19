// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../src/Transfer.sol";
import "../src/TransferV1.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Token is ERC20("token", "tk") {
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract TransferV1Test is Test {
    error NotMember();
    Transfer public t;
    TransferV1 public tv1;
    OwnableV1 public ownv1;
    WhiteListV1 public wl1;

    address user = vm.addr(1);

    function setUp() public {
        vm.startPrank(user);
        t = new Transfer();
        tv1 = new TransferV1();
        ownv1 = new OwnableV1();
        wl1 = new WhiteListV1();
    }

    function testV1() public {
        // set owner
        assertEq(ownv1.getOwner(), user);
        ownv1.setOwner(vm.addr(2)); 

        // whitelist
        wl1.addWhiteList(vm.addr(2)); 
        assertEq(wl1.checkMembership(vm.addr(2)), true);

        // delete from wl
        wl1.deleteFromWhiteList(vm.addr(2));
        assertEq(wl1.checkMembership(vm.addr(2)), false);

        // transfer


        vm.stopPrank();



        vm.prank(vm.addr(3));
        vm.expectRevert("nOwner");
        ownv1.setOwner(vm.addr(1)); // not ok

        vm.expectRevert("nOwner");
        wl1.addWhiteList(vm.addr(2)); // not ok
    }
}