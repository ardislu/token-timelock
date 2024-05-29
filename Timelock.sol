// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title A basic ERC-20 token timelock.
/// This smart contract may be used to provably restrict access to ERC-20 tokens until a specified block number.
/// IMPORTANT: native ETH and other types of tokens, such as ERC-721, are not supported.
contract Timelock {
  /// The minimum block number before tokens can be withdrawn by owner and then by token.
  mapping(address => mapping(address => uint256)) public timelock;

  /// The current amount of tokens stored in this smart contract by owner and then by token.
  mapping(address => mapping(address => uint256)) public balance;

  /// Can't set token lock in the past. `blockNumber` must be greater than `currentBlockNumber`.
  /// @param currentBlockNumber The latest block height (`block.number`).
  /// @param blockNumber The block number provided to update the timelock.
  error BlockNumberInPast(uint256 currentBlockNumber, uint256 blockNumber);

  /// Can't set token lock below previous lock. `blockNumber` must be greater than `setBlockNumber`.
  /// @param setBlockNumber The currently set block number for this timelock.
  /// @param blockNumber The block number provided to update the timelock.
  error BlockNumberBelowPrevious(uint256 setBlockNumber, uint256 blockNumber);

  /// Unable to successfully call the ERC-20 `transferFrom` function.
  error DepositTransferFailed();

  /// The current block number is smaller than the timelock set for this owner and token.
  /// @param timelock The minimum block before tokens can be withdrawn.
  /// @param currentBlockNumber The current block number.
  error TokenLocked(uint256 timelock, uint256 currentBlockNumber);

  /// Requested withdrawal amount is too high. `amount` must be equal to or less than `balance`.
  /// @param balance The current balance for this owner and token.
  /// @param amount The requested withdrawal amount.
  error InsufficientBalance(uint256 balance, uint256 amount);

  /// Unable to successfully call the ERC-20 `transfer` function.
  error WithdrawTransferFailed();

  /// This event is emitted when a new timelock is set.
  /// @param owner The address that owns the tokens.
  /// @param token The token for which this timelock has been set.
  /// @param blockNumber The minimum block number that tokens may be withdrawn. This number may only be increased.
  event Lock(address indexed owner, address indexed token, uint256 blockNumber);

  /// This event is emitted when a user deposits new tokens into this timelock.
  /// @param owner The address sending tokens to this smart contract.
  /// @param token The ERC-20 token that is being deposited.
  /// @param amount The number of ERC-20 tokens sent to this smart contract.
  event Deposit(address indexed owner, address indexed token, uint256 amount);

  /// This event is emitted when a user withdraws tokens from this timelock.
  /// @param owner The address that previously deposited tokens into this smart contract.
  /// @param token The ERC-20 token that is being withdrawn.
  /// @param amount The number of ERC-20 tokens withdrawn from this smart contract.
  event Withdraw(address indexed owner, address indexed token, uint256 amount);

  /// Set a timelock which provably restricts access to a token.
  /// @param token The token to restrict withdrawals for.
  /// @param blockNumber The minimum block number that must be passed before tokens may be withdrawn.
  function setTimelock(address token, uint256 blockNumber) external {
    if (block.number >= blockNumber) {
      revert BlockNumberInPast(block.number, blockNumber);
    }
    if (timelock[msg.sender][token] >= blockNumber) {
      revert BlockNumberBelowPrevious(timelock[msg.sender][token], blockNumber);
    }
    timelock[msg.sender][token] = blockNumber;
    emit Lock(msg.sender, token, blockNumber);
  }

  /// Send tokens to this smart contract for locking up.
  /// IMPORTANT: Tokens MUST be deposited via this function ONLY or else they will not be able to be withdrawn!
  /// @param token The ERC-20 token to transfer to this smart contract. This smart contract must be approved to call
  /// `transferFrom` on the ERC-20 to move tokens.
  /// @param amount The number of tokens to transfer to this smart contract.
  function deposit(address token, uint256 amount) external {
    ERC20 erc20 = ERC20(token);
    bool success = erc20.transferFrom(msg.sender, address(this), amount);
    if (!success) {
      revert DepositTransferFailed();
    }

    balance[msg.sender][token] += amount;

    emit Deposit(msg.sender, token, amount);
  }

  /// Withdraw tokens which were previously deposited via `deposit`.
  /// @param token The ERC-20 token which was previously deposited into this smart contract.
  /// @param amount The number of tokens to withdraw from this smart contract.
  function withdraw(address token, uint256 amount) external {
    if (timelock[msg.sender][token] > block.number) {
      revert TokenLocked(timelock[msg.sender][token], block.number);
    }
    if (amount > balance[msg.sender][token]) {
      revert InsufficientBalance(balance[msg.sender][token], amount);
    }

    balance[msg.sender][token] -= amount;

    ERC20 erc20 = ERC20(token);
    bool success = erc20.transfer(msg.sender, amount);
    if (!success) {
      revert WithdrawTransferFailed();
    }

    emit Withdraw(msg.sender, token, amount);
  }
}
