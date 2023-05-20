// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
    Deploy:
    V0 -  379719 gas
    V1 -  301527 gas 

    All tested with 200 optimizer runs
*/


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
   
    // 2341 gas -> 2341 gas
    function getOwner() external view returns (address r) {
        return owner;
    }

    // 31070 gas -> 30866 gas
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
    
    // 4425 gas -> 2559 gas
    function checkMembership(address addr) public view returns (bool value) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, addr)
            mstore(add(ptr, 0x20), whiteList.slot)
            let slot := keccak256(ptr, 0x40)
            value := sload(slot)
        }
    }

    // ... -> 38888 gas
    function deleteFromWhiteList(address addr)
        external
        onlyOwner
    {
        require(whiteList[addr]);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, addr)
            mstore(add(ptr, 0x20), whiteList.slot)
            let slot := keccak256(ptr, 0x40)
            sstore(slot, false)
        }
    }

    // 53084 gas -> 53058 gas
    function addWhiteList(address addr) external onlyOwner {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, addr)
            mstore(add(ptr, 0x20), whiteList.slot)
            let slot := keccak256(ptr, 0x40)
            sstore(slot, true)
        }
    }
}

contract TransferV1 is OwnableV1, WhiteListV1 {
    event ProxyDeposit(address token, address indexed from, address to, uint256 amount);

    // 79686 gas -> 77860 gas // unoptimized
    // 76777 gas -> 54174 gas // 200 opt
    function proxyToken(
        address token,
        address to,
        uint256 amount
    ) external isWhiteListed(to) {

        // bytes32 of keccak of event signature
        bytes32 topic = 0xd380ef37d2d0f7023ba9d03fe5554672e7a6391b6d42a453a365c0409c375011;

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
            log1(eventPtr, eventSize, topic)
        }
    }
}

