// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregateState.sol";
import "./Utils.sol";
import "./proto/event.proto.sol";


contract AMMState is AggregateState {

    using SafeMath for uint;

    bytes public token1;
    bytes public token2;
    uint public totalToken1;
    uint public totalToken2;

    uint public K;

    mapping (address => uint) public shares;
    address[] public shareholders;
    uint public totalShares;

    mapping (address => uint) public balance1;
    mapping (address => uint) public balance2;
    address[] public balanceOwners;

    bool public isCreated = false;

    function setToken1(bytes memory _token1) public {
        token1 = _token1;
    }

    function setToken2(bytes memory _token2) public {
        token2 = _token2;
    }

    function setTotalToken1(uint _totalToken1) public {
        totalToken1 = _totalToken1;
    }

    function setTotalToken2(uint _totalToken2) public {
        totalToken2 = _totalToken2;
    }

    function setK(uint _K) public {
        K = _K;
    }

    function setShares(address holder, uint _shares) public {
        shares[holder] = _shares;
    }

    function pushShareholder(address shareholder) public {
        shareholders.push(shareholder);
    }

    function setTotalShares(uint _totalShares) public {
        totalShares = _totalShares;
    }

    function setBalance1(address owner, uint _balance1) public {
        balance1[owner] = _balance1;
    }

    function setBalance2(address owner, uint _balance2) public {
        balance2[owner] = _balance2;
    }

    function pushBalanceOwner(address balanceOwner) public {
        balanceOwners.push(balanceOwner);
    }

    function setIsCreated(bool created) public {
        isCreated = created;
    }
    
    function on(DomainEvent memory evnt) internal override { 

        if (evnt.evnt_type == DomainEventType.FUNDS_DEPOSITED) {
            (bool success, , FundsDepositedPayload memory payload) = FundsDepositedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "Deserialization failed");
            onFundsDeposited(payload);
        }

        if (evnt.evnt_type == DomainEventType.FUNDS_WITHDRAWN) {
            (bool success, , FundsWithdrawnPayload memory payload) = FundsWithdrawnPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "Deserialization failed");
            onFundsWithdrawn(payload);
        }

        if (evnt.evnt_type == DomainEventType.LIQUIDITY_REMOVED) {
            (bool success, , LiquidityRemovedPayload memory payload) = LiquidityRemovedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "Deserialization failed");
            onLiquidityRemoved(payload);
        }

        if (evnt.evnt_type == DomainEventType.TOKENS_SWAPPED) {
            (bool success, , TokensSwapedPayload memory payload) = TokensSwapedPayloadCodec.decode(0, evnt.evnt_payload, uint64(evnt.evnt_payload.length));
            require(success, "Deserialization failed");
            onTokensSwapped(payload);
        }
    }

    function getTokensEstimateForShare(uint _share) public view returns(uint amountToken1, uint amountToken2) {
        require(totalShares > 0, "No liquidity");
        require(_share <= totalShares, "Share should be less than totalShare");
        
        amountToken1 = _share.mul(totalToken1).div(totalShares);
        amountToken2 = _share.mul(totalToken2).div(totalShares);
    }

    function getSwapToken1Estimate(uint _amountToken1) public view returns(uint amountToken2) {
        uint token1After = totalToken1.add(_amountToken1);
        uint token2After = K.div(token1After);
        amountToken2 = totalToken2.sub(token2After);

        // To ensure that Token2's pool is not completely depleted leading to inf:0 ratio
        if(amountToken2 == totalToken2) amountToken2--;
    }

    function getSwapToken2Estimate(uint _amountToken2) public view returns(uint amountToken1) {
        uint token2After = totalToken2.add(_amountToken2);
        uint token1After = K.div(token2After);
        amountToken1 = totalToken1.sub(token1After);

        // To ensure that Token1's pool is not completely depleted leading to inf:0 ratio
        if(amountToken1 == totalToken1) amountToken1--;
    }

    function onCreated(AMMCreatedPayload memory payload) public {
        token1 = payload.asset1;
        token2 = payload.asset2;

        address ownerAddress = Utils.bytesToAddress(payload.owner);

        balance1[ownerAddress] = payload.supply1;
        balance2[ownerAddress] = payload.supply2;
        balanceOwners.push(ownerAddress);

        isCreated = true;
    }

    function onFundsDeposited(FundsDepositedPayload memory payload) private {
        address account = Utils.bytesToAddress(payload.account);
        
        if (Utils.compareStrings(token1, payload.asset)) {
            balance1[account] += payload.amount;
        }
        if (Utils.compareStrings(token2, payload.asset)) {
            balance2[account] += payload.amount;
        }

        if (balance1[account] == 0 && balance2[account] == 0) {
            balanceOwners.push(account);
        }
    }

    function onFundsWithdrawn(FundsWithdrawnPayload memory payload) private {
        address account = Utils.bytesToAddress(payload.account);
        
        // TODO: withdraw to account
        if (Utils.compareStrings(token1, payload.asset)) {
            balance1[account] -= payload.amount;
        }
        if (Utils.compareStrings(token2, payload.asset)) {
            balance2[account] -= payload.amount;
        }
    }

    

    function onLiquidityRemoved(LiquidityRemovedPayload memory payload) private {
        address account = Utils.bytesToAddress(payload.account);
        uint _share = payload.shares;
        
        (uint amountToken1, uint amountToken2) = getTokensEstimateForShare(_share);
        
        shares[msg.sender] -= _share;
        totalShares -= _share;

        totalToken1 -= amountToken1;
        totalToken2 -= amountToken2;
        K = totalToken1.mul(totalToken2);

        balance1[account] += amountToken1;
        balance2[account] += amountToken2;
    }

    function onTokensSwapped(TokensSwapedPayload memory payload) private {
        
        address account = Utils.bytesToAddress(payload.account);
        
        // Swap from token1 to token2
        if (Utils.compareStrings(token1, payload.asset_from)) {
            balance1[account] -= payload.amount_from;
            totalToken1 += payload.amount_from;
            totalToken2 -= payload.amount_to;
            balance2[account] += payload.amount_to;
        }
        // Swap from token2 to token1
        else {
            balance2[account] -= payload.amount_from;
            totalToken2 += payload.amount_from;
            totalToken1 -= payload.amount_to;
            balance1[account] += payload.amount_to;
        }  
    }

    function clear() internal override { 
        for (uint i = 0; i < shareholders.length; i++) {
            delete shares[shareholders[i]];
        }
        delete shareholders;
        for (uint i = 0; i < balanceOwners.length; i++) {
            delete balance1[balanceOwners[i]];
            delete balance2[balanceOwners[i]];
        }
        
        delete balanceOwners;
        delete token1;
        delete token2;

        totalShares = 0;
        totalToken1 = 0;
        totalToken2 = 0;
    }

}