const ganache = require('ganache-cli');
const Web3 = require('web3');
const { expect } = require('chai')
const provider = ganache.provider()
const web3 = new Web3(provider);

const { bnsInterface, bnsBytecode } = require('./compile')

/* const bnsInterface = require('./build/abi')
const bnsBytecode = fs.readFileSync('./build/bytecode.bin') */

const debug = false

let BNS, ethAccounts, ethAccountMaster;

beforeEach(async () => {
  //Grab accounts from web3 object, and set them to vars
  ethAccounts = await web3.eth.getAccounts();
  ethAccountMaster = ethAccounts[0];
  const before = await web3.eth.getBalance(ethAccountMaster)
  BNS = await deployBNS(ethAccountMaster);
  const after = await web3.eth.getBalance(ethAccountMaster)

  if (debug) console.log(
    `deployed!\n` +
    `deployment cost: ${before - after}`
  ) 
});

async function deployBNS(addressDeployer){
  _bns = await new web3.eth.Contract(JSON.parse(bnsInterface))
        .deploy({ data: bnsBytecode, arguments: [] })
        .send({ from: addressDeployer, gas: '5500000' });
   return _bns;
}

const sendTransaction = async (transaction, from, value, ...args) => {
  if (debug) console.log(
    `Sending Transaction!\n` +
    `\t${transaction}(${args.join(', ')})\n`
  )
  const before = await web3.eth.getBalance(from)
  const receipt = await BNS.methods[transaction](...args).send({ from, value, gas: 6700000 });
  const after = await web3.eth.getBalance(from)
  const { gasUsed } = receipt
  const weiSpent = before - after
  // console.log(`\t${transaction}(${args.join(', ')}) ${gasUsed}`)
  if (debug) console.log(    
    `\tgas used: ${gasUsed}\n` +
    `\twei spent: ${weiSpent}\n` +
    `\tevents\n`
  )
  if (debug && receipt.events != {}) console.log(receipt.events) //
  return {
    weiSpent,
    gasUsed,
    receipt
  }
}

const callMethod = async (method, from, ...args) => {
  // args.map(arg => typeof arg == 'string' ? encodeBytes(arg) : arg)
  // await scraper.scrapePosts('yogapants');
  return BNS.methods[method](...args).call({ from })
}

