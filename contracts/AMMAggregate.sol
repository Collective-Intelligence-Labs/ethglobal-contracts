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
            require(success, "Deserialization failed");
            create(payload);
        }

        if (cmd.cmd_type == CommandType.DEPOSIT_FUNDS) {
            (bool success, , DepositFundsPayload memory payload) = DepositFundsPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "Deserialization failed");
            deposit(payload);
        }

        if (cmd.cmd_type == CommandType.WITHDRAW_FUNDS) {
            (bool success, , WithdrawFundsPayload memory payload) = WithdrawFundsPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "Deserialization failed");
            withdraw(payload);
        }

        if (cmd.cmd_type == CommandType.ADD_LIQUIDITY) {
            (bool success, , AddLiquidityPayload memory payload) = AddLiquidityPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "Deserialization failed");
            addLiquidity(payload);
        }

        if (cmd.cmd_type == CommandType.REMOVE_LIQUIDITY) {
            (bool success, , RemoveLiquidityPayload memory payload) = RemoveLiquidityPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "Deserialization failed");
            removeLiquidity(payload);
        }

        if (cmd.cmd_type == CommandType.SWAP) {
            (bool success, , SwapTokensPayload memory payload) = SwapTokensPayloadCodec.decode(0, cmd.cmd_payload, uint64(cmd.cmd_payload.length));
            require(success, "Deserialization failed");
            swap(payload);
        }
    }

    function createEvent(uint64 idx, DomainEventType event_type, bytes memory payload) private returns (DomainEvent memory evnt) {
        DomainEvent memory evnt;
        evnt.evnt_idx = idx;
        evnt.evnt_type = event_type;
        evnt.evnt_payload = payload;
    }

    function create(CreateAMMPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == false, "AMM already exists");

        AMMCreatedPayload memory evnt_payload;
        evnt_payload.asset1 = payload.token1;
        evnt_payload.asset2 = payload.token2;
        evnt_payload.supply1 = payload.token1_balance;
        evnt_payload.supply2 = payload.token1_balance;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.AMM_CREATED, AMMCreatedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function deposit(DepositFundsPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(compareStrings(s.token1(), payload.token) || compareStrings(s.token2(), payload.token), "Not supported token");
        require(payload.amount > 0, "Not enough funds");

        FundsDepositedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount = payload.amount;
        evnt_payload.asset = payload.token;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.FUNDS_DEPOSITED, FundsDepositedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function withdraw(WithdrawFundsPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(compareStrings(s.token1(), payload.token) || compareStrings(s.token2(), payload.token), "Not  supported token");
        
        address account = bytesToAddress(payload.account);
        if (compareStrings(s.token1(), payload.token)) {
            require(s.balance1(account) > payload.amount, "Not enough balance");
        }

        if (compareStrings(s.token2(), payload.token)) {
            require(s.balance2(account) > payload.amount, "Not enough balance");
        }

        FundsWithdrawnPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount = payload.amount;
        evnt_payload.asset = payload.token;

        
        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.FUNDS_WITHDRAWN, FundsWithdrawnPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function addLiquidity(AddLiquidityPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = bytesToAddress(payload.account);
        require(s.balance1(account) >= payload.amount1 
            && s.balance2(account) >= payload.amount2, "Not enough balance");

        LiquidityAddedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount1 = payload.amount1;
        evnt_payload.amount2 = payload.amount2;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.LIQUIDITY_ADDED, LiquidityAddedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function removeLiquidity(RemoveLiquidityPayload memory payload) private {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = bytesToAddress(payload.account);
        require(s.shares(account) >= payload.share, "Not enough share");

        // Calculate amounts when altering state
        LiquidityRemovedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.shares = payload.share;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.LIQUIDITY_REMOVED, LiquidityRemovedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function swap(SwapTokensPayload memory payload) private {
        AMMState s = AMMState(address(state));

        address account = bytesToAddress(payload.account);
        
        uint toSwapped = 0;
        bytes memory toToken;

        require(s.isCreated() == true, "AMM does not exist");
        if (compareStrings(s.token1(), payload.token)) {
            require(s.balance1(account) >= payload.amount, "Not enough token1");

            toSwapped = s.getSwapToken1Estimate(payload.amount);
            toToken = s.token2();
        }
        if (compareStrings(s.token2(), payload.token)) {
            require(s.balance2(account) >= payload.amount, "Not enough token2");
        
            toSwapped = s.getSwapToken2Estimate(payload.amount);
            toToken = s.token1();
        }
        
        TokensSwapedPayload memory evnt_payload;
        evnt_payload.account = payload.account;
        evnt_payload.amount_from = payload.amount;
        evnt_payload.asset_from = payload.token;
        evnt_payload.amount_to = uint64(toSwapped);
        evnt_payload.asset_to = toToken;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.TOKENS_SWAPPED, TokensSwapedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }
}