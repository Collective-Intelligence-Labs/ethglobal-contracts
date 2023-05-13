// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregateState.sol";
import "./Utils.sol";
import "./proto/command.proto.sol";
import "./proto/event.proto.sol";


contract AMMState is AggregateState, Utils {

    uint256 constant PRECISION = 1_000_000;

    address public token1;
    address public token2;

    uint256 token1Supply;
    uint256 token2Supply;

    mapping (address => uint) public shares;
    uint totalShares;
    
    function on(DomainEvent memory evnt) internal override { 

        if (evnt.evnt_type == DomainEventType.AMM_CREATED) {
            (bool success, , AMMCreatedPayload memory payload) = AMMCreatedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "AMMCreatedPayload deserialization failed");

            onCreated(payload);
        }
    }

    function onCreated(AMMCreatedPayload memory payload) private {
        token1 = bytesToAddress(payload.asset1);
        token1Supply = payload.supply1;

        token2 = bytesToAddress(payload.asset2);
        token1Supply = payload.supply2;

        totalShares = 0 * PRECISION;
    }

    function clear() internal override { 
        //delete shares;
        totalShares = 0 * PRECISION;

        token1 = address(0);
        token2 = address(0);

        token1Supply = 0;
        token2Supply = 0;
    }

}