// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Aggregate.sol";
import "./AggregateRepository.sol";
import "./proto/operation.proto.sol";


contract Dispatcher is Ownable {

    mapping (address => bool) public routers;
    address public repository;
    bool isLocked;

    event OmnichainEvent(uint64 indexed _idx, DomainEventType indexed _type, bytes _payload);

    modifier onlyRouter {
        require(routers[msg.sender], "Unauthorized: transaction sender must be an authorized Router");
        _;
    }

    modifier noReentrancy() {
        require(!isLocked, "Reentrancy call is not allowed");
        isLocked = true;
        _;
        isLocked = false;
    }

    function setRepository(address repository_) public onlyOwner {
        repository = repository_;
    }

    function addRouter(address router) public onlyOwner {
        routers[router] = true;
    }

    function removeRouter(address router) public onlyOwner {
        delete routers[router];
    }

    function dispatch(bytes memory opBytes) public onlyRouter noReentrancy {
        require(address(repository) != address(0), "AggregateRepository is not set");

        (bool success, , Operation memory operation) = OperationCodec.decode(0, opBytes, uint64(opBytes.length));
        require(success, "Operation deserialization failed");
        
        for (uint i = 0; i < operation.commands.length; i++) {
            // todo: check cmd author signature
            Aggregate aggregate = AggregateRepository(repository).get(string(operation.commands[i].aggregate_id));
            aggregate.handle(operation.commands[i]);

            DomainEvent[] memory recentChanges = AggregateRepository(repository).save(aggregate);
            for (uint j = 0; j < recentChanges.length; j++) {
                DomainEvent memory recentChange = recentChanges[j];
                emit OmnichainEvent(recentChange.evnt_idx, recentChange.evnt_type, DomainEventCodec.encode(recentChange));
            }
        }
    }

}