pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../proto/event.proto.sol";
import "../../Utils.sol";
import "../../AMMState.sol";

contract FundsWithdrawnHandler is Ownable {

    function on(bytes memory payload, address stateAddress) external {
        (bool success, , FundsDepositedPayload memory e) = FundsDepositedPayloadCodec.decode(0, payload, uint64(payload.length));

        address account = Utils.bytesToAddress(e.account);
        AMMState state  = AMMState(stateAddress);
        
        // TODO: withdraw to account
        if (Utils.compareStrings(state.token1(), e.asset)) {
            require(state.balance1(account) - e.amount >= 0, "Not enough funds");
            state.setBalance1(account, state.balance1(account) - e.amount);
        }
        if (Utils.compareStrings(state.token2(), e.asset)) {
            require(state.balance2(account) - e.amount >= 0, "Not enough funds");
            state.setBalance2(account, state.balance2(account) - e.amount);
        }
    }
}