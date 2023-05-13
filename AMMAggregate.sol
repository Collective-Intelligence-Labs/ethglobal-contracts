// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Aggregate.sol";
import "./AMMState.sol";
import "./Utils.sol";
import "./proto/command.proto.sol";
import "./proto/event.proto.sol";


contract AMMAggregate is Aggregate, Utils {

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

        if (cmd.cmd_type == CommandType.DEPOSIT_FUNDS) {
            (bool success, , DepositFundsPayload memory payload) = DepositFundsPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "DepositFundsPayload deserialization failed");

            deposit(payload);
        }

        if (cmd.cmd_type == CommandType.WITHDRAW_FUNDS) {
            (bool success, , WithdrawFundsPayload memory payload) = WithdrawFundsPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "WithdrawFundsPayload deserialization failed");

            withdraw(payload);
        }

        if (cmd.cmd_type == CommandType.ADD_LIQUIDITY) {
            (bool success, , AddLiquidityPayload memory payload) = AddLiquidityPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "AddLiquidityPayload deserialization failed");

            addLiquidity(payload);
        }

        if (cmd.cmd_type == CommandType.REMOVE_LIQUIDITY) {
            (bool success, , RemoveLiquidityPayload memory payload) = RemoveLiquidityPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "RemoveLiquidityPayload deserialization failed");

            removeLiquidity(payload);
        }
    }

    function create(CreateAMMPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == false, "AMM already exists");

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

    function deposit(DepositFundsPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(compareStrings(s.token1(), payload.token) || compareStrings(s.token2(), payload.token), "Please deposit supported tokens");
        require(payload.amount > 0, "Not enough funds to deposit");

        FundsDepositedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount = payload.amount;
        evnt_payload.asset = payload.token;

        DomainEvent memory evnt;
        evnt.evnt_idx = eventsCount; // counter will be incremented in applyEvent
        evnt.evnt_type = DomainEventType.FUNDS_DEPOSITED;
        evnt.evnt_payload = FundsDepositedPayloadCodec.encode(evnt_payload);

        applyEvent(evnt);
    }

    function withdraw(WithdrawFundsPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(compareStrings(s.token1(), payload.token) || compareStrings(s.token2(), payload.token), "Please deposit supported tokens");
        
        address account = bytesToAddress(payload.account);
        if (compareStrings(s.token1(), payload.token)) {
            require(s.balance1(account) > payload.amount, "Not enough funds to withdraw");
        }

        if (compareStrings(s.token2(), payload.token)) {
            require(s.balance2(account) > payload.amount, "Not enough funds to withdraw");
        }

        FundsWithdrawnPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount = payload.amount;
        evnt_payload.asset = payload.token;

        DomainEvent memory evnt;
        evnt.evnt_idx = eventsCount; // counter will be incremented in applyEvent
        evnt.evnt_type = DomainEventType.FUNDS_WITHDRAWN;
        evnt.evnt_payload = FundsWithdrawnPayloadCodec.encode(evnt_payload);

        applyEvent(evnt);
    }

    function addLiquidity(AddLiquidityPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = bytesToAddress(payload.account);
        require(s.balance1(account) >= payload.amount1, "Not enough balance to add liquidity");
        require(s.balance2(account) >= payload.amount2, "Not enough balance to add liquidity");

        LiquidityAddedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount1 = payload.amount1;
        evnt_payload.amount2 = payload.amount2;

        DomainEvent memory evnt;
        evnt.evnt_idx = eventsCount; // counter will be incremented in applyEvent
        evnt.evnt_type = DomainEventType.LIQUIDITY_ADDED;
        evnt.evnt_payload = LiquidityAddedPayloadCodec.encode(evnt_payload);

        applyEvent(evnt);
    }

    function removeLiquidity(RemoveLiquidityPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = bytesToAddress(payload.account);
        require(s.shares(account) >= payload.share, "Not enough share to remove liquidity");

        // Calculate amounts when altering state
        LiquidityRemovedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.shares = payload.share;

        DomainEvent memory evnt;
        evnt.evnt_idx = eventsCount; // counter will be incremented in applyEvent
        evnt.evnt_type = DomainEventType.LIQUIDITY_REMOVED;
        evnt.evnt_payload = LiquidityRemovedPayloadCodec.encode(evnt_payload);

        applyEvent(evnt);
    }
}