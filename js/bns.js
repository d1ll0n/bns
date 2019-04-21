const splitDomainTld = (_domain) => {
  let domain = _domain.toLowerCase()
  const i = domain.lastIndexOf('@')
  if (!i) throw new Error('Domain string must include tld. Example: domain@tld')
  const tld = domain.slice(i + 1)
  domain = domain.slice(0, i)
  return [domain, tld]
}

const splitSubdomainDomain = (_subdomain) => {
  let subdomain = _subdomain.toLowerCase()
  const i = subdomain.lastIndexOf('.')
  if (!i) throw new Error('Subdomain string must include domain and tld. Example: subdomain.domain@tld')
  const domain = subdomain.slice(i + 1)
  subdomain = subdomain.slice(0, i)
  return [subdomain, domain]
}

module.exports = class BetterNameService {
  constructor(web3, account, abi, address) {
    this.contract = new web3.eth.Contract(abi, address)
    this.web3 = web3
    this.account = account
  }

// WEB3 FUNCTIONS

  sendTransaction(method, value, gas, ...args) {
    gas = gas || 6700000
    return this.contract.methods[method](...args).send({ from: this.account, value, gas })
      .catch(e => {
        if (e.message.indexOf('o: VM Exception while processing transaction:')) {
          throw new Error(e.message.replace('o: VM Exception while processing transaction: ', ''))
        } else throw e
      });
  }

  call(method, ...args) {
    return this.contract.methods[method](...args).call({ from: this.account })
  }

// DATA RETRIEVAL

  getTldPrice(tld) { return this.call('getTldPrice', tld.toLowerCase()) }
  reverseLookup(address) { return this.call('reverseLookup', address) }
  getDomainOwner(domain) { return this.call('getDomainOwner', domain.toLowerCase()) }
  getContent(domain) { return this.call('getContent', domain.toLowerCase()) }
  getStorage(domain, ...keys) {
    if (keys.length > 1) return this.call('getStorageMany', domain.toLowerCase(), keys)
    else return this.call('getStorageSingle', domain.toLowerCase(), keys[0])
  }
  getRegistrationStatus(domain) { return this.call('isPublicDomainRegistrationOpen', domain.toLowerCase()) }
  checkApproved(domain, address) { return this.call('isApprovedToRegister', domain.toLowerCase(), address) }

// TRANSACTION WRAPPERS

  createTopLevelDomain(tld, { gas } = {}) {
    tld = tld.toLowerCase()
    return this.sendTransaction('createTopLevelDomain', null, gas, tld)
  }

  async registerDomain(_domain, open, { gas } = {}) {
    const [domain, tld] = splitDomainTld(_domain)
    if (open == undefined) open = false
    const price = await this.getTldPrice(tld)
    return this.sendTransaction('registerDomain', price, gas, domain, tld, open)
  }

  registerSubdomain(_subdomain, open, { gas } = {}) {
    const [subdomain, domain] = splitSubdomainDomain(_subdomain)
    if (open == undefined) open = false
    return this.sendTransaction('registerSubdomain', null, gas, subdomain, domain, open)
  }

  registerSubdomainFor(_subdomain, address, open, { gas } = {}) {
    const [subdomain, domain] = splitSubdomainDomain(_subdomain)
    if (open == undefined) open = false
    return this.sendTransaction('registerSubdomainAsDomainOwner', null, gas, subdomain, domain, address)
  }

  openRegistration(domain, { gas } = {}) {
    return this.sendTransaction('openPublicDomainRegistration', null, gas, domain.toLowerCase())
  }

  closeRegistration(domain, { gas } = {}) {
    return this.sendTransaction('closePublicDomainRegistration', null, gas, domain.toLowerCase())
  }

  approveToRegister(domain, address, { gas } = {}) {
    return this.sendTransaction('approveForSubdomain', null, gas, domain.toLowerCase(), address)
  }

  disapproveToRegister(domain, address, { gas } = {}) {
    return this.sendTransaction('disapproveForSubdomain', null, gas, domain.toLowerCase(), address)
  }

  transferDomain(domain, address, { gas } = {}) {
    return this.sendTransaction('transferDomain', null, gas, domain.toLowerCase(), address)
  }

  setContent(domain, content, { gas } = {}) {
    return this.sendTransaction('setContent', null, gas, domain.toLowerCase(), content)
  }
 
  setStorage(domain, kv, { gas } = {}) {
    const keys = Object.keys(kv)
    let storage = keys.map(key => ([ key, kv[key] ]))
    if (keys.length > 1) {
      return this.sendTransaction('setDomainStorageMany', null, gas, domain, storage)
    } else {
      storage = storage[0]
      return this.sendTransaction('setDomainStorageSingle', null, gas, domain, storage[0], storage[1])
    }
  }

  deleteDomain(domain, { gas } = {}) {
    return this.sendTransaction('deleteDomain', null, gas, domain.toLowerCase())
  }

  deleteSubdomain(_subdomain, { gas } = {}) {
    const [subdomain, domain] = splitSubdomainDomain(_subdomain)
    return this.sendTransaction('deleteSubdomainAsDomainOwner', null, gas, subdomain, domain)
  }
}