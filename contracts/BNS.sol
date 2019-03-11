pragma solidity ^0.4.25;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

/* import "./lib/SafeMath.sol";
import "./lib/StringHelper.sol";
import "./lib/BnsLib.sol"; */
library BnsLib {
  /*<BEGIN STRUCTS>*/
  struct TopLevelDomain {
    uint price;
    uint lastUpdate;
    bool min;
    bool exists;
  }
  /*</END STRUCTS>*/
  
  /*<BEGIN MODIFIERS>*/
  function hasOnlyAllowedCharacters(string memory str) internal pure returns (bool) {
    /* [9-0] [@] [A-Z] [a-z] [.] */
    bytes memory b = bytes(str);
    for(uint i; i<b.length; i++){
      bytes1 char = b[i];
      if(! (
        (char >= 0x30 && char <= 0x39) ||
        (char >= 0x41 && char <= 0x5A) ||
        (char >= 0x61 && char <= 0x7A) ||
        (char == 0x2E || char == 0x40)
      )) return false;
    }
    return true;
  }

  function hasOnlyDomainLevelCharacters(string memory str) internal pure returns (bool) {
    /* [9-0] [A-Z] [a-z] [-] */
    bytes memory b = bytes(str);
    for(uint i; i<b.length; i++) {
      bytes1 char = b[i];
      if (! (
        (char >= 0x30 && char <= 0x39) ||
        (char >= 0x41 && char <= 0x5A) ||
        (char >= 0x61 && char <= 0x7A) ||
        (char == 0x2d)
      )) return false;
    }
    return true;
  }
  /*</END MODIFIERS>*/
  
}

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library StringHelper {
  uint internal constant WORD_SIZE = 32;
 // string internal constant period = ".";
  bytes1 internal constant period = ".";
  bytes1 internal constant atSign = "@";

  function copy(uint src, uint dest, uint len) internal pure {
    // Copy word-length chunks while possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += WORD_SIZE;
      src += WORD_SIZE;
    }

    // Copy remaining bytes
    uint mask = 256 ** (WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
    len = bts.length;
    assembly {
      addr := add(bts, /*BYTES_HEADER_SIZE*/32)
    }
  }

  function concat(bytes memory sel, bytes memory other) internal pure returns (bytes memory) {
    bytes memory ret = new bytes(sel.length + other.length);
    (uint src, uint srcLen) = fromBytes(sel);
    (uint src2, uint src2Len) = fromBytes(other);
    (uint dest,) = fromBytes(ret);
    uint dest2 = dest + src2Len;
    copy(src, dest, srcLen);
    copy(src2, dest2, src2Len);
    return ret;
  }

  function decimalJoin(string memory self, string memory s2) internal pure returns (string memory) {
    /* [9-0] [A-Z] [a-z] [-] */
    bytes memory orig = bytes(self);
    bytes memory addStr = bytes(s2);
    uint retSize = orig.length + addStr.length + 1;
    bytes memory ret = new bytes(retSize);
    for (uint i = 0; i < orig.length; i ++) {
      require(
        (orig[i] >= 0x30 && orig[i] <= 0x39) ||
        (orig[i] >= 0x41 && orig[i] <= 0x5A) ||
        (orig[i] >= 0x61 && orig[i] <= 0x7A) ||
        (orig[i] == 0x2d),
        "Invalid character."
      );
      if (orig[i] >= 0x41 && orig[i] <= 0x5A) ret[i] = bytes1(uint8(orig[i]) + 0x20);
      else ret[i] = orig[i];
    }
    ret[orig.length] = period;
    for (uint i = 0; i < addStr.length; i ++) {
      if (addStr[i] >= 0x41 && addStr[i] <= 0x5A) ret[orig.length + i + 1] = bytes1(uint8(addStr[i]) + 0x20);
      else ret[orig.length + i + 1] = addStr[i];
    }
    return string(ret);
  }

  function toLowercase(string memory self) internal pure returns(string memory) {
    bytes memory b = bytes(self);
    bytes memory ret = new bytes(b.length);
    for (uint i = 0; i < b.length; i ++) {
      if (b[i] >= 0x41 && b[i] <= 0x5A) ret[i] = bytes1(uint8(b[i]) + 0x20);
      else ret[i] = b[i];
    }
    return string(ret);
  }

  function atJoin(string memory self, string memory s2) internal pure returns (string memory) {
    /* [9-0] [A-Z] [a-z] [-] */
    bytes memory orig = bytes(self);
    bytes memory addStr = bytes(s2);
    uint retSize = orig.length + addStr.length + 1;
    bytes memory ret = new bytes(retSize);
    for (uint i = 0; i < orig.length; i ++) {
      require(
        (orig[i] >= 0x30 && orig[i] <= 0x39) ||
        (orig[i] >= 0x41 && orig[i] <= 0x5A) ||
        (orig[i] >= 0x61 && orig[i] <= 0x7A) ||
        (orig[i] == 0x2d),
        "Invalid character."
      );
      ret[i] = orig[i];
    }
    ret[orig.length] = atSign;
    for (uint i = 0; i < addStr.length; i ++) {
      if (addStr[i] >= 0x41 && addStr[i] <= 0x5A) ret[orig.length + i + 1] = bytes1(uint8(addStr[i]) + 0x20);
      else ret[orig.length + i + 1] = addStr[i];
    }
    return string(ret);
  }
}


