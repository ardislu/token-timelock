$output = solc --standard-json ./input.json | ConvertFrom-Json -Depth 100
$output.contracts.'Timelock.sol'.Timelock.evm.bytecode.object | Out-File ./dist/Timelock.bin
$metadata = $output.contracts.'Timelock.sol'.Timelock.metadata
$metadata | Out-File ./dist/Timelock-metadata.json
$newInput = Get-Content ./input.json | ConvertFrom-Json -Depth 100
$newInput.sources = ($metadata | ConvertFrom-Json -Depth 100).sources
$newInput | ConvertTo-Json -Depth 100 | Out-File ./dist/Timelock-input.json
