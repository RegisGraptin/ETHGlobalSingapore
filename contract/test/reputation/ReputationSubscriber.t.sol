// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {ISubscriber} from "v4-periphery/src/interfaces/ISubscriber.sol";


import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {PositionConfig} from "v4-periphery/test/shared/PositionConfig.sol";

import {LiquidityFuzzers} from "v4-periphery/test/shared/fuzz/LiquidityFuzzers.sol";
import {PosmTestSetup} from "v4-periphery/test/shared/PosmTestSetup.sol";
import {FeeMath} from "v4-periphery/test/shared/FeeMath.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

import {PositionInfo, PositionInfoLibrary} from "v4-periphery/src/libraries/PositionInfoLibrary.sol";

import {ReputationSubscriber} from "../../src/ReputationSubscriber.sol";

contract FeeCollectionTest is Test, PosmTestSetup, LiquidityFuzzers {
    using FixedPointMathLib for uint256;
    using CurrencyLibrary for Currency;
    using FeeMath for IPositionManager;
    using PositionInfoLibrary for PositionInfo;

    PoolId poolId;
    address alice = makeAddr("ALICE");
    address bob = makeAddr("BOB");

    // expresses the fee as a wad (i.e. 3000 = 0.003e18)
    uint256 FEE_WAD;

    PositionConfig config;

    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        // This is needed to receive return deltas from modifyLiquidity calls.
        deployPosmHookSavesDelta();

        (key, poolId) = initPool(currency0, currency1, IHooks(hook), 3000, SQRT_PRICE_1_1, ZERO_BYTES);
        FEE_WAD = uint256(key.fee).mulDivDown(FixedPointMathLib.WAD, 1_000_000);

        // Requires currency0 and currency1 to be set in base Deployers contract.
        deployAndApprovePosm(manager);

        // Give tokens to Alice and Bob.
        seedBalance(alice);
        seedBalance(bob);

        // Approve posm for Alice and bob.
        approvePosmFor(alice);
        approvePosmFor(bob);

        config = PositionConfig({poolKey: key, tickLower: -300, tickUpper: 300});
    }


    
    // Subscribe pool manager
    function test_subscription_register() public {
        uint256 tokenId = lpm.nextTokenId();
        mint(config, 100e18, alice, ZERO_BYTES);

        // approve this contract to operate on alices liq
        vm.startPrank(alice);
        lpm.approve(address(this), tokenId);
        vm.stopPrank();

        // Create subscription manager
        ReputationSubscriber rpsb = new ReputationSubscriber(lpm);
        lpm.subscribe(tokenId, address(rpsb), ZERO_BYTES);

        // successfully subscribe
        assertEq(lpm.positionInfo(tokenId).hasSubscriber(), true);
        assertEq(address(lpm.subscriber(tokenId)), address(rpsb));
    }

    // Check reputation user
    function test_subscription_action() public {
        uint256 tokenId = lpm.nextTokenId();
        mint(config, 100e18, alice, ZERO_BYTES);

        // approve this contract to operate on alices liq
        vm.startPrank(alice);
        lpm.approve(address(this), tokenId);
        vm.stopPrank();

        ReputationSubscriber rpsb = new ReputationSubscriber(lpm);
        lpm.subscribe(tokenId, address(rpsb), ZERO_BYTES);

        // Create subscription manager
        vm.roll(100);
        
        // // Transfer some tokens
        // lpm.safeTransferFrom(alice, bob, tokenId, "");
        // uint256 aliceRep = rpsb.getUserReputation(tokenId, alice);
        // console.logUint(aliceRep);

    }
}
