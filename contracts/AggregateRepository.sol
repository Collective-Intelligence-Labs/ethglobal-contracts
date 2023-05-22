// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventStore.sol";
import "./Aggregate.sol";
import "./AMMAggregate.sol";


contract AggregateRepository is Ownable {

    EventStore public eventStore;
    address public dispatcher;
    address public stateSpooler;

    mapping(string => address) public aggregates;
    
    uint constant BATCH_LIMIT = 1000; // for demo purposes only

    constructor(address eventstore_, address dispatcher_, address stateSpooler_) {
        eventStore = EventStore(eventstore_);
        dispatcher = dispatcher_;
        stateSpooler = stateSpooler_;
    }

    modifier onlyDispatcher {
        require(msg.sender == dispatcher, "Unauthorized: transaction sender must be an authorized Dispatcher");
        _;
    }

    function setDispatcher(address dispatcher_) public onlyOwner {
        dispatcher = dispatcher_;
    }

    function setEventStore(address eventStore_) public onlyOwner {
        eventStore = EventStore(eventStore_);
    }

    function addAggregate(string memory id, address aggregate) public onlyOwner { // for demo purposes only
        aggregates[id] = aggregate;
    }

    function get(string memory aggregateId) external onlyDispatcher returns (Aggregate) {
        if (aggregates[aggregateId] == address(0)) {
           return Aggregate(address(0));
        }

        DomainEvent[] memory evnts = eventStore.pull(aggregateId, 0, BATCH_LIMIT);
        Aggregate aggregate = Aggregate(aggregates[aggregateId]);
        aggregate.setStateSpooler(stateSpooler);
        aggregate.setup(evnts);

        return aggregate;
    }

    function save(Aggregate aggregate) external onlyDispatcher returns (DomainEvent[] memory) {
        DomainEvent[] memory changes = new DomainEvent[](aggregate.getChangesLength());

        for (uint i = 0; i < aggregate.getChangesLength(); i++) {
            DomainEvent memory evnt = aggregate.getChange(i);
            eventStore.append(aggregate.id(), evnt);
            changes[i] = evnt;
        }

        aggregate.reset();

        return changes;
    }

}