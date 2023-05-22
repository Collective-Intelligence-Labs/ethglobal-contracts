pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../proto/event.proto.sol";
import "../../Utils.sol";
import "../../AMMState.sol";


contract AMMCreatedHandler is Ownable {
    
    function on(bytes memory payload, address stateAddress) external
    {
        (bool success, , AMMCreatedPayload memory e) = AMMCreatedPayloadCodec.decode(0, payload, uint64(payload.length));

        AMMState state  = AMMState(stateAddress);
        state.setToken1(e.asset1);
        state.setToken2(e.asset2);

        address ownerAddress = Utils.bytesToAddress(e.owner);

        state.setBalance1(ownerAddress, e.supply1);
        state.setBalance2(ownerAddress, e.supply2);
        state.pushBalanceOwner(ownerAddress);

        state.setIsCreated(true);
    }
}