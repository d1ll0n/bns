const path = require('path');
const fs = require('fs');
const solc = require('solc');

const filePath = path.resolve(__dirname, 'contracts', 'BNS.sol');


const input = {

   sources: {
      'BNS.sol': fs.readFileSync(filePath, 'utf8')
   }

};

compileOutput = solc.compile(input, 1);
// console.log(compileOutput)  // <--- Try uncommenting this to see the output object!
console.log(compileOutput.errors)
module.exports = compileOutput.contracts;

