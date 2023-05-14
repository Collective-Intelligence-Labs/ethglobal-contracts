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
        (bool success, , WithdrawFundsPayload memory cmd) = WithdrawFundsPayloadCodec.decode(0, payload, uint64(payload.length));
        Aggregate aggregate = repository.get(aggregateId);
        AMMAggregate aggregateAmm  = AMMAggregate(address(aggregate));
        aggregateAmm.withdraw(cmd.token, cmd.account, cmd.amount);
        repository.save(aggregateAmm);
    }
}