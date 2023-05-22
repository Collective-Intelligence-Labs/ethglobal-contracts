pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../proto/command.proto.sol";
import "../AMMAggregate.sol";
import "../EventStore.sol";
import "../Utils.sol";


contract AddLiquidityHandler is Ownable {
    
    EventStore public eventStore;

    constructor(address eventStore_) {
        eventStore = EventStore(eventStore_);
    }

    function handle(bytes memory payload, string memory aggregateId) external
    {
        (bool success, , AddLiquidityPayload memory cmd) = AddLiquidityPayloadCodec.decode(0, payload, uint64(payload.length));
        //Aggregate aggregate = eventStore.get(aggregateId);
        AMMState state = new AMMState();
        //AMMAggregate aggregateAmm  = AMMAggregate(address(aggregate));
        //aggregateAmm.addLiquidity(cmd.amount1, cmd.amount2, cmd.account);
        //repository.save(aggregateAmm);
    }
}