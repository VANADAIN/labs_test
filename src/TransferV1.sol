// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* 
    Deployment:
    - Optimizator   unabled: 283972 gas
 	                enabled: 172786 gas
*/
contract OwnableV1 {
    error NotOwner();
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assembly {
            if iszero(eq(caller(), sload(owner.slot))) {
               let ptr := mload(0x40) // Get free memory pointer
                mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000) // Selector for method Error(string)
                mstore(add(ptr, 0x04), 0x20) // String offset
                mstore(add(ptr, 0x24), 6) // Revert reason length
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

    function setOwner(address wallet) external onlyOwner returns (address) {
        owner = wallet;
        return owner;
    }
}

contract WhiteListV1 is OwnableV1 {
    mapping(address => uint16) whiteList;

    modifier checkOfWhiteLists(address adr) {
        require(checkOfWhiteList(adr) == 0, "Not WhiteList");
        _;
    }

    function checkOfWhiteList(address adr) private view returns (uint16) {
        if (whiteList[adr] > 0) {
            return whiteList[adr];
        }

        return 0;
    }

    function deleteFromWhiteList(address adr)
        public
        checkOfWhiteLists(adr)
        onlyOwner
    {
        delete whiteList[adr];
    }

    function addWhiteList(address adr) external onlyOwner {
        whiteList[adr] = 1;
    }
}

contract TransferV1 is OwnableV1, WhiteListV1 {
    event ProxyDeposit(address token, address from, address to, uint256 amount);

    function proxyToken(
        address token,
        address to,
        uint256 amount
    ) public payable checkOfWhiteLists(to) {
        IERC20(token).transferFrom(msg.sender, to, amount);

        emit ProxyDeposit(token, msg.sender, to, amount);
    }
}

