// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Aggregate.sol";
import "./AMMState.sol";
import "./Utils.sol";
import "./proto/command.proto.sol";
import "./proto/event.proto.sol";


contract NFTsAggregate is Aggregate, Utils {

    constructor(string memory id_) {
        id = id_;
        state = new AMMState();
    }

    function handleCommand(Command memory cmd) internal override {

        if (cmd.cmd_type == CommandType.CREATE_AMM) {
            (bool success, , CreateAMMPayload memory payload) = CreateAMMPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "CreateAMMPayload deserialization failed");

            create(payload);
        }
    }

    function create(CreateAMMPayload memory payload) private {
        AMMState s = AMMState(address(state));

        address token1 = bytesToAddress(payload.token1);
        address token2 = bytesToAddress(payload.token2);

        require(s.token1() == address(0) && s.token2() == address(0), "AMM already exists");

        AMMCreatedPayload memory evnt_payload;
        evnt_payload.asset1 = payload.token1;
        evnt_payload.asset2 = payload.token2;
        evnt_payload.supply1 = payload.token1_balance;
        evnt_payload.supply2 = payload.token1_balance;

        DomainEvent memory evnt;
        evnt.evnt_idx = eventsCount; // counter will be incremented in applyEvent
        evnt.evnt_type = DomainEventType.AMM_CREATED;
        evnt.evnt_payload = AMMCreatedPayloadCodec.encode(evnt_payload);

        applyEvent(evnt);
    }
}