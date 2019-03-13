const path = require('path');
const fs = require('fs');
const solc = require('solc');

const input = {
   sources: {
      'BetterNameService.sol': fs.readFileSync(path.resolve(__dirname, 'contracts', 'BetterNameService.sol'), 'utf8')
   }
};

compileOutput = solc.compile(input, 1);
const contract = compileOutput.contracts['BetterNameService.sol:BetterNameService']
const bnsInterface = contract.interface;
const bnsBytecode = contract.bytecode;
fs.writeFileSync('build/abi.json', bnsInterface)
fs.writeFileSync('build/bytecode.bin', bnsBytecode)
