#!/bin/bash

output=$(solc --standard-json ./input.json)
echo $output | jq -r '.contracts."Timelock.sol".Timelock.evm.bytecode.object' > './dist/Timelock.bin'
metadata=$(echo $output | jq -r '.contracts."Timelock.sol".Timelock.metadata')
echo $metadata > './dist/Timelock-metadata.json'
newInput=$(cat ./input.json)
echo "$newInput" | jq --argjson newSources "$(echo $metadata | jq '.sources')" '.sources = $newSources' > './dist/Timelock-input.json'
