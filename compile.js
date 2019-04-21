const path = require('path');
const fs = require('fs');
const solc = require('solc');

const input = {
   sources: {
      'BetterNameService.sol': fs.readFileSync(path.resolve(__dirname, 'contracts', 'BetterNameService.sol'), 'utf8')
   }
};

compileOutput = solc.compile(input, 1);
console.log(compileOutput.errors)
const contract = compileOutput.contracts['BetterNameService.sol:BetterNameService']
const bnsInterface = contract.interface;
const bnsBytecode = contract.bytecode;

module.exports = {
  bnsInterface,
  bnsBytecode
}
