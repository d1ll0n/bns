const ganache = require('ganache-cli');
const Web3 = require('web3');
const { expect } = require('chai')
const provider = ganache.provider()
const web3 = new Web3(provider);
const BNS = require('./bns')

const { bnsInterface, bnsBytecode } = require('../compile')
const abi = JSON.parse(bnsInterface)
// fs.writeFileSync('./abi.json', abi)

let bns, ethAccounts, ethAccountMaster;

async function deployBNS(addressDeployer) {
  return new web3.eth.Contract(abi)
    .deploy({ data: bnsBytecode, arguments: [] })
    .send({ from: addressDeployer, gas: '5500000' })
}

beforeEach(async () => {
  ethAccounts = await web3.eth.getAccounts();
  ethAccountMaster = ethAccounts[0];
  const contract = await deployBNS(ethAccountMaster);
  bns = new BNS(web3, ethAccountMaster, abi, contract.address)
})

describe('Testing BNS.js', () => {
  describe('top level domain creation', () => {
    it('should create a new TLD', async () => {
      await bns.createTopLevelDomain('dmn')
      const price = await bns.getTldPrice('dmn')
      expect(price).to.eql('5000000000000000000')
    })
  })

  describe('lookup', () => {
    it('should lookup the owner of a domain', async () => {
      await bns.registerDomain('domain@bns')
      const owner = await bns.getDomainOwner('domain@bns')
      expect(owner).to.eql(ethAccountMaster)
    })

    it('should lookup the owner of a subdomain', async () => {
      await bns.registerDomain('domain@bns')
      await bns.registerSubdomain('subdomain.domain@bns')
      expect(await bns.getDomainOwner('domain@bns')).to.eql(ethAccountMaster)
      expect(await bns.getDomainOwner('subdomain.domain@bns')).to.eql(ethAccountMaster)
    })

    it('should lookup domains owned by an address', async () => {
      await bns.registerDomain('cooldomain@bns')
      await bns.registerSubdomain('coolsubdomain.cooldomain@bns')
      const domains = await bns.reverseLookup(ethAccountMaster)
      expect(JSON.stringify(domains)).to.eql(JSON.stringify(['cooldomain@bns', 'coolsubdomain.cooldomain@bns']))
    })
  })

  describe('domain registration', () => {
    it('should register a domain', async () => {
      await bns.registerDomain('domain@bns')
      const owner = await bns.getDomainOwner('domain@bns')
      expect(owner).to.eql(ethAccountMaster)
    })

    it('should register a subdomain', async () => {
      await bns.registerDomain('domain@bns')
      await bns.registerSubdomain('subdomain.domain@bns')
      const owner = await bns.getDomainOwner('subdomain.domain@bns')
      expect(owner).to.eql(ethAccountMaster)
    })
  
    it('should register a domain with a new TLD', async () => {
      await bns.createTopLevelDomain('dmn')
      await bns.registerDomain('domain@dmn')
      const owner = await bns.getDomainOwner('domain@dmn')
      expect(owner).to.eql(ethAccountMaster)
    })
  })

  describe('registration rules', async () => {
    it('should check if a domain has open registration', async () => {
      await bns.registerDomain('domain@bns', false)
      const isOpen = await bns.getRegistrationStatus('domain@bns')
      expect(isOpen).to.eql(false)
    })

    it('should check if a user is approved to register a subdomain', async () => {
      await bns.registerDomain('domain@bns', false)
      const isApproved = await bns.checkApproved('domain@bns', ethAccounts[1])
      expect(isApproved).to.eql(false)
    })

    it('should approve a user', async () => {
      await bns.registerDomain('domain@bns', false)
      await bns.approveToRegister('domain@bns', ethAccounts[1])
      const isApproved = await bns.checkApproved('domain@bns', ethAccounts[1])
      expect(isApproved).to.eql(true)
    })

    it('should disapprove a user', async () => {
      await bns.registerDomain('domain@bns', false)
      await bns.disapproveToRegister('domain@bns', ethAccounts[1])
      const isApproved = await bns.checkApproved('domain@bns', ethAccounts[1])
      expect(isApproved).to.eql(false)
    })
  })
})

