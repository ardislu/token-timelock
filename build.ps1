$output = solc --standard-json ./input.json | ConvertFrom-Json
$output.contracts.'Timelock.sol'.Timelock.evm.bytecode.object | Out-File -NoNewLine ./dist/Timelock.bin
$metadata = $output.contracts.'Timelock.sol'.Timelock.metadata
$metadata | Out-File -NoNewLine ./dist/Timelock-metadata.json
$newInput = Get-Content ./input.json | ConvertFrom-Json
$newInput.sources = ($metadata | ConvertFrom-Json).sources
$newInput | ConvertTo-Json -Depth 5 | Out-File -NoNewLine ./dist/Timelock-input.json
