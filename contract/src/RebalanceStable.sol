// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CurrencyLibrary} from "v4-core/src/libraries/CurrencyLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract RebalanceStable is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    mapping(PoolId => uint256) public donationCount;
    PoolKey public referencePoolKey;

    constructor(IPoolManager _poolManager, PoolKey memory _referencePoolKey) BaseHook(_poolManager) {
        referencePoolKey = _referencePoolKey;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4, int128)
    {
        // Get the slot0 data using extsload
        bytes32 slot0Data = poolManager.extsload(keccak256(abi.encode(key.toId(), uint256(0))));
        uint160 sqrtPriceX96 = uint160(uint256(slot0Data));

        // Get the reference pool's slot0 data
        bytes32 referenceSlot0Data = poolManager.extsload(keccak256(abi.encode(referencePoolKey.toId(), uint256(0))));
        uint160 referenceSqrtPriceX96 = uint160(uint256(referenceSlot0Data));

        if (sqrtPriceX96 == referenceSqrtPriceX96) {
            uint128 donateAmount0 = 1000; // Example amount, adjust as needed
            uint128 donateAmount1 = 1000; // Example amount, adjust as needed
            
            // Handle approvals if needed
            if (!key.currency0.isNative()) {
                IERC20(key.currency0.unwrap()).approve(address(poolManager), donateAmount0);
            }

            if (!key.currency1.isNative()) {
                IERC20(key.currency1.unwrap()).approve(address(poolManager), donateAmount1);
            }

            // Donate to the pool
            poolManager.donate(key, donateAmount0, donateAmount1, "");
            donationCount[key.toId()]++;
        }

        return (BaseHook.afterSwap.selector, 0);
    }
}