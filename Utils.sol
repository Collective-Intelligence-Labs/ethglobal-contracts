// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

abstract contract Utils {

    function bytesToAddress(bytes memory data) internal pure returns (address) {
        require(data.length == 20, "Invalid address format");
        address addr;
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }
    
}