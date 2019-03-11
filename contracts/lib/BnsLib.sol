pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

library BnsLib {
  /*<BEGIN EVENTS>*/
  event TopLevelDomainCreated(string tld);
  event TopLevelDomainPriceUpdated(string tld, uint newPrice);
  event DomainRegistered(string domain, address indexed owner, address indexed registeredBy, bool open);
  event SubdomainInvalidated(string subdomain, address InvalidatedBy);
  event ReturnedRefund(address recipient, uint refund);
  /*</END EVENTS>*/

  /*<BEGIN STRUCTS>*/
  struct TopLevelDomain {
    uint price;
    uint lastUpdate;
    bool min;
    bool exists;
  }
  /*</END STRUCTS>*/
  
  /*<BEGIN MODIFIERS>*/
  function hasOnlyAllowedCharacters(string memory str) 
  internal pure returns (bool) {
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

  function hasOnlyDomainLevelCharacters(string memory str) 
  internal pure returns (bool) {
    /* [9-0] [A-Z] [a-z] */
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