pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../proto/command.proto.sol";
import "../AMMAggregateCreateProcessor.sol";
import "../AggregateRepository.sol";
import "../Utils.sol";


contract CreateAMMHandler is Ownable {
    
    AggregateRepository public repository;

    constructor(address repository_) {
        repository = AggregateRepository(repository_);
    }

    function handle(bytes memory payload, string memory aggregateId) external
    {
        (bool success, , CreateAMMPayload memory cmd) = CreateAMMPayloadCodec.decode(0, payload, uint64(payload.length));
        Aggregate aggregate = repository.get(aggregateId);
        AMMAggregateCreateProcessor aggregateAmm  = AMMAggregateCreateProcessor(address(aggregate));
        aggregateAmm.create(cmd.token1, cmd.token2, cmd.token1_balance, cmd.token2_balance);
        repository.save(aggregateAmm);
    }
}