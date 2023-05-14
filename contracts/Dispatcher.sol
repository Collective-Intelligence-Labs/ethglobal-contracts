// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CommandHandlersRegistery.sol";
import "./CommandHandlerInvoker.sol";
import "./proto/operation.proto.sol";

contract Dispatcher is Ownable {

    mapping (address => bool) public routers;
    address public registeryAddress;

    modifier onlyRouter {
        require(routers[msg.sender], "Unauthorized: transaction sender must be an authorized Router");
        _;
    }

    function addRouter(address router) public onlyOwner {
        routers[router] = true;
    }

    function setRegistery(address registery) public onlyOwner {
        registeryAddress = registery;
    }

    function removeRouter(address router) public onlyOwner {
        delete routers[router];
    }

    function dispatch(bytes memory opBytes) public onlyRouter {
        (bool success, , Operation memory operation) = OperationCodec.decode(0, opBytes, uint64(opBytes.length));
        require(success, "Operation deserialization failed");
        for (uint i = 0; i < operation.commands.length; i++) {
            CommandHandlersRegistery registery = CommandHandlersRegistery(registeryAddress);
            Command memory cmd = operation.commands[i];
            uint256 commandType = uint256(cmd.cmd_type);
            address handlerAddress = registery.handlers(commandType);
            CommandHandlerInvoker invoker = new CommandHandlerInvoker();
            invoker.invoke(handlerAddress, cmd.cmd_payload, string(cmd.aggregate_id));
        }
    }
}