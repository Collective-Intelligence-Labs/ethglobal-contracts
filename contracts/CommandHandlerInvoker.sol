pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CommandHandlersRegistery.sol";

contract CommandHandlerInvoker is Ownable {

    function invoke(address handler, bytes memory cmd, string memory aggregateId) external returns (bool success, bytes memory result) 
    {
        bytes memory data = abi.encodeWithSignature("handle(bytes,uint256,string)", cmd, aggregateId);
        (success, result) = handler.call(data);
    }
}