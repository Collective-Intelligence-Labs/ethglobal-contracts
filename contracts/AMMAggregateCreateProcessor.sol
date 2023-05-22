// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./AMMAggregate.sol";
import "./AMMState.sol";
import "./Utils.sol";
import "./proto/event.proto.sol";


contract AMMAggregateCreateProcessor is AMMAggregate {

    constructor(string memory id_) AMMAggregate(id_) {
    }

    function create(bytes memory token1, bytes memory token2, uint64 token1_balance, uint64 token2_balance) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == false, "AMM already exists");

        AMMCreatedPayload memory evnt_payload;
        evnt_payload.asset1 = token1;
        evnt_payload.asset2 = token2;
        evnt_payload.supply1 = token1_balance;
        evnt_payload.supply2 = token1_balance;
        applyEvent(DomainEventType.AMM_CREATED, AMMCreatedPayloadCodec.encode(evnt_payload));
    }
}