describe('Testing BNS.sol', () => {
  it('should have deployed the contract', async () => {
    expect(await BNS.options.address).ok
  })

  describe('Balance & Withdrawals', () => {
    it('should update the balance when domains are registered', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-open', true)
      const balance = await callMethod('balanceOf', ethAccounts[3]) 
      expect(balance).to.eql('5000000000000000000')
    })

    it('should withdraw funds from the contract', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-open', true)
      const {weiSpent} = await sendTransaction('withdraw', ethAccountMaster, null, '0x' + (5000000000000000000).toString(16))
      expect(Math.abs(weiSpent)).to.be.gte(900000000000000000)
    })
  })

  describe('capitalization', () => {
    it('should convert TLD to lowercase on creation', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'DMN')
      const price = await callMethod('getTldPrice', ethAccounts[1], 'dmn');
      expect(price).ok
    })

    it('should convert TLD to lowercase on lookup', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dmn')
      const price = await callMethod('getTldPrice', ethAccounts[1], 'DMN');
      expect(price).ok
    })

    it('should convert domain to lowercase on registration', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-dOmain', true)
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'trade-domain@bns')
      expect(subOwner).to.eql(ethAccounts[1])
    })

    it('should convert domain to lowercase on lookup', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-domain', true)
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'trade-dOmain@bns')
      expect(subOwner).to.eql(ethAccounts[1])
    })

    it('should convert subdomain to lowercase on registration', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-domain', true)
      await sendTransaction('registerSubdomain', ethAccounts[1], null, 'suBdomain', 'trade-doMain@bns', true)
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'subdomain.trade-domain@bns')
      expect(subOwner).to.eql(ethAccounts[1])
    })

    it('should convert subdomain to lowercase on lookup', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-domain', true)
      await sendTransaction('registerSubdomain', ethAccounts[1], null, 'subdomain', 'trade-domain@bns', true)
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'subdOmain.trade-dOmain@bns')
      expect(subOwner).to.eql(ethAccounts[1])
    })
  })

  describe('top level domain registration', () => {
    it('should create a new TLD', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dmn')
    })
  
    it('should fail to create a new TLD that already exists', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dmn')
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dmn')
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })
  
    it('should fail to create a new TLD with an invalid length', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dmnx')
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })
  
    it('should fail to create a new TLD with periods in it', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'dm.nx')
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })
  
    it('should register a domain with a new TLD', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'eth')
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-open', 'eth', true)   
    })
  })

  /* describe('top level domain pricing', () => {
    These tests don't work well with truffle because it does not support type overloading very well
    Additionally, the test here is based on an update period of 10 blocks, whereas the main contract uses 15000
    it('should retrieve the @bns price', async () => {
      const price = await callMethod('getTldPrice', ethAccounts[1], 'bns');
    })

    it('should churn through blocks and update TLD price', async () => {
      await sendTransaction('createTopLevelDomain', ethAccounts[1], null, 'chr')
      const defaultPrice = 1000000000000000000
      for(let i = 0; i < 50; i++) {
        const { receipt } = await sendTransaction('churnBlock', ethAccounts[1], null, i)
        lastBlock = receipt.blockNumber
      }
      const {weiSpent} = await sendTransaction('registerDomain', ethAccounts[1], 1000000000000000000, 'domain-priceler', 'chr', false)      
      
      expect(weiSpent).to.be.lte(defaultPrice * (3/4)**5)
    })
  }) */

  describe('domain registration', () => {
    it('should register an open domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-open', true)      
    })

    it('should register a restricted domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-closed', false)
    })

    it('should fail to register a domain with a period in it', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain.shouldfail', true)
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })

    it('should open and close public subdomain registration', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'door', false)
      let isOpen = await callMethod('isPublicDomainRegistrationOpen', ethAccounts[3], 'door@bns')
      expect(isOpen).to.eql(false)
      await sendTransaction('openPublicDomainRegistration', ethAccounts[1], null, 'door@bns')
      isOpen = await callMethod('isPublicDomainRegistrationOpen', ethAccounts[3], 'door@bns')
      expect(isOpen).to.eql(true)
      await sendTransaction('closePublicDomainRegistration', ethAccounts[1], null, 'door@bns')
      isOpen = await callMethod('isPublicDomainRegistrationOpen', ethAccounts[3], 'door@bns')
      expect(isOpen).to.eql(false)      
    })

    it('should perform a reverse lookup for an address', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'door', false)
      const domains = await callMethod('reverseLookup', ethAccounts[3], ethAccounts[2])
      expect(domains[0]).to.eql('door@bns')
    })
  })

  describe('domain cancelling', () => {
    it('should cancel a domain owned by user', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domainWillDelete', false)
      await sendTransaction('deleteDomain', ethAccounts[1], null, 'domainwilldelete@bns')
      const subOwner = await callMethod('getDomainOwner', ethAccounts[2], 'domainwilldelete@bns')
      expect(subOwner).to.eql('0x0000000000000000000000000000000000000001')
    })

    it('should forcibly remove a subdomain as domain owner', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-enforcer', true)
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'toremove', 'domain-enforcer@bns', true);
      await sendTransaction('deleteSubdomainAsDomainOwner', ethAccounts[1], null, 'toremove', 'domain-enforcer@bns');      
      const subOwner = await callMethod('getDomainOwner', ethAccounts[2], 'toremove.domain-enforcer@bns')
      expect(subOwner).to.eql('0x0000000000000000000000000000000000000001')
    })

    it('should fail to forcibly remove a subdomain with an invalid address', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'evil-enforcer', true)
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'toremove', 'evil-enforcer@bns', true);
      await sendTransaction('deleteSubdomainAsDomainOwner', ethAccounts[3], null, 'toremove', 'evil-enforcer@bns')
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })
  })

  describe('subdomain registration', () => {
    it('should register a subdomain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-opened', true)
      await sendTransaction('registerSubdomain', ethAccounts[1], null, 'subdomain', 'domain-opened@bns', true)
    })

    it('should register a domain for another user', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'to-cancel', true)
      await sendTransaction('registerSubdomainAsDomainOwner', ethAccounts[2], null, 'subdomain', 'to-cancel@bns', ethAccounts[1])
      const subOwner = await callMethod('getDomainOwner', ethAccounts[2], 'subdomain.to-cancel@bns')
      expect(subOwner).to.eql(ethAccounts[1])
    })

    it('should fail to register a subdomain with periods', async () => {
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'subd.omain', 'domain-open@bns', true)
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })
  
    it('should fail to register a subdomain on a restricted domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-closed2', false)
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'subdomain', 'domain-closed2@bns', true)
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })

    it('should approve a user for subdomain registration', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain-approval', false)
      await sendTransaction('approveForSubdomain', ethAccounts[2], null, 'domain-approval@bns', ethAccounts[3])
      await sendTransaction('registerSubdomain', ethAccounts[3], null, 'subdomain', 'domain-approval@bns', true)
    })

    it('should approve and disapprove a user for subdomain registration', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain-disapproval', false)
      await sendTransaction('approveForSubdomain', ethAccounts[2], null, 'domain-disapproval@bns', ethAccounts[3])
      await sendTransaction('disapproveForSubdomain', ethAccounts[2], null, 'domain-disapproval@bns', ethAccounts[3])
      await sendTransaction('registerSubdomain', ethAccounts[3], null, 'subdomain', 'domain-disapproval@bns', true)
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
    })

    it('should register a subsubdomain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'domain-subly', true)
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'subdomain', 'domain-subly@bns', true)
      await sendTransaction('registerSubdomain', ethAccounts[3], null, 'subsubdomain', 'subdomain.domain-subly@bns', true)
    })

    it('should fail to allow re-registration of removed domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'to-cancel', true)
      await sendTransaction('registerSubdomain', ethAccounts[2], null, 'subdomain', 'to-cancel@bns', true)
      await sendTransaction('deleteDomain', ethAccounts[2], null, 'subdomain.to-cancel@bns')
      await sendTransaction('registerSubdomainAsDomainOwner', ethAccounts[1], null, 'subdomain', 'to-cancel@bns', ethAccounts[3])
        .then((r) => { throw new Error(r) })
        .catch((e) => { if (typeof e.message !== 'string') throw e })
      const subOwner = await callMethod('getDomainOwner', ethAccounts[2], 'subdomain.to-cancel@bns')
      expect(subOwner).to.eql('0x0000000000000000000000000000000000000001')
    })
  })

  describe('domain transfer', () => {
    it('should transfer a domain from one user to another', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-domain', true)
      await sendTransaction('transferDomain', ethAccounts[1], null, 'trade-domain@bns', ethAccounts[2])
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'trade-domain@bns')
      expect(subOwner).to.eql(ethAccounts[2])
    })

    it('should transfer a subdomain from one user to another', async () => {
      await sendTransaction('registerDomain', ethAccounts[1], 5000000000000000009, 'trade-domain', true)
      await sendTransaction('registerSubdomain', ethAccounts[1], null, 'subdomain', 'trade-domain@bns', true)
      await sendTransaction('transferDomain', ethAccounts[1], null, 'subdomain.trade-domain@bns', ethAccounts[2])      
      const subOwner = await callMethod('getDomainOwner', ethAccounts[3], 'subdomain.trade-domain@bns')
      expect(subOwner).to.eql(ethAccounts[2])
    })
  })

  describe('domain storage', () => {
    it('should set and retrieve one kv pair for a domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain-storage', true)
      await sendTransaction('setDomainStorageSingle', ethAccounts[2], null, 'domain-storage@bns', 'special', 'kvpair')
      const retVal = await callMethod('getDomainStorageSingle', ethAccounts[2], 'domain-storage@bns', 'special')
      expect(retVal).to.eql('kvpair')
    })

    it('should set and retrieve many kv pairs for a domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain-storage-dos', true)
      const kvPairs = [
        ['key1', 'value1'],
        ['key16', 'value16'],
        ['hello', 'world']
      ]
      await sendTransaction('setDomainStorageMany', ethAccounts[2], null, 'domain-storage-dos@bns', kvPairs)
      const retVals = await callMethod('getDomainStorageMany', ethAccounts[2], 'domain-storage-dos@bns', ['key1', 'key16', 'hello'])
      expect(retVals).to.eql(kvPairs)
    })

    it('should set the content for a domain', async () => {
      await sendTransaction('registerDomain', ethAccounts[2], 5000000000000000009, 'domain-content-dos', true)
      await sendTransaction('setContent', ethAccounts[2], null, 'domain-content-dos@bns', '0x0000000000000000000000000000000000000001')
      const retVals = await callMethod('getContent', ethAccounts[2], 'domain-content-dos@bns')
      expect(retVals).to.eql('0x0000000000000000000000000000000000000001')
    })
  })
});
