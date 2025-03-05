// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import '../IHoneyBadgerBaseV1.sol';

// /// @notice Simple ERC20 + EIP-2612 implementation.
// /// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
// /// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
// /// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
// ///
// /// @dev Note:
// /// - The ERC20 standard allows minting and transferring to and from the zero address,
// ///   minting and transferring zero tokens, as well as self-approvals.
// ///   For performance, this implementation WILL NOT revert for such actions.
// ///   Please add any checks with overrides if desired.
// /// - The `permit` function uses the ecrecover precompile (0x1).
// ///
// /// If you are overriding:
// /// - NEVER violate the ERC20 invariant:
// ///   the total sum of all balances must be equal to `totalSupply()`.
// /// - Check that the overridden function is actually used in the function you want to
// ///   change the behavior of. Much of the code has been manually inlined for performance.
// contract ERC20 {
//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                       CUSTOM ERRORS                        */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev The total supply has overflowed.
//     error TotalSupplyOverflow();

//     /// @dev The allowance has overflowed.
//     error AllowanceOverflow();

//     /// @dev The allowance has underflowed.
//     error AllowanceUnderflow();

//     /// @dev Insufficient balance.
//     error InsufficientBalance();

//     /// @dev Insufficient allowance.
//     error InsufficientAllowance();

//     /// @dev The permit is invalid.
//     error InvalidPermit();

//     /// @dev The permit has expired.
//     error PermitExpired();

//     /// @dev The allowance of Permit2 is fixed at infinity.
//     error Permit2AllowanceIsFixedAtInfinity();

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                           EVENTS                           */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
//     event Transfer(address indexed from, address indexed to, uint256 amount);

//     /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
//     event Approval(address indexed owner, address indexed spender, uint256 amount);

//     /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
//     uint256 private constant _TRANSFER_EVENT_SIGNATURE =
//         0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

//     /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
//     uint256 private constant _APPROVAL_EVENT_SIGNATURE =
//         0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                          STORAGE                           */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev The balance slot of `owner` is given by:
//     /// ```
//     ///     mstore(0x0c, _BALANCE_SLOT_SEED)
//     ///     mstore(0x00, owner)
//     ///     let balanceSlot := keccak256(0x0c, 0x20)
//     /// ```
//     uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

//     /// @dev The allowance slot of (`owner`, `spender`) is given by:
//     /// ```
//     ///     mstore(0x20, spender)
//     ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
//     ///     mstore(0x00, owner)
//     ///     let allowanceSlot := keccak256(0x0c, 0x34)
//     /// ```
//     uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

//     /// @dev The nonce slot of `owner` is given by:
//     /// ```
//     ///     mstore(0x0c, _NONCES_SLOT_SEED)
//     ///     mstore(0x00, owner)
//     ///     let nonceSlot := keccak256(0x0c, 0x20)
//     /// ```
//     uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

//     address private _HoneyBadgerInstanceAddress;
//     address private _owner;
//     IHoneyBadgerBaseV1 private _HB;

//     uint256 public GLOBAL_DATA_STORAGE_SPACE;
//     uint256 public ALLOWANCES_STORAGE_SPACE;
//     uint256 public USER_DATA_STORAGE_SPACE; 
//     uint256 public NONCES_STORAGE_SPACE;

//     enum Globals
//     {
//         name,
//         symbol,
//         decimals,
//         totalSupply
//     }

//     enum Allowance
//     {
//         allowance
//     }

//     enum User
//     {
//         balance
//     }

//     enum Nonce
//     {
//         nonce
//     }

//     constructor(address HoneyBadgerInstanceAddress)
//     {
//         _HoneyBadgerInstanceAddress = HoneyBadgerInstanceAddress;
//         _owner = msg.sender;
//         _HB = IHoneyBadgerBaseV1(HoneyBadgerInstanceAddress);
//     }

//     function init_storage(
//         string memory __name, 
//         string memory __symbol, 
//         uint256 __decimals
//     ) external 
//     {
//         uint256[] memory types = new uint256[](4);
//         types[0] = 6;
//         types[1] = 6;
//         types[2] = 1;
//         types[3] = 1;

//         uint256[] memory sizes = new uint256[](4);
//         sizes[2] = 8;
//         sizes[3] = 256;

