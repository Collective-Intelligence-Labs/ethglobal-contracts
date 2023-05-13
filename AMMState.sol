// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregateState.sol";
import "./Utils.sol";
import "./proto/command.proto.sol";
import "./proto/event.proto.sol";


contract AMMState is AggregateState, Utils {

    uint256 constant PRECISION = 1_000_000;

    bytes public token1;
    bytes public token2;
    uint256 token1Supply;
    uint256 token2Supply;

    mapping (address => uint) public shares;
    address[] shareholders;
    uint totalShares;

    mapping (address => uint256) public balance1;
    mapping (address => uint256) public balance2;
    address[] balanceOwners;

    bool public isCreated = false;
    
    function on(DomainEvent memory evnt) internal override { 

        if (evnt.evnt_type == DomainEventType.AMM_CREATED) {
            (bool success, , AMMCreatedPayload memory payload) = AMMCreatedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "AMMCreatedPayload deserialization failed");

            onCreated(payload);
        }

        if (evnt.evnt_type == DomainEventType.FUNDS_DEPOSITED) {
            (bool success, , FundsDepositedPayload memory payload) = FundsDepositedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "FundsDepositedPayload deserialization failed");

            onFundsDeposited(payload);
        }

        if (evnt.evnt_type == DomainEventType.FUNDS_WITHDRAWN) {
            (bool success, , FundsWithdrawnPayload memory payload) = FundsWithdrawnPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "FundsWithdrawnPayload deserialization failed");

            onFundsWithdrawn(payload);
        }
    }

    function onCreated(AMMCreatedPayload memory payload) private {
        token1 = payload.asset1;
        token1Supply = payload.supply1;

        token2 = payload.asset2;
        token1Supply = payload.supply2;

        totalShares = 0 * PRECISION;

        address ownerAddress = bytesToAddress(payload.owner);

        balance1[ownerAddress] = payload.supply1;
        balance2[ownerAddress] = payload.supply2;
        balanceOwners.push(ownerAddress);

        isCreated = true;
    }

    function onFundsDeposited(FundsDepositedPayload memory payload) private {
        address account = bytesToAddress(payload.account);
        
        if (compareStrings(token1, payload.asset)) {
            balance1[account] += payload.amount;
        }
        if (compareStrings(token2, payload.asset)) {
            balance2[account] += payload.amount;
        }

        if (balance1[account] == 0 && balance2[account] == 0) {
            balanceOwners.push(account);
        }
    }

    function onFundsWithdrawn(FundsWithdrawnPayload memory payload) private {
        address account = bytesToAddress(payload.account);
        
        // TODO: withdraw to account
        if (compareStrings(token1, payload.asset)) {
            balance1[account] -= payload.amount;
        }
        if (compareStrings(token2, payload.asset)) {
            balance2[account] -= payload.amount;
        }
    }

    function clear() internal override { 
        for (uint i = 0; i < shareholders.length; i++) {
            delete shares[shareholders[i]];
        }
        
        delete shareholders;
        totalShares = 0 * PRECISION;

        for (uint i = 0; i < balanceOwners.length; i++) {
            delete balance1[balanceOwners[i]];
            delete balance2[balanceOwners[i]];
        }
        
        delete balanceOwners;

        token1 = '';
        token2 = '';

        token1Supply = 0;
        token2Supply = 0;
    }

}