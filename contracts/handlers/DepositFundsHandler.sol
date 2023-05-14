pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../proto/command.proto.sol";
import "../AMMAggregate.sol";
import "../AggregateRepository.sol";
import "../Utils.sol";


contract DepositFundsHandler is Ownable {
    
    AggregateRepository public repository;

    constructor(address repository_) {
        repository = AggregateRepository(repository_);
    }

    function handle(bytes memory payload, string memory aggregateId) external
    {
        (bool success, , DepositFundsPayload memory cmd) = DepositFundsPayloadCodec.decode(0, payload, uint64(payload.length));
        Aggregate aggregate = repository.get(aggregateId);
        AMMAggregate aggregateAmm  = AMMAggregate(address(aggregate));
        aggregateAmm.deposit(cmd.token, cmd.account, cmd.amount);
        repository.save(aggregateAmm);
    }
}