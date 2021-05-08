// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



import "./BEP20.sol";


contract STiger is BEP20("BTCST Tiger", "STiger") {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
