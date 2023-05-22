pragma solidity >=0.8.0 <0.9.0;

import "./StateHandlersRegistery.sol";
import "./StateHandlerInvoker.sol";
import "./proto/event.proto.sol";

contract StateSpooler {

    StateHandlerInvoker invoker;
    StateHandlersRegistery registery;

    constructor (address registery_, address invoker_ ) {
        registery = StateHandlersRegistery(registery_);
        invoker = StateHandlerInvoker(invoker_);
    }

    function spool(DomainEventType event_type, bytes memory e, address state) external returns (bool success, bytes memory result) 
    {
        address handler = registery.handlers(uint256(event_type));
        bytes memory data = abi.encodeWithSignature("on(bytes,address)", e, state);
        (success, result) = handler.call(data);
    }
}