//         uint256 storageSpace = _HB.init_create(types, sizes, false);
//         GLOBAL_DATA_STORAGE_SPACE = storageSpace - 1;

//         _HB.push(1, storageSpace);
//         _HB.put_string(__name, uint256(Globals.name), 1, GLOBAL_DATA_STORAGE_SPACE, "0x");
//         _HB.put_string(__symbol, uint256(Globals.symbol), 1, GLOBAL_DATA_STORAGE_SPACE, "0x");
//         _HB.put(__decimals, uint256(Globals.decimals), 1, GLOBAL_DATA_STORAGE_SPACE, "0x");

//         assembly
//         {
//             mstore(types, 1)
//             mstore(sizes, 1)
//         }

//         types[0] = 1;
//         sizes[0] = 256;

//         //allowances
//         storageSpace = _HB.init_create(types, sizes, true);
//         ALLOWANCES_STORAGE_SPACE = storageSpace - 1;

//         //user
//         uint256[] memory types2 = new uint256[](1);
//         uint256[] memory sizes2 = new uint256[](1);

//         types2[0] = 1; //balance
//         sizes2[0] = 256;
//         storageSpace = _HB.init_create(types2, sizes2, false);
//         USER_DATA_STORAGE_SPACE = storageSpace - 1;

//         storageSpace = _HB.init_create(types2, sizes2, false);
//         NONCES_STORAGE_SPACE = storageSpace - 1;
//     }


//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                         CONSTANTS                          */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev `(_NONCES_SLOT_SEED << 16) | 0x1901`.
//     uint256 private constant _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX = 0x383775081901;

//     /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
//     bytes32 private constant _DOMAIN_TYPEHASH =
//         0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

//     /// @dev `keccak256("1")`.
//     /// If you need to use a different version, override `_versionHash`.
//     bytes32 private constant _DEFAULT_VERSION_HASH =
//         0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

//     /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
//     bytes32 private constant _PERMIT_TYPEHASH =
//         0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

//     /// @dev The canonical Permit2 address.
//     /// For signature-based allowance granting for single transaction ERC20 `transferFrom`.
//     /// To enable, override `_givePermit2InfiniteAllowance()`.
//     /// [Github](https://github.com/Uniswap/permit2)
//     /// [Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)
//     address internal constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                       ERC20 METADATA                       */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Returns the name of the token.
//     function name() public view virtual returns (string memory)
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         return _HB.get_string(uint256(Globals.name), 1, GLOBAL_DATA_STORAGE_SPACE, "0x");
//     }

//     /// @dev Returns the symbol of the token.
//     function symbol() public view virtual returns (string memory)
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         return _HB.get_string(uint256(Globals.symbol), 1, GLOBAL_DATA_STORAGE_SPACE, "0x");
//     }

//     /// @dev Returns the decimals places of the token.
//     function decimals() public view virtual returns (uint8) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         return uint8(_HB.get(uint256(Globals.symbol), 1, GLOBAL_DATA_STORAGE_SPACE, "0x"));
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                           ERC20                            */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Returns the amount of tokens in existence.
//     function totalSupply() public view virtual returns (uint256 result) 
//     {    
//         require(address(_HB) != address(0), "Not initialized!");

//         return(_HB.get(uint256(Globals.totalSupply), 1, GLOBAL_DATA_STORAGE_SPACE, "0x"));
//     }

//     /// @dev Returns the amount of tokens owned by `owner`.
//     function balanceOf(address owner) public view virtual returns (uint256 result) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");
//         uint256 userIndex = _HB.address_indexed(owner, USER_DATA_STORAGE_SPACE);
//         if(userIndex == 0) return 0;
//         uint256 balance = _HB.get(uint8(User.balance), userIndex, USER_DATA_STORAGE_SPACE, "0x");

//         return balance;
//     }

