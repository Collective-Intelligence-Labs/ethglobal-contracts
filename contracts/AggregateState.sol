// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./proto/event.proto.sol";


abstract contract AggregateState is Ownable {

    function on(DomainEvent memory evnt) internal virtual;

    function spool(DomainEvent memory evnt) external onlyOwner {
        on(evnt);
    }

    function clear() internal virtual;

    function reset() external onlyOwner {
        clear();
    }
}