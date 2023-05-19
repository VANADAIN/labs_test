// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OwnableV1 {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assembly {
            if iszero(eq(caller(), sload(owner.slot))) {
               let ptr := mload(0x40) 
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 6) // Revert bytes
                mstore(add(ptr, 0x44), 0x6e4f776e65720000000000000000000000000000000000000000000000000000)
                revert(ptr, 0x64)
            }
        }
        _;
    }

    // sol: 2319 gas
    // asm: 2301 gas
    function getOwner() external view returns (address r) {
        assembly {
            r := sload(owner.slot)
        }
    }

    function setOwner(address wallet) external onlyOwner returns (address r) {
        assembly {
            sstore(owner.slot, wallet)  
            r := wallet
        }
    }
}

contract WhiteListV1 is OwnableV1 {
    error NotMember();
    mapping(address => bool) whiteList;

    modifier isWhiteListed(address addr) {
        if(!whiteList[addr]) {
            revert NotMember();
        }
        _;
    }

    function checkMembership(address addr) public view returns (bool value) {
        assembly {
            value := sload(add(whiteList.slot, mul(addr, 0x20)))
        }
    }

    function deleteFromWhiteList(address addr)
        external
        onlyOwner
    {
        assembly {
            sstore(add(whiteList.slot, mul(addr, 0x20)), 0)
        }
    }

    function addWhiteList(address addr) external onlyOwner {
        assembly {
            sstore(add(whiteList.slot, mul(addr, 0x20)), 1)
        }
    }
}

contract TransferV1 is OwnableV1, WhiteListV1 {
    event ProxyDeposit(address token, address indexed from, address to, uint256 amount);

    function proxyToken(
        address token,
        address to,
        uint256 amount
    ) external isWhiteListed(to) {

        uint256 _TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;

        assembly {
            function reRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            let emptyPtr := mload(0x40)

            mstore(emptyPtr, _TRANSFER_FROM_CALL_SELECTOR_32)
            mstore(add(emptyPtr, 0x4), caller())
            mstore(add(emptyPtr, 0x24), to)
            mstore(add(emptyPtr, 0x44), amount)

            if iszero(call(gas(), token, 0, emptyPtr, 0x64, 0, 0)) {
                reRevert()
            }

            // Calculate the size of the event data
            let eventSize := 96

            // Allocate memory for the event data
            let eventPtr := mload(0x40)
            mstore(eventPtr, token)
            mstore(add(eventPtr, 0x20), caller())
            mstore(add(eventPtr, 0x40), to)
            mstore(add(eventPtr, 0x60), amount)

            // Emit the event
            log4(eventPtr, eventSize, 0, 0, 0, 0)
        }

        // IERC20(token).transferFrom(msg.sender, to, amount);

        // emit ProxyDeposit(token, msg.sender , to, amount);
    }
}

