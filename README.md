
# HoneyBadger Framework

![HoneyBadger Logo](logoTPB.png)

HoneyBadger is an extension of ERC-7844, offering a comprehensive plug-and-play data and permission management solution for Solidity smart contract systems in a single easy-to-use package.  

The core concept behind HoneyBadger is to standardize cutting-edge supporting infrastructure.  The model cohesively combines best practices for interoperability, dependency management, upgradeability, and storage management into an extendible format with near-universal applicability.   

One of the key standout features is HoneyBadger's approach to storage, which is securely managed by hash-segregated namespaces called "storage spaces."  Storage spaces each encode a custom "extendible struct" type, which can be extended without re-deployment using function calls.  



Project frontend: https://www.honeybadgerframework.com  
Feel free to contact me: https://www.linkedin.com/in/cameron-warnick-64a25222a/ 
Linkedin company page: https://www.linkedin.com/company/honeybadgerframework/?viewAsMember=true  
Project twitter: https://x.com/HoneyBadgerWeb3  
## Deployment

It's easy to get HoneyBadger up and running.  Use the init_create function to define new storage spaces, and use update_permissions to grant permissions to contracts that will execute calls to the framework.

Example:
uint256[] memory types = new uint256[](3);
uint256[] memory sizes = new uint256[](3);

types[0] = 1;
types[1] = 1;
types[2] = 1;

sizes[0] = 8;
sizes[2] = 16;
sizes[3] = 128;

_HB.init_create(types, sizes, false);

Where init_create has the following interface: init_create(types, sizes, specialAccess).

SpecialAccess defines whether a storage space uses custom access patterns.  This is largely used for multi-layered nested indexing (ie; allowances[from][to]). 

## Authors

- [@wisecameron](https://www.github.com/wisecameron)


## Using the Framework

**Allocating storage**
Allocation is only required for storage spaces that do not use special access patterns (as special access patterns don't follow basic sequential indexing).

To allocate a new entry (ie; allocate data for user 1), use: *push(amount, storageSpace)*

**Modify data:** 
*put(value, memberIndex, entryIndex, storageSpace)*

Example: put(120, uint8(UserData.balance), 1, USER_DATA_STORAGE_SPACE)

**Retrieve data:**
*get(memberIndex, entryIndex, storageSpace)*

**Modify Permissions**
*update_permissions(user, flags, remove)*
## To-Do

**Granular Access Controls**
The current version only supports basic permission flags (ie; put/get/permission management, etc).  

**Cross-Chain Data Sharing with ZK Proofs** 
This is a major feature that we intend to add in a standalone version.

**ERC20, ERC721 and Other Integrated Standards**
This process is underway.  Integrated standards are recommended to use Solady or Solmate for enhanced efficiency.

**Auditing**
The Framework is not currently audited, although basic tests are available (hardhat).
## Community

Our contributor community is hosted on Telegram: https://t.me/+b8ZbMRFX1xEyYzE5
