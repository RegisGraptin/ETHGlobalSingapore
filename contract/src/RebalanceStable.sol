// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

contract UpdatedCounter is BaseHook {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;

    mapping(PoolId => uint256 count) public beforeAddLiquidityCount;
    mapping(PoolId => uint256 count) public beforeRemoveLiquidityCount;

    mapping(PoolId => uint256 count) public donationCount;

    PoolKey public referencePoolKey;

    constructor(IPoolManager _poolManager, PoolKey memory _referencePoolKey) BaseHook(_poolManager) {
        referencePoolKey = _referencePoolKey;
    }

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

    // Get the slot0 data using extsload
    bytes32 slot0Data = poolManager.extsload(keccak256(abi.encode(key.toId(), uint256(0))));
    uint160 sqrtPriceX96 = uint160(uint256(slot0Data));

    // Get the reference pool's slot0 data
    bytes32 referenceSlot0Data = poolManager.extsload(keccak256(abi.encode(referencePoolKey.toId(), uint256(0))));
    uint160 referenceSqrtPriceX96 = uint160(uint256(referenceSlot0Data));

    if (sqrtPriceX96 == referenceSqrtPriceX96) {
        uint128 donateAmount0 = 1000; // Example amount, adjust as needed
        uint128 donateAmount1 = 1000; // Example amount, adjust as needed
        
        Currency currency0 = key.currency0;
        Currency currency1 = key.currency1;

        // Approve tokens if necessary (assuming this contract holds the tokens)
        currency0.approve(address(poolManager), donateAmount0);
        currency1.approve(address(poolManager), donateAmount1);

        poolManager.donate(key, donateAmount0, donateAmount1, "");
        donationCount[key.toId()]++;
    }

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
}