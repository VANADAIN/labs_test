// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

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
    Token public tok;

    Owner public own;
    WhiteList public wl;
    Transfer public t;

    TransferV1 public tv1;
    OwnableV1 public ownv1;
    WhiteListV1 public wl1;

    address user = vm.addr(1);

    function setUp() public {
        vm.startPrank(user);
        tok = new Token();
        t = new Transfer();
        tv1 = new TransferV1();
    }

    function testV1() public {
        address ad2 = vm.addr(2);

        // set owner
        assertEq(tv1.getOwner(), user);
        tv1.setOwner(ad2); 
        assertEq(tv1.getOwner(), ad2);

        vm.prank(ad2);
        tv1.setOwner(user); 
        assertEq(tv1.getOwner(), user);

        vm.startPrank(user);


        // whitelist
        tv1.addWhiteList(ad2); 
        assertEq(tv1.checkMembership(ad2), true);

        // delete
        tv1.deleteFromWhiteList(ad2);
        assertEq(tv1.checkMembership(ad2), false);

        // transfer
        tv1.addWhiteList(ad2); 
        assertEq(tv1.checkMembership(ad2), true);
        tok.mint(10000);
        tok.approve(address(tv1), 100);
        tv1.proxyToken(address(tok), ad2, 100);

        vm.stopPrank();
        vm.startPrank(vm.addr(3));
        vm.expectRevert("nOwner");
        tv1.setOwner(vm.addr(1)); // not ok

        vm.expectRevert("nOwner");
        tv1.addWhiteList(vm.addr(2)); // not ok

        tok.mint(10000);
        tok.approve(address(tv1), 100);

        vm.expectRevert(
            WhiteListV1.NotMember.selector
        );
        tv1.proxyToken(address(tok), vm.addr(4), 100); // not wl
    }

    function testV0() public {
        address ad2 = vm.addr(2);


        // set owner
        assertEq(t.getOwner(), user);
        t.setOwner(ad2); 
        assertEq(t.getOwner(), ad2);

        vm.prank(ad2);
        t.setOwner(user); 
        assertEq(t.getOwner(), user);

        vm.startPrank(user);


        t.deleteFromWhiteList(ad2);

        // whitelist
        // t.addWhiteList(ad2); 
        // t.addWhiteList(user); 

        // transfer
        tok.mint(10000);
        tok.approve(address(t), 100);
        t.proxyToken(address(tok), ad2, 100);

        vm.stopPrank();

        vm.startPrank(vm.addr(9));
        vm.expectRevert("Caller is not owner");
        t.setOwner(user); // not ok

        vm.expectRevert("Caller is not owner");
        t.addWhiteList(ad2); // not ok

        tok.mint(10000);
        tok.approve(address(t), 100);

        t.proxyToken(address(tok), ad2, 100); // not wl
    }
}