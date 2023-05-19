// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/* 
    Deployment:
    - Optimizator   unabled: 283972 gas
 	                enabled: 172786 gas
*/
contract Owner {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // sol: 2319 gas
    function getOwner() external view returns (address) {
        return owner;
    }

    function setOwner(address wallet) external onlyOwner returns (address) {
        owner = wallet;
        return owner;
    }
}

contract WhiteList is Owner {
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

contract Transfer is Owner, WhiteList {
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
