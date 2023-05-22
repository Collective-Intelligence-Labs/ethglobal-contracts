// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AggregateState.sol";
import "./proto/event.proto.sol";
import "./StateSpooler.sol";

abstract contract Aggregate is Ownable {

    string public id;
    AggregateState public state;
    DomainEvent[] changes;
    bool isReady;
    uint64 eventsCount;
    StateSpooler spooler;

    function setStateSpooler(address spooler_) public {
        spooler = StateSpooler(spooler_);
    }

    function applyEvent(DomainEvent memory evnt) internal {
        spooler.spool(evnt.evnt_type, evnt.evnt_payload, address(state));
        eventsCount++;
        changes.push(evnt);
    }

    function getChangesLength() external view returns (uint256)  {
        return changes.length;
    }

    function getChange(uint i) external view returns (DomainEvent memory)  {
        return changes[i];
    }

    function setup(DomainEvent[] memory evnts) external onlyOwner {
        for (uint i = 0; i < evnts.length; i++) {
            spooler.spool(evnts[i].evnt_type, evnts[i].evnt_payload, address(state));
            eventsCount++;
        }
        isReady = true;
    }

    function reset() external onlyOwner {
        state.reset();
        eventsCount = 0;
        delete changes;
        isReady = false;
    }

}