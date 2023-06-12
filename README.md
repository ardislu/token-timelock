# token-timelock

Proof of concept smart contract that holds tokens until a specified block number.

Compile the smart contract creation bytecode and metadata using the helper scripts `build.ps1` (PowerShell) or `build.sh` (bash). You must have [`solc`](https://github.com/ethereum/solidity) installed.

Outputs:
- `Timelock-metadata.json`: the complete compiler settings, ABI, and source code for this smart contract. The IPFS hash for this file is encoded into the runtime bytecode. Pin this file to IPFS.
- `Timelock.bin`: the creation bytecode for this smart contract. Send a `eth_sendTransaction` request to any JSON-RPC with this bytecode as the `data` parameter to deploy this smart contract.
- `Timelock-input.json`: a copy of `input.json` with the `urls` key replaced with a `content` key containing the raw source code inlined into the JSON. This file can be used to recompile the smart contract using automated tooling.
