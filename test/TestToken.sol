// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// Minimal ERC-20 token intended to be used in test scripts only.
/// https://github.com/ardislu/minimal-test-erc20/
contract TestToken {
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address to, uint256 value) public returns (bool success) {
    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool success) {
    allowance[from][msg.sender] -= value;
    balanceOf[from] -= value;
    balanceOf[to] += value;
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool success) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
}