contract BNS {
/*----------------<BEGIN IMPORTS>----------------*/
  using BnsLib for *;
  using SafeMath for uint;
  using StringHelper for string;
/*----------------</END IMPORTS>----------------*/
  


  constructor() public {
    createTopLevelDomain("bns");
    creat0r = msg.sender;
  }
  

  
/*----------------<BEGIN CONSTANTS>----------------*/
  address creat0r;  
  uint updateAfter = 15000; // target around 1 update per day
  uint minPrice = 10000000000000000; // 0.01 eth
/*----------------</END CONSTANTS>----------------*/



/*----------------<BEGIN GLOBALS>----------------*/
  mapping(string => BnsLib.TopLevelDomain) internal tldPrices;

  mapping(string => address) domains; // domain and subdomain owners  
  mapping(string => bool) openDomains; // domain allows subdomains to be registered by anyone
  mapping(string => mapping(address => bool)) domainApprovals; // addresses approved to register subdomains

  mapping(string => address) emails; // email addr owners
  mapping(string => bool) openEmail; // domain allows emails to be registered
  mapping(string => mapping(address => bool)) emailApprovals; // addresses approved to register email addresses

  mapping(string => mapping(string => string)) domainStorage; // kv store per domain
  mapping(string => bytes) contentHashes;
/*----------------</END GLOBALS>----------------*/



/*----------------<BEGIN ACCOUNT FUNCTIONS>----------------*/
  function withdraw(uint amount) public {
    require(msg.sender == creat0r, "Only the creat0r can call that.");
    msg.sender.transfer(amount);
  }

  function balanceOf() public view returns (uint) {
    return address(this).balance;
  }
/*----------------</END ACCOUNT FUNCTIONS>*----------------/



/*----------------<BEGIN MODIFIERS>----------------*/
  modifier tldExists(string memory tld) {
    require(tldPrices[tld].exists, "TLD does not exist");
    _;
  }

  modifier tldNotExists(string memory tld) {
    require(!tldPrices[tld].exists, "TLD exists");
    _;
  }

  modifier domainExists(string memory domain) {
    require(
      domains[domain] != address(0) &&
      domains[domain] != address(0x01), "Domain does not exist or has been invalidated.");
    _;
  }

  modifier domainNotExists(string memory domain) {
    require(domains[domain] == address(0), "Domain exists");
    _;
  }

  modifier emailExists(string memory email) {
    require(
      emails[email] != address(0) &&
      emails[email] != address(0x01),
      "Email does not exist"
    );
    _;
  }

  modifier emailNotExists(string memory email) {
    require(emails[email] == address(0), "Email exists");
    _;
  }

  modifier onlyDomainOwner(string memory domain) {
    require(msg.sender == domains[domain], "Not owner of domain");
    _;
  }

  modifier onlyAllowed(string memory domain) {
    require(
      openDomains[domain] ||
      domains[domain] == msg.sender ||
      domainApprovals[domain][msg.sender],
      "Not allowed to register subdomain."
    );
    _;
  }

  modifier onlyEmailAllowed(string memory domain) {
    require(
      openEmail[domain] ||
      domains[domain] == msg.sender ||
      emailApprovals[domain][msg.sender],
      "Not allowed to register email."
    );
    _;
  }

  modifier onlyEmailOwner(string memory email) {
    require(msg.sender == emails[email], "Not owner of email");
    _;
  }

  modifier onlyDomainLevelCharacters(string memory domainLevel) {
    require(BnsLib.hasOnlyDomainLevelCharacters(domainLevel), "Invalid characters");
    _;
  }

  modifier isLowercase(string memory str) {
    str = str.toLowercase();
    _;
  }
/*----------------</END MODIFIERS>----------------*/



/*----------------<BEGIN EVENTS>----------------*/
  /*<BEGIN DOMAIN EVENTS>*/
  event TopLevelDomainCreated(bytes32 indexed tldHash, string tld);
  event TopLevelDomainPriceUpdated(bytes32 indexed tldHash, string tld, uint newPrice);

  event DomainRegistered(bytes32 indexed domainHash, string domain, address owner, address registeredBy, bool open);
  event SubdomainInvalidated(bytes32 indexed subdomainHash, string subdomain, address invalidatedBy);

  event DomainRegistrationOpened(bytes32 indexed domainHash, string domain);
  event DomainRegistrationClosed(bytes32 indexed domainHash, string domain);

  event ApprovedForDomain(bytes32 indexed domainHash, string domain, address indexed approved);
  event DisapprovedForDomain(bytes32 indexed domainHash, string domain, address indexed disapproved);

  event ContentHashUpdated(bytes32 indexed domainHash, string domain, bytes contentHash);
  /*</END DOMAIN EVENTS>*/


  /*<BEGIN EMAIL EVENTS>*/
  event EmailRegistered(bytes32 indexed emailHash, string email, address indexed owner);

  event EmailRegistrationOpened(bytes32 indexed domainHash, string domain);
  event EmailRegistrationClosed(bytes32 indexed domainHash, string domain);

  event EmailInvalidated(bytes32 indexed emailHash, string email, address indexed invalidatedBy);
  event ApprovedForEmail(bytes32 indexed domainHash, string domain, address indexed approved);
  event DisapprovedForEmail(bytes32 indexed domainHash, string domain, address indexed approved);
  /*</END EMAIL EVENTS>*/
/*----------------</END EVENTS>----------------*/



/*----------------<BEGIN VIEW FUNCTIONS>----------------*/
  function getTldPrice(string tld) public view returns (uint) {
    return tldPrices[tld].min ? minPrice : tldPrices[tld].price;
  }

  function expectedTldPrice(string tld) public view returns (uint) {
    if (tldPrices[tld].min) return minPrice;
    if (block.number - tldPrices[tld].lastUpdate >= updateAfter) {
      uint blockCount = block.number - tldPrices[tld].lastUpdate;
      uint updatesDue = blockCount / updateAfter;
      uint newPrice = tldPrices[tld].price.mul(750**updatesDue).div(1000**updatesDue);
      if (newPrice <= minPrice) return minPrice;
      else return newPrice;
    }
    return tldPrices[tld].price;
  }

  function getDomainOwner(string domain) public view returns (address) {
    return domains[domain];
  }

  function isPublicDomainRegistrationOpen(string domain) public view returns (bool) {
    return openDomains[domain];
  }
  
  function isApprovedToRegister(string domain, address addr) public view domainExists(domain) returns (bool) {
    return openDomains[domain] || domains[domain] == addr || domainApprovals[domain][addr];
  }

  function isDomainInvalidated(string domain) public view returns(bool) {
    return domains[domain] == address(0x01);
  }

  function getContentHash(string memory domain) public view returns (bytes) {
    return contentHashes[domain];
  }


  /*<BEGIN STORAGE FUNCTIONS>*/
  function getDomainStorageSingle(string domain, string key) public view domainExists(domain) returns (string) {
    return domainStorage[domain][key];
  }

  function getDomainStorageMany(string domain, string[] memory keys) public view domainExists(domain) returns (string[2][]) {
    string[2][] memory results = new string[2][](keys.length);
    for(uint i = 0; i < keys.length; i++) {
      string memory key = keys[i];
      results[i] = [key, domainStorage[domain][key]];
    }
    return results;
  }
  /*</END STORAGE FUNCTIONS>*/
/*----------------</END VIEW FUNCTIONS>----------------*/



/*----------------<BEGIN UTILITY FUNCTIONS>----------------*/
  function returnRemainder(uint price) internal {
    if (msg.value > price) msg.sender.transfer(msg.value - price);
  }

  function updatedTldPrice(string tld) internal returns (uint) {
    if (!tldPrices[tld].min) {
      // tld price has not reached the minimum price
      if (block.number - tldPrices[tld].lastUpdate >= updateAfter) {
        // tld price is due for an update
        uint blockCount = block.number - tldPrices[tld].lastUpdate;
        uint updatesDue = blockCount / updateAfter;
        uint newPrice = tldPrices[tld].price.mul(750**updatesDue).div(1000**updatesDue);
        if (newPrice <= minPrice) {
          tldPrices[tld].min = true;
          tldPrices[tld].price = 0;
          tldPrices[tld].lastUpdate = 0;
          emit TopLevelDomainPriceUpdated(keccak256(abi.encode(tld)), tld, minPrice);
          return minPrice;
        } else {
          tldPrices[tld].price = newPrice;
          tldPrices[tld].lastUpdate = block.number.sub(blockCount % updateAfter);
          emit TopLevelDomainPriceUpdated(keccak256(abi.encode(tld)), tld, tldPrices[tld].price);          
        }
      }
    }
    return tldPrices[tld].price;
  }
/*----------------</END UTILITY FUNCTIONS>----------------*/


  
/*----------------<BEGIN EMAIL FUNCTIONS>----------------*/
  function _registerEmail(string memory email) internal emailNotExists(email) {
    emails[email] = msg.sender;
    emit EmailRegistered(keccak256(abi.encode(email)), email, msg.sender);
  }

  function registerEmail(string memory username, string memory domain) 
  public onlyEmailAllowed(domain) {
    string memory checkSubdomain = username.decimalJoin(domain);
    require(
      domains[checkSubdomain] == address(0) ||
      domains[checkSubdomain] == msg.sender,
      "Can not register an email with same username as an existing subdomain unless you own the subdomain."
    );
    _registerEmail(username.atJoin(domain));
  }

  function openEmailRegistration(string memory domain) 
  public onlyDomainOwner(domain) {
    openEmail[domain] = true;
    emit EmailRegistrationOpened(keccak256(abi.encode(domain)), domain);
  }

  function closeEmailRegistration(string memory domain) 
  public onlyDomainOwner(domain) {
    openEmail[domain] = false;
    emit EmailRegistrationClosed(keccak256(abi.encode(domain)), domain);
  }

  function invalidateEmail(string memory email) 
  public onlyEmailOwner(email) {
    emails[email] = address(0x01);
  }

  function invalidateEmailAsDomainOwner(string memory username, string memory domain) 
  public onlyDomainOwner(domain) {
    string memory email = username.atJoin(domain);
    emails[email] = address(0x01);
    emit EmailInvalidated(keccak256(abi.encode(email)), email, msg.sender);
  }

  function getEmailOwner(string memory email)
  public view isLowercase(email) returns(address) {
    return emails[email];
  }

  // get it? because it's for e-mail (so it's like regular mail, where they use stamps)
  function stampOfApproval(string memory domain, address approved) 
  public  onlyDomainOwner(domain) {
    emailApprovals[domain][approved] = true;
    emit ApprovedForEmail(keccak256(abi.encode(domain)), domain, approved);
  }

  function stampOfDisapproval(string memory domain, address disapproved) 
  public onlyDomainOwner(domain) {
    emailApprovals[domain][disapproved] = false;
    emit ApprovedForEmail(keccak256(abi.encode(domain)), domain, disapproved);
  }
/*----------------</END EMAIL FUNCTIONS>----------------*/



/*----------------<BEGIN DOMAIN REGISTRATION FUNCTIONS>----------------*/
  /*<BEGIN TLD FUNCTIONS>*/
  function createTopLevelDomain(string memory tld) 
  public isLowercase(tld) tldNotExists(tld) onlyDomainLevelCharacters(tld) {
    tldPrices[tld] = BnsLib.TopLevelDomain({
      price: 5000000000000000000,
      lastUpdate: block.number,
      exists: true,
      min: false
    });
    emit TopLevelDomainCreated(keccak256(abi.encode(tld)), tld);
  }
  /*</END TLD FUNCTIONS>*/

  /*<BEGIN INTERNAL REGISTRATION FUNCTIONS>*/
  function _register(string memory domain, address owner, bool open) 
  internal domainNotExists(domain) {
    domains[domain] = owner;
    emit DomainRegistered(keccak256(abi.encode(domain)), domain, owner, msg.sender, open);
    if (open) openDomains[domain] = true;
  }

  function _registerDomain(string memory domain, string memory tld, bool open) 
  internal tldExists(tld) {
    uint price = updatedTldPrice(tld);
    require(msg.value >= price, "Insufficient price.");
    _register(domain.decimalJoin(tld), msg.sender, open);
    returnRemainder(price);
  }

  function _registerSubdomain(string memory subdomain, string memory domain, address owner, bool open) 
  internal onlyAllowed(domain) {
    string memory email = subdomain.atJoin(domain);
    require(
      emails[email] == address(0) ||
      emails[email] == msg.sender,
      "Email already exists for that subdomain"
    );
    _register(subdomain.decimalJoin(domain), owner, open);
  }
  /*</END INTERNAL REGISTRATION FUNCTIONS>*/

  /*<BEGIN REGISTRATION OVERLOADS>*/
  function registerDomain(string memory domain) public payable {
    _registerDomain(domain, "bns", false);
  }

  function registerDomain(string memory domain, bool open) public payable {
    _registerDomain(domain, "bns", open);
  }

  function registerDomain(string memory domain, string memory tld) public payable {
    _registerDomain(domain, tld, false);
  }

  function registerDomain(string memory domain, string memory tld, bool open) public payable {
    _registerDomain(domain, tld, open);
  }
  /*</END REGISTRATION OVERLOADS>*/

  /*<BEGIN SUBDOMAIN REGISTRATION OVERLOADS>*/
  function registerSubdomain(string memory subdomain, string memory domain) public {
    _registerSubdomain(subdomain, domain, msg.sender, false);
  }

  function registerSubdomain(string memory subdomain, string memory domain, bool open) public {
    _registerSubdomain(subdomain, domain, msg.sender, open);
  }

  function registerSubdomainAsDomainOwner(string memory subdomain, string memory domain, address subdomainOwner) 
  public onlyDomainOwner(domain) {
    _registerSubdomain(subdomain, domain, subdomainOwner, false);
  }
  /*</END SUBDOMAIN REGISTRATION OVERLOADS>*/
/*----------------</END DOMAIN REGISTRATION FUNCTIONS>----------------*/



/*----------------<BEGIN DOMAIN MANAGEMENT FUNCTIONS>----------------*/

  function transferDomain(string domain, address recipient) public onlyDomainOwner(domain) {
    domains[domain] = recipient;
  }

  /*<BEGIN CONTENT HASH FUNCTIONS>*/
  function setContentHash(string memory domain, bytes memory contentHash) public onlyDomainOwner(domain) {
    contentHashes[domain] = contentHash;
    emit ContentHashUpdated(keccak256(abi.encode(domain)), domain, contentHash);
  }

  function deleteContentHash(string memory domain) public onlyDomainOwner(domain) {
    delete contentHashes[domain];
    emit ContentHashUpdated(keccak256(abi.encode(domain)), domain, new bytes1(0x00));
  }
  /*</END CONTENT HASH FUNCTIONS>*/

  /*<BEGIN APPROVAL FUNCTIONS>*/
  function approveUser(string memory domain, address user) public onlyDomainOwner(domain) {
    domainApprovals[domain][user] = true;
    emit ApprovedForDomain(keccak256(abi.encode(domain)), domain, user);
  }

  function disapproveUser(string memory domain, address user) public onlyDomainOwner(domain) {
    domainApprovals[domain][user] = false;
    emit DisapprovedForDomain(keccak256(abi.encode(domain)), domain, user);
  }
  /*</END APPROVAL FUNCTIONS>*/


  /*<BEGIN INVALIDATION FUNCTIONS>*/
  function _invalidateDomain(string memory domain) internal {
    domains[domain] = address(0x01);
    emit SubdomainInvalidated(keccak256(abi.encode(domain)), domain, msg.sender);
  }

  function invalidateDomain(string memory domain) 
  public onlyDomainOwner(domain) {
    _invalidateDomain(domain);
  }

  function invalidateSubdomainAsDomainOwner(string memory subdomain, string memory domain) 
  public isLowercase(subdomain) onlyDomainOwner(domain) {
    _invalidateDomain(subdomain.decimalJoin(domain));
  }
  /*</END INVALIDATION FUNCTIONS>*/


  /*<BEGIN RESTRICTION FUNCTIONS>*/
  function openPublicDomainRegistration(string domain) public onlyDomainOwner(domain) {
    openDomains[domain] = true;
    emit DomainRegistrationOpened(keccak256(abi.encode(domain)), domain);
  }

  function closePublicDomainRegistration(string domain) public onlyDomainOwner(domain) {
    openDomains[domain] = false;
    emit DomainRegistrationClosed(keccak256(abi.encode(domain)), domain);
  }
  /*</END RESTRICTION FUNCTIONS>*/


  /*<BEGIN STORAGE FUNCTIONS>*/
  function setDomainStorageSingle(string domain, string key, string value) public onlyDomainOwner(domain) {
    domainStorage[domain][key] = value;
  }

  function setDomainStorageMany(string domain, string[2][] memory kvPairs) public onlyDomainOwner(domain) {
    for(uint i = 0; i < kvPairs.length; i++) {
      domainStorage[domain][kvPairs[i][0]] = kvPairs[i][1];
    }
  }

  function clearDomainStorage(string domain, string key) public onlyDomainOwner(domain) {
    delete domainStorage[domain][key];
  }

  function clearDomainStorage(string domain, string[] memory keys) public onlyDomainOwner(domain) {
    for(uint i = 0; i < keys.length; i++) {
      delete domainStorage[domain][keys[i]];
    }
  }
  /*</END STORAGE FUNCTIONS>*/

/*----------------</END DOMAIN MANAGEMENT FUNCTIONS>----------------*/
}