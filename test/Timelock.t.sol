// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import '../Timelock.sol';
import './TestToken.sol';

// See documentation for more details and usage examples:
// https://github.com/foundry-rs/foundry/tree/master/crates/forge
interface Vm {
  function deal(address recipient, uint256 amount) external;
  function store(address contractAddr, bytes32 slot, bytes32 value) external;
  function prank(address sender) external;
  function startPrank(address sender) external;
  function stopPrank() external;
  function assume(bool) external;
  function roll(uint256 blockNumber) external;
  function expectRevert() external;
}

contract TestTimelock {
  address constant u1 = address(1);

  Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
  Timelock timelock;
  TestToken token;

  function setUp() public {
    timelock = new Timelock();
    token = new TestToken();

    // Give 100 ETH to test user
    vm.deal(u1, 100e18);

    // Give 100 ERC20 to test user
    vm.store(address(token), keccak256(abi.encodePacked(uint256(uint160(u1)), uint256(1))), bytes32(uint256(100e18)));

    // Set totalSupply
    vm.store(address(token), 0, bytes32(uint256(100e18)));
  }

  // Confirm that setUp() works
  function testSetUp() public view {
    assert(u1.balance == 100e18);
    assert(token.balanceOf(u1) == 100e18);
    assert(token.totalSupply() == 100e18);
  }

  // A deposit and immediate withdrawal should have no effect
  function testDepositWithdraw(uint256 rand) public {
    // Preconditions:
    uint256 initialAllowance = token.allowance(u1, address(timelock));
    uint256 initialBalance = token.balanceOf(u1);
    uint256 initialTimelockBalance = token.balanceOf(address(timelock));
    uint256 value = rand % initialBalance;

    // Action:
    vm.startPrank(u1);
    token.approve(address(timelock), value);
    timelock.deposit(address(token), value);
    timelock.withdraw(address(token), value);
    vm.stopPrank();

    // Postconditions:
    uint256 finalAllowance = token.allowance(u1, address(timelock));
    uint256 finalBalance = token.balanceOf(u1);
    uint256 finalTimelockBalance = token.balanceOf(address(timelock));
    assert(initialAllowance == finalAllowance);
    assert(initialBalance == finalBalance);
    assert(initialTimelockBalance == finalTimelockBalance);
  }

  // It should never be possible to withdraw before the lock has expired
  function testEarlyWithdraw(uint256 rand1, uint256 rand2) public {
    // Preconditions:
    vm.assume(rand1 > 1 && rand2 > 0);
    vm.roll(1); // Set block.number to 1
    uint256 lock = 30_000_000;
    uint256 initialBalance = token.balanceOf(u1);
    uint256 blockNumber = rand1 % lock + 2; // 1 < blockNumber < 30,000,003
    uint256 value = rand2 % initialBalance;

    // Action:
    vm.startPrank(u1);
    timelock.setTimelock(address(token), blockNumber);
    token.approve(address(timelock), value);
    timelock.deposit(address(token), value);

    vm.expectRevert();
    timelock.withdraw(address(token), value);
    vm.stopPrank();

    // Postconditions:
    uint256 finalBalance = token.balanceOf(u1);
    assert(finalBalance == initialBalance - value);
    assert(token.balanceOf(address(timelock)) == value);
  } 
  
  // It should always be possible to withdraw after the timelock has expired
  function testValidWithdraw(uint256 rand1, uint256 rand2) public {
    // Preconditions:
    vm.assume(rand1 > 1 && rand2 > 0);
    vm.roll(1);
    uint256 lock = 30_000_000;
    uint256 initialBalance = token.balanceOf(u1);
    uint256 blockNumber = rand1 % lock + 2; // 1 < blockNumber < 30,000,003
    uint256 value = rand2 % initialBalance;

    // Action:
    vm.startPrank(u1);
    timelock.setTimelock(address(token), blockNumber);
    token.approve(address(timelock), value);
    timelock.deposit(address(token), value);

    vm.roll(blockNumber + 1);
    timelock.withdraw(address(token), value);
    vm.stopPrank();

    // Postconditions:
    uint256 finalBalance = token.balanceOf(u1);
    assert(finalBalance == initialBalance);
    assert(token.balanceOf(address(timelock)) == 0);
  }

  // It should never be possible to set the timelock to a lower block number
  function testSetLowerTimelock(uint256 rand1, uint256 rand2) public {
    // Preconditions:
    vm.assume(rand2 > 1 && rand1 > rand2);
    vm.roll(1);

    // Action:
    vm.startPrank(u1);
    timelock.setTimelock(address(token), rand1);

    // Postconditions:
    vm.expectRevert();
    timelock.setTimelock(address(token), rand2);
    vm.expectRevert();
    timelock.withdraw(address(token), 0);
    vm.stopPrank();
  }
}
