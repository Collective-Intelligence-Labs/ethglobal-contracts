pragma solidity >=0.8.0 <0.9.0;

contract StateHandlerInvoker {

    function invoke(address handler, bytes memory cmd, address state) external returns (bool success, bytes memory result) 
    {
        bytes memory data = abi.encodeWithSignature("on(bytes,address)", cmd, state);
        (success, result) = handler.call(data);
    }
}