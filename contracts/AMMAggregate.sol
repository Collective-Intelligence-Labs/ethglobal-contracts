// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Aggregate.sol";
import "./AMMState.sol";
import "./Utils.sol";
import "./proto/event.proto.sol";


contract AMMAggregate is Aggregate {

    constructor(string memory id_) {
        id = id_;
        state = new AMMState();
    }

    function createEvent(uint64 idx, DomainEventType event_type, bytes memory payload) private returns (DomainEvent memory evnt) {
        DomainEvent memory evnt;
        evnt.evnt_idx = idx;
        evnt.evnt_type = event_type;
        evnt.evnt_payload = payload;
    }

    function create(bytes memory token1, bytes memory token2, uint64 token1_balance, uint64 token2_balance) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == false, "AMM already exists");

        AMMCreatedPayload memory evnt_payload;
        evnt_payload.asset1 = token1;
        evnt_payload.asset2 = token2;
        evnt_payload.supply1 = token1_balance;
        evnt_payload.supply2 = token1_balance;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.AMM_CREATED, AMMCreatedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function deposit(bytes memory token, bytes memory account, uint64 amount) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(Utils.compareStrings(s.token1(), token) || Utils.compareStrings(s.token2(), token), "Not supported token");
        require(amount > 0, "Not enough funds");

        FundsDepositedPayload memory evnt_payload;
        evnt_payload.account = account;
        evnt_payload.amount = amount;
        evnt_payload.asset = token;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.FUNDS_DEPOSITED, FundsDepositedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function withdraw(bytes memory token, bytes memory accountBytes, uint64 amount) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        require(Utils.compareStrings(s.token1(), token) || Utils.compareStrings(s.token2(), token), "Not  supported token");
        
        address account = Utils.bytesToAddress(accountBytes);
        if (Utils.compareStrings(s.token1(), token)) {
            require(s.balance1(account) > amount, "Not enough balance");
        }

        if (Utils.compareStrings(s.token2(), token)) {
            require(s.balance2(account) > amount, "Not enough balance");
        }

        FundsWithdrawnPayload memory evnt_payload;
        evnt_payload.account = accountBytes;
        evnt_payload.amount = amount;
        evnt_payload.asset = token;

        
        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.FUNDS_WITHDRAWN, FundsWithdrawnPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function addLiquidity(uint64 amount1, uint64 amount2, bytes memory accountBytes) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = Utils.bytesToAddress(accountBytes);
        require(s.balance1(account) >= amount1 
            && s.balance2(account) >= amount2, "Not enough balance");

        LiquidityAddedPayload memory evnt_payload;
        evnt_payload.account = accountBytes;
        evnt_payload.amount1 = amount1;
        evnt_payload.amount2 = amount2;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.LIQUIDITY_ADDED, LiquidityAddedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function removeLiquidity(uint64 share, bytes memory accountBytes) public {
        AMMState s = AMMState(address(state));

        require(s.isCreated() == true, "AMM does not exist");
        
        address account = Utils.bytesToAddress(accountBytes);
        require(s.shares(account) >= share, "Not enough share");

        // Calculate amounts when altering state
        LiquidityRemovedPayload memory evnt_payload;
        evnt_payload.account = accountBytes;
        evnt_payload.shares = share;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.LIQUIDITY_REMOVED, LiquidityRemovedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }

    function swap(bytes memory token, bytes memory accountBytes, uint64 amount) public {
        AMMState s = AMMState(address(state));

        address account = Utils.bytesToAddress(accountBytes);
        
        uint toSwapped = 0;
        bytes memory toToken;

        require(s.isCreated() == true, "AMM does not exist");
        if (Utils.compareStrings(s.token1(), token)) {
            require(s.balance1(account) >= amount, "Not enough token1");

            toSwapped = s.getSwapToken1Estimate(amount);
            toToken = s.token2();
        }
        if (Utils.compareStrings(s.token2(), token)) {
            require(s.balance2(account) >= amount, "Not enough token2");
        
            toSwapped = s.getSwapToken2Estimate(amount);
            toToken = s.token1();
        }
        
        TokensSwapedPayload memory evnt_payload;
        evnt_payload.account = accountBytes;
        evnt_payload.amount_from = amount;
        evnt_payload.asset_from = token;
        evnt_payload.amount_to = uint64(toSwapped);
        evnt_payload.asset_to = toToken;

        DomainEvent memory evnt = createEvent(eventsCount, DomainEventType.TOKENS_SWAPPED, TokensSwapedPayloadCodec.encode(evnt_payload));
        applyEvent(evnt);
    }
}