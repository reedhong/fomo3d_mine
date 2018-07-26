pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


contract CorpBank is Ownable {
    using SafeMath for uint256;

    event RefundValue(address, uint256 value);
    event DepositValue(address investor, uint256 value);

    address public wallet;

    constructor(address _wallet)
        public
    {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    mapping (address => uint256) public deposited;

    function deposit(address investor) public payable {
        //require(state == State.Active);
        emit DepositValue(investor, msg.value);
    }

    function setWallet(address _wallet) onlyOwner public  {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function migrationReceiver_setup() external 
        returns (bool){
        return true;
    }

    function refund(address investor) onlyOwner public {
        wallet.transfer(address(this).balance);
        emit RefundValue(wallet, address(this).balance);
    }
}
