pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../proto/event.proto.sol";
import "../../Utils.sol";
import "../../AMMState.sol";

contract LiquidityAddedHandler is Ownable {
    
    using SafeMath for uint;

    uint64 constant PRECISION = 1_000_000;

    function on(bytes memory payload, address stateAddress) external {
        (bool success, , LiquidityAddedPayload memory e) = LiquidityAddedPayloadCodec.decode(0, payload, uint64(payload.length));

        address account = Utils.bytesToAddress(e.account);
        AMMState state  = AMMState(stateAddress);

        uint share = 0;
        if(state.totalShares() == 0) { // Genesis liquidity is issued 100 Shares
            share = 100 * PRECISION;
        } else{
            uint share1 = state.totalShares().mul(e.amount1).div(state.totalToken1());
            uint share2 = state.totalShares().mul(e.amount2).div(state.totalToken2());
            require(share1 == share2, "Equivalent value of tokens not provided");
            share = share1;
        }
        require(share > 0, "Contribute more!");

        uint newBalance1 = state.balance1(account) - e.amount1;
        uint newBalance2 = state.balance2(account) - e.amount2;
        state.setBalance1(account, newBalance1);
        state.setBalance2(account, newBalance2);

        state.setTotalToken1(state.totalToken1() + e.amount1);
        state.setTotalToken2(state.totalToken2() + e.amount2);
        state.setK(state.totalToken1().mul(state.totalToken2()));

        state.setTotalShares(state.totalShares() + share);
        state.setShares(account, state.shares(account) + share);
    }
}