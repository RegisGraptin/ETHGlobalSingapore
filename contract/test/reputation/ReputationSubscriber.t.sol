// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {ISubscriber} from "v4-periphery/src/interfaces/ISubscriber.sol";


import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {PositionConfig} from "v4-periphery/test/shared/PositionConfig.sol";

import {LiquidityFuzzers} from "v4-periphery/test/shared/fuzz/LiquidityFuzzers.sol";
import {PosmTestSetup} from "v4-periphery/test/shared/PosmTestSetup.sol";
import {FeeMath} from "v4-periphery/test/shared/FeeMath.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";


import {ReputationSubscriber} from "../../src/ReputationSubscriber.sol";

contract FeeCollectionTest is Test, PosmTestSetup, LiquidityFuzzers {
    using FixedPointMathLib for uint256;
    using CurrencyLibrary for Currency;
    using FeeMath for IPositionManager;

    PoolId poolId;
    address alice = makeAddr("ALICE");
    address bob = makeAddr("BOB");

    // expresses the fee as a wad (i.e. 3000 = 0.003e18)
    uint256 FEE_WAD;

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
    }

    
    // Subscribe pool manager
    function test_subscribe() public {

        IPositionManager posm = IPositionManager(address(lpm));
        
        ReputationSubscriber rpsb = new ReputationSubscriber(lpm);
        ISubscriber mySubscriber = ISubscriber(rpsb);
        
        uint256 tokenId = lpm.nextTokenId();

        bytes memory optionalData = "";
        posm.subscribe(tokenId, address(mySubscriber), optionalData); // Notice we expect address for 'mySubscriber'

        mySubscriber.notifySubscribe(tokenId, "");
    }



    function test_donation(uint256 feeRevenue0, uint256 feeRevenue1) public {
        feeRevenue0 = bound(feeRevenue0, 0, 100_000_000 ether);
        feeRevenue1 = bound(feeRevenue1, 0, 100_000_000 ether);

        PositionConfig memory config = PositionConfig({poolKey: key, tickLower: -120, tickUpper: 120});
        uint256 tokenId = lpm.nextTokenId();
        mint(config, 10e18, address(this), ZERO_BYTES);

        // donate to generate fee revenue
        donateRouter.donate(key, feeRevenue0, feeRevenue1, ZERO_BYTES);

        BalanceDelta expectedFees = IPositionManager(address(lpm)).getFeesOwed(manager, config, tokenId);
        assertApproxEqAbs(uint128(expectedFees.amount0()), feeRevenue0, 1 wei); 
        assertApproxEqAbs(uint128(expectedFees.amount1()), feeRevenue1, 1 wei);
    }

}
