// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

// world id
import { ByteHasher } from './helpers/ByteHasher.sol';
import { IWorldID } from './interfaces/IWorldID.sol';

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract Counter is BaseHook {
    using PoolIdLibrary for PoolKey;
    // world id
	using ByteHasher for bytes;
	////////////////////////////////////////////////////////////////////////////////
	///                            WORLD ID ERRORS                              ///
	//////////////////////////////////////////////////////////////////////////////

	/// @notice Thrown when attempting to reuse a nullifier
	error DuplicateNullifier(uint256 nullifierHash);

	/// @dev The World ID instance that will be used for verifying proofs
	IWorldID internal immutable worldId;

	/// @dev The contract's external nullifier hash
	uint256 internal immutable externalNullifier;

	/// @dev The World ID group ID (always 1)
	uint256 internal immutable groupId = 1;

	/// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
	mapping(uint256 => bool) internal nullifierHashes;

	/// @param nullifierHash The nullifier hash for the verified proof
	/// @dev A placeholder event that is emitted when a user successfully verifies with World ID
	event Verified(uint256 nullifierHash);

	/// @param _worldId The WorldID router that will verify the proofs
	/// @param _appId The World ID app ID
	/// @param _actionId The World ID action ID




    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;

    mapping(PoolId => uint256 count) public beforeAddLiquidityCount;
    mapping(PoolId => uint256 count) public beforeRemoveLiquidityCount;

    constructor(IPoolManager _poolManager, IWorldID _worldId, string memory _appId, string memory _actionId) BaseHook(_poolManager) {
		worldId = _worldId;
		externalNullifier = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
	}

	/// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
	/// @param root The root of the Merkle tree (returned by the JS widget).
	/// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
	/// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the JS widget).
	/// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        beforeSwapCount[key.toId()]++;
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4, int128)
    {
        afterSwapCount[key.toId()]++;
        return (BaseHook.afterSwap.selector, 0);
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        beforeAddLiquidityCount[key.toId()]++;
        return BaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        beforeRemoveLiquidityCount[key.toId()]++;
        return BaseHook.beforeRemoveLiquidity.selector;
    }

	function verifyAndExecute(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) public {
		// First, we make sure this person hasn't done this before
		if (nullifierHashes[nullifierHash]) revert DuplicateNullifier(nullifierHash);

		// We now verify the provided proof is valid and the user is verified by World ID
		worldId.verifyProof(
			root,
			groupId,
			abi.encodePacked(signal).hashToField(),
			nullifierHash,
			externalNullifier,
			proof
		);

		// We now record the user has done this, so they can't do it again (proof of uniqueness)
		nullifierHashes[nullifierHash] = true;

		// Finally, execute your logic here, for example issue a token, NFT, etc...
		// Make sure to emit some kind of event afterwards!

		emit Verified(nullifierHash);
	}
}
