// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

library Utils {

    function bytesToAddress(bytes memory data) internal pure returns (address) {
        require(data.length == 20, "Invalid address format");
        address addr;
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }

    function compareStrings(bytes memory s1, bytes memory s2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((s1))) == keccak256(abi.encodePacked((s2))));
    }
    
}