//     /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
//     function allowance(address owner, address spender)
//         public
//         view
//         virtual
//         returns (uint256 result)
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         if (_givePermit2InfiniteAllowance()) {
//             if (spender == _PERMIT2) return type(uint256).max;
//         }

//         bytes memory arguments = abi.encodePacked(owner, spender);
//         result = _HB.get(uint8(Allowance.allowance), 1, ALLOWANCES_STORAGE_SPACE, arguments);
//     }

//     /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//     ///
//     /// Emits a {Approval} event.
//     function approve(address spender, uint256 amount) public virtual returns (bool) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");
    
//         if (_givePermit2InfiniteAllowance()) {
//             /// @solidity memory-safe-assembly
//             assembly {
//                 // If `spender == _PERMIT2 && amount != type(uint256).max`.
//                 if iszero(or(xor(shr(96, shl(96, spender)), _PERMIT2), iszero(not(amount)))) {
//                     mstore(0x00, 0x3f68539a) // `Permit2AllowanceIsFixedAtInfinity()`.
//                     revert(0x1c, 0x04)
//                 }
//             }
//         }

//         bytes memory arguments = abi.encodePacked(msg.sender, spender);
//         _HB.put(amount, uint8(Allowance.allowance), 1, ALLOWANCES_STORAGE_SPACE, arguments);

//         /// @solidity memory-safe-assembly
//         assembly {
//             // Emit the {Approval} event.
//             mstore(0x00, amount)
//             log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
//         }
//         return true;
//     }

//     /// @dev Transfer `amount` tokens from the caller to `to`.
//     ///
//     /// Requirements:
//     /// - `from` must at least have `amount`.
//     ///
//     /// Emits a {Transfer} event.
//     function transfer(address to, uint256 amount) public virtual returns (bool) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");
//         _beforeTokenTransfer(msg.sender, to, amount);

//         uint256 toId = _HB.address_indexed(to, USER_DATA_STORAGE_SPACE);
//         uint256 fromId = _HB.address_indexed(msg.sender, USER_DATA_STORAGE_SPACE);

//         if(toId == 0) toId = _allocate_storage_for_user(to);
//         if(fromId == 0) fromId = _allocate_storage_for_user(msg.sender);

//         //verify spender balance
//         uint256 fromBalance = _HB.get(uint8(User.balance), fromId, USER_DATA_STORAGE_SPACE, "0x");
//         assembly 
//         {
//             if gt(amount, fromBalance) {
//                 mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
//                 revert(0x1c, 0x04)
//             }
//         }

//         //subtract and store the updated amount
//         _HB.put(fromBalance - amount, uint8(User.balance), fromId, USER_DATA_STORAGE_SPACE, "0x");

//         //Compute the "to" balance.
//         uint256 toBalance = _HB.get(uint8(User.balance), toId, USER_DATA_STORAGE_SPACE, "0x");
//         _HB.put(toBalance + amount, uint8(User.balance), toId, USER_DATA_STORAGE_SPACE, "0x");

//         assembly 
//         {
//             // Emit the {Transfer} event.
//             mstore(0x20, amount)
//             log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
//         }
//         _afterTokenTransfer(msg.sender, to, amount);
//         return true;
//     }

//     /// @dev Transfers `amount` tokens from `from` to `to`.
//     ///
//     /// Note: Does not update the allowance if it is the maximum uint256 value.
//     ///
//     /// Requirements:
//     /// - `from` must at least have `amount`.
//     /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
//     ///
//     /// Emits a {Transfer} event.
//     function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");
//         _beforeTokenTransfer(from, to, amount);
        
//         bytes memory arguments = abi.encodePacked(from, to);
//         uint256 __allowance = _HB.get(uint8(Allowance.allowance), 1, ALLOWANCES_STORAGE_SPACE, arguments);

//         if(msg.sender != _PERMIT2)
//         {
//             if(__allowance != type(uint256).max)
//             {
//                 assembly
//                 {
//                     if gt(amount, __allowance) 
//                     {
//                         mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
//                         revert(0x1c, 0x04)
//                     }
//                 }

//                 //Subtract and store the updated allowance
//                 _HB.put(__allowance - amount, uint8(Allowance.allowance), 1, ALLOWANCES_STORAGE_SPACE, arguments);
//             }
//         }

//         //get from balance
//         uint256 fromId = _HB.address_indexed(from, USER_DATA_STORAGE_SPACE);
//         if(fromId == 0) fromId = _allocate_storage_for_user(msg.sender);

//         uint256 fromBalance = _HB.get(uint8(User.balance), fromId, USER_DATA_STORAGE_SPACE, "0x");

//         assembly
//         {
//             // Revert if insufficient balance.
//             if gt(amount, fromBalance) {
//                 mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
//                 revert(0x1c, 0x04)
//             }
//         }

//         //Subtract and store the updated from balance.
//         _HB.put(fromBalance - amount, uint8(User.balance), fromId, USER_DATA_STORAGE_SPACE, "0x");

//         //Add and store the updated to balance
//         uint256 toId = _HB.address_indexed(to, USER_DATA_STORAGE_SPACE);
//         if(toId == 0) toId = _allocate_storage_for_user(to);

//         uint256 toBalance = _HB.get(uint8(User.balance), toId, USER_DATA_STORAGE_SPACE, "0x");
//         _HB.put(toBalance + amount, uint8(User.balance), toId, USER_DATA_STORAGE_SPACE, "0x");

//         //Emit the {Transfer} event
//         assembly
//         {
//             mstore(0x20, amount)
//             log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, from, to)
//         }

//         _afterTokenTransfer(from, to, amount);
//         return true;
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                          EIP-2612                          */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev For more performance, override to return the constant value
//     /// of `keccak256(bytes(name()))` if `name()` will never change.
//     function _constantNameHash() internal view virtual returns (bytes32 result) {}

//     /// @dev If you need a different value, override this function.
//     function _versionHash() internal view virtual returns (bytes32 result) 
//     {
//         result = _DEFAULT_VERSION_HASH;
//     }

//     /// @dev For inheriting contracts to increment the nonce.
//     function _incrementNonce(address owner) internal virtual 
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         uint256 ownerId = _HB.address_indexed(owner, NONCES_STORAGE_SPACE);
//         if(ownerId == 0) ownerId = _allocate_storage_for_user(owner);

//         uint256 nonce = _HB.get(uint8(Nonce.nonce), ownerId, NONCES_STORAGE_SPACE, "0x");
//         _HB.put(nonce + 1, uint8(Nonce.nonce), ownerId, NONCES_STORAGE_SPACE, "0x");
//     }

//     /// @dev Returns the current nonce for `owner`.
//     /// This value is used to compute the signature for EIP-2612 permit.
//     function nonces(address owner) public view virtual returns (uint256 result) 
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         uint256 ownerId = _HB.address_indexed(owner, NONCES_STORAGE_SPACE);
//         if(ownerId == 0) return 0;

//         return(_HB.get(uint8(Nonce.nonce), ownerId, NONCES_STORAGE_SPACE, "0x"));
//     }

//     /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
//     /// authorized by a signed approval by `owner`.
//     ///
//     /// Emits a {Approval} event.
//     function permit(
//         address owner,
//         address spender,
//         uint256 value,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) public virtual 
//     {
//         if (_givePermit2InfiniteAllowance()) 
//         {
//             assembly {
//                 // If `spender == _PERMIT2 && value != type(uint256).max`.
//                 if iszero(or(xor(shr(96, shl(96, spender)), _PERMIT2), iszero(not(value)))) {
//                     mstore(0x00, 0x3f68539a) // `Permit2AllowanceIsFixedAtInfinity()`.
//                     revert(0x1c, 0x04)
//                 }
//             }
//         }
//         bytes32 nameHash = _constantNameHash();
//         //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
//         if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
//         bytes32 versionHash = _versionHash();

//         assembly {
//             // Revert if the block timestamp is greater than `deadline`.
//             if gt(timestamp(), deadline) {
//                 mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
//                 revert(0x1c, 0x04)
//             }
//             let m := mload(0x40) // Grab the free memory pointer.
//             // Clean the upper 96 bits.
//             owner := shr(96, shl(96, owner))
//             spender := shr(96, shl(96, spender))
//             // Compute the nonce slot and load its value.
//             mstore(0x0e, _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX)
//             mstore(0x00, owner)
//             let nonceSlot := keccak256(0x0c, 0x20)
//             let nonceValue := sload(nonceSlot)
//             // Prepare the domain separator.
//             mstore(m, _DOMAIN_TYPEHASH)
//             mstore(add(m, 0x20), nameHash)
//             mstore(add(m, 0x40), versionHash)
//             mstore(add(m, 0x60), chainid())
//             mstore(add(m, 0x80), address())
//             mstore(0x2e, keccak256(m, 0xa0))
//             // Prepare the struct hash.
//             mstore(m, _PERMIT_TYPEHASH)
//             mstore(add(m, 0x20), owner)
//             mstore(add(m, 0x40), spender)
//             mstore(add(m, 0x60), value)
//             mstore(add(m, 0x80), nonceValue)
//             mstore(add(m, 0xa0), deadline)
//             mstore(0x4e, keccak256(m, 0xc0))
//             // Prepare the ecrecover calldata.
//             mstore(0x00, keccak256(0x2c, 0x42))
//             mstore(0x20, and(0xff, v))
//             mstore(0x40, r)
//             mstore(0x60, s)
//             let t := staticcall(gas(), 1, 0x00, 0x80, 0x20, 0x20)
//             // If the ecrecover fails, the returndatasize will be 0x00,
//             // `owner` will be checked if it equals the hash at 0x00,
//             // which evaluates to false (i.e. 0), and we will revert.
//             // If the ecrecover succeeds, the returndatasize will be 0x20,
//             // `owner` will be compared against the returned address at 0x20.
//             if iszero(eq(mload(returndatasize()), owner)) {
//                 mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
//                 revert(0x1c, 0x04)
//             }
//             // Increment and store the updated nonce.
//             sstore(nonceSlot, add(nonceValue, t)) // `t` is 1 if ecrecover succeeds.
//             // Compute the allowance slot and store the value.
//             // The `owner` is already at slot 0x20.
//             mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
//             sstore(keccak256(0x2c, 0x34), value)
//             // Emit the {Approval} event.
//             log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
//             mstore(0x40, m) // Restore the free memory pointer.
//             mstore(0x60, 0) // Restore the zero pointer.
//         }
//     }

//     /// @dev Returns the EIP-712 domain separator for the EIP-2612 permit.
//     function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
//         bytes32 nameHash = _constantNameHash();
//         //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
//         if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
//         bytes32 versionHash = _versionHash();
//         /// @solidity memory-safe-assembly
//         assembly {
//             let m := mload(0x40) // Grab the free memory pointer.
//             mstore(m, _DOMAIN_TYPEHASH)
//             mstore(add(m, 0x20), nameHash)
//             mstore(add(m, 0x40), versionHash)
//             mstore(add(m, 0x60), chainid())
//             mstore(add(m, 0x80), address())
//             result := keccak256(m, 0xa0)
//         }
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                  INTERNAL MINT FUNCTIONS                   */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Mints `amount` tokens to `to`, increasing the total supply.
//     ///
//     /// Emits a {Transfer} event.
//     function _mint(address to, uint256 amount) internal virtual {
//         _beforeTokenTransfer(address(0), to, amount);
//         /// @solidity memory-safe-assembly
//         assembly {
//             let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
//             let totalSupplyAfter := add(totalSupplyBefore, amount)
//             // Revert if the total supply overflows.
//             if lt(totalSupplyAfter, totalSupplyBefore) {
//                 mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
//                 revert(0x1c, 0x04)
//             }
//             // Store the updated total supply.
//             sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
//             // Compute the balance slot and load its value.
//             mstore(0x0c, _BALANCE_SLOT_SEED)
//             mstore(0x00, to)
//             let toBalanceSlot := keccak256(0x0c, 0x20)
//             // Add and store the updated balance.
//             sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
//             // Emit the {Transfer} event.
//             mstore(0x20, amount)
//             log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
//         }
//         _afterTokenTransfer(address(0), to, amount);
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                  INTERNAL BURN FUNCTIONS                   */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Burns `amount` tokens from `from`, reducing the total supply.
//     ///
//     /// Emits a {Transfer} event.
//     function _burn(address from, uint256 amount) internal virtual {
//         _beforeTokenTransfer(from, address(0), amount);
//         /// @solidity memory-safe-assembly
//         assembly {
//             // Compute the balance slot and load its value.
//             mstore(0x0c, _BALANCE_SLOT_SEED)
//             mstore(0x00, from)
//             let fromBalanceSlot := keccak256(0x0c, 0x20)
//             let fromBalance := sload(fromBalanceSlot)
//             // Revert if insufficient balance.
//             if gt(amount, fromBalance) {
//                 mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
//                 revert(0x1c, 0x04)
//             }
//             // Subtract and store the updated balance.
//             sstore(fromBalanceSlot, sub(fromBalance, amount))
//             // Subtract and store the updated total supply.
//             sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
//             // Emit the {Transfer} event.
//             mstore(0x00, amount)
//             log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
//         }
//         _afterTokenTransfer(from, address(0), amount);
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                INTERNAL TRANSFER FUNCTIONS                 */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Moves `amount` of tokens from `from` to `to`.
//     function _transfer(address from, address to, uint256 amount) internal virtual {
//         _beforeTokenTransfer(from, to, amount);
//         /// @solidity memory-safe-assembly
//         assembly {
//             let from_ := shl(96, from)
//             // Compute the balance slot and load its value.
//             mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
//             let fromBalanceSlot := keccak256(0x0c, 0x20)
//             let fromBalance := sload(fromBalanceSlot)
//             // Revert if insufficient balance.
//             if gt(amount, fromBalance) {
//                 mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
//                 revert(0x1c, 0x04)
//             }
//             // Subtract and store the updated balance.
//             sstore(fromBalanceSlot, sub(fromBalance, amount))
//             // Compute the balance slot of `to`.
//             mstore(0x00, to)
//             let toBalanceSlot := keccak256(0x0c, 0x20)
//             // Add and store the updated balance of `to`.
//             // Will not overflow because the sum of all user balances
//             // cannot exceed the maximum uint256 value.
//             sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
//             // Emit the {Transfer} event.
//             mstore(0x20, amount)
//             log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
//         }
//         _afterTokenTransfer(from, to, amount);
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                INTERNAL ALLOWANCE FUNCTIONS                */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
//     function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
//         if (_givePermit2InfiniteAllowance()) {
//             if (spender == _PERMIT2) return; // Do nothing, as allowance is infinite.
//         }
//         /// @solidity memory-safe-assembly
//         assembly {
//             // Compute the allowance slot and load its value.
//             mstore(0x20, spender)
//             mstore(0x0c, _ALLOWANCE_SLOT_SEED)
//             mstore(0x00, owner)
//             let allowanceSlot := keccak256(0x0c, 0x34)
//             let allowance_ := sload(allowanceSlot)
//             // If the allowance is not the maximum uint256 value.
//             if not(allowance_) {
//                 // Revert if the amount to be transferred exceeds the allowance.
//                 if gt(amount, allowance_) {
//                     mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
//                     revert(0x1c, 0x04)
//                 }
//                 // Subtract and store the updated allowance.
//                 sstore(allowanceSlot, sub(allowance_, amount))
//             }
//         }
//     }

//     /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
//     ///
//     /// Emits a {Approval} event.
//     function _approve(address owner, address spender, uint256 amount) internal virtual {
//         if (_givePermit2InfiniteAllowance()) {
//             /// @solidity memory-safe-assembly
//             assembly {
//                 // If `spender == _PERMIT2 && amount != type(uint256).max`.
//                 if iszero(or(xor(shr(96, shl(96, spender)), _PERMIT2), iszero(not(amount)))) {
//                     mstore(0x00, 0x3f68539a) // `Permit2AllowanceIsFixedAtInfinity()`.
//                     revert(0x1c, 0x04)
//                 }
//             }
//         }
//         /// @solidity memory-safe-assembly
//         assembly {
//             let owner_ := shl(96, owner)
//             // Compute the allowance slot and store the amount.
//             mstore(0x20, spender)
//             mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
//             sstore(keccak256(0x0c, 0x34), amount)
//             // Emit the {Approval} event.
//             mstore(0x00, amount)
//             log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
//         }
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                     HOOKS TO OVERRIDE                      */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Hook that is called before any transfer of tokens.
//     /// This includes minting and burning.
//     function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

//     /// @dev Hook that is called after any transfer of tokens.
//     /// This includes minting and burning.
//     function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                          PERMIT2                           */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//     /// @dev Returns whether to fix the Permit2 contract's allowance at infinity.
//     ///
//     /// This value should be kept constant after contract initialization,
//     /// or else the actual allowance values may not match with the {Approval} events.
//     /// For best performance, return a compile-time constant for zero-cost abstraction.
//     function _givePermit2InfiniteAllowance() internal view virtual returns (bool) {
//         return true;
//     }

//     /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
//     /*                User storage alloc                          */
//     /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
//     function _allocate_storage_for_user(
//         address user
//     ) internal returns(uint256 id)
//     {
//         require(address(_HB) != address(0), "Not initialized!");

//         _HB.push(1, USER_DATA_STORAGE_SPACE);
//         id = _HB.address_indexed(user, USER_DATA_STORAGE_SPACE);
//     }

// }