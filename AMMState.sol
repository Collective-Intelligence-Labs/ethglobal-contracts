// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregateState.sol";
import "./Utils.sol";
import "./proto/command.proto.sol";
import "./proto/event.proto.sol";


contract AMMState is AggregateState, Utils {

    using SafeMath for uint256;

    uint256 constant PRECISION = 1_000_000;

    bytes public token1;
    bytes public token2;
    uint256 totalToken1;
    uint256 totalToken2;

    uint256 K;

    mapping (address => uint256) public shares;
    address[] shareholders;
    uint256 totalShares;

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

        if (evnt.evnt_type == DomainEventType.LIQUIDITY_ADDED) {
            (bool success, , LiquidityAddedPayload memory payload) = LiquidityAddedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "LiquidityAddedPayload deserialization failed");

            onLiquidityAdded(payload);
        }

        if (evnt.evnt_type == DomainEventType.LIQUIDITY_REMOVED) {
            (bool success, , LiquidityRemovedPayload memory payload) = LiquidityRemovedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "LiquidityRemovedPayload deserialization failed");

            onLiquidityRemoved(payload);
        }
    }

    function getTokensEstimateForShare(uint256 _share) public view returns(uint256 amountToken1, uint256 amountToken2) {
        require(totalShares > 0, "No liquidity in pool");
        require(_share <= totalShares, "Share should be less than totalShare");
        
        amountToken1 = _share.mul(totalToken1).div(totalShares);
        amountToken2 = _share.mul(totalToken2).div(totalShares);
    }

    function onCreated(AMMCreatedPayload memory payload) private {
        token1 = payload.asset1;
        totalToken1 = 0;

        token2 = payload.asset2;
        totalToken2 = 0;

        K = totalToken1.mul(totalToken2);

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

    function onLiquidityAdded(LiquidityAddedPayload memory payload) private {
        address account = bytesToAddress(payload.account);
        uint256 share = 0;

        if(totalShares == 0) { // Genesis liquidity is issued 100 Shares
            share = 100 * PRECISION;
        } else{
            uint256 share1 = totalShares.mul(payload.amount1).div(totalToken1);
            uint256 share2 = totalShares.mul(payload.amount2).div(totalToken2);
            require(share1 == share2, "Equivalent value of tokens not provided...");
            share = share1;
        }

        require(share > 0, "Asset value less than threshold for contribution!");
        balance1[account] -= payload.amount1;
        balance2[account] -= payload.amount2;

        totalToken1 += payload.amount1;
        totalToken2 += payload.amount2;
        K = totalToken1.mul(totalToken2);

        totalShares += share;
        shares[account] += share;
    }

    function onLiquidityRemoved(LiquidityRemovedPayload memory payload) private {
        address account = bytesToAddress(payload.account);
        uint256 _share = payload.shares;
        
        (uint256 amountToken1, uint256 amountToken2) = getTokensEstimateForShare(_share);
        
        shares[msg.sender] -= _share;
        totalShares -= _share;

        totalToken1 -= amountToken1;
        totalToken2 -= amountToken2;
        K = totalToken1.mul(totalToken2);

        balance1[account] += amountToken1;
        balance2[account] += amountToken2;
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

        totalToken1 = 0;
        totalToken2 = 0;
    }

}