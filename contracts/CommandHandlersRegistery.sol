pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommandHandlersRegistery is Ownable {

    mapping(uint256 => address) public handlers;

    function setHandler(uint256 commandType, address handler) public onlyOwner {
        handlers[commandType] = handler;
    }
}