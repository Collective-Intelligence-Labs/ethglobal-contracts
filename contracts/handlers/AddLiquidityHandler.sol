pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../proto/command.proto.sol";
import "../AMMAggregate.sol";
import "../AggregateRepository.sol";
import "../Utils.sol";


contract CreateAMMHandler is Ownable {
    
    AggregateRepository public repository;

    constructor(address repository_) {
        repository = AggregateRepository(repository_);
    }

    function handle(bytes memory payload, string memory aggregateId) external
    {
        (bool success, , AddLiquidityPayload memory cmd) = AddLiquidityPayloadCodec.decode(0, payload, uint64(payload.length));
        Aggregate aggregate = repository.get(aggregateId);
        AMMAggregate aggregateAmm  = AMMAggregate(address(aggregate));
        aggregateAmm.addLiquidity(cmd.amount1, cmd.amount2, cmd.account);
        DomainEvent[] memory recentChanges = repository.save(aggregateAmm);
    }
}