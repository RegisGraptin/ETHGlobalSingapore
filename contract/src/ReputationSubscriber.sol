// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {ISubscriber} from "v4-periphery/src/interfaces/ISubscriber.sol";
import {PositionInfo, PositionInfoLibrary} from "v4-periphery/src/libraries/PositionInfoLibrary.sol";



import {PositionManagerSubscriber} from "./PositionManagerSubscriber.sol";

import "forge-std/Test.sol";

// User position
struct Position {
    uint256 amount0; 
    uint256 amount1;
    uint256 startTime;    
}

struct AmountPosition {
    uint256 amount;
    uint256 startTime;        
}

contract ReputationSubscriber is PositionManagerSubscriber {

    // using StateLibrary for PositionManager;
    using StateLibrary for IPoolManager;
    using PositionInfoLibrary for PositionInfo;

    // Defined a reputation system for each token ID
    mapping(uint256 tokenId => Reputation) reputation;

    constructor(PositionManager _posm) PositionManagerSubscriber(_posm) {}

    function notifySubscribe(uint256 tokenId, bytes memory) external override onlyByPosm {
        // FIXME :: maybe need to confirm the reputation does not exists ?
        reputation[tokenId] = Reputation(address(this));
    }

    function notifyUnsubscribe(uint256 tokenId) external override onlyByPosm {
        delete reputation[tokenId];
    }

    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta)
        external
        override
        onlyByPosm
    {
        // Extract liquidity from position
        uint128 liquidity = posm.getPositionLiquidity(tokenId);
        (PoolKey memory poolKey, PositionInfo info) = posm.getPoolAndPositionInfo(tokenId);

        IPoolManager manager = IPoolManager(address(posm));
        (uint160 sqrtPriceX96,,,) = manager.getSlot0(poolKey.toId());
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(info.tickLower()),
            TickMath.getSqrtPriceAtTick(info.tickUpper()),
            liquidity
        );

        Position memory userPosition = Position({
            amount0: amount0, 
            amount1: amount1, 
            startTime: block.timestamp
        });

        if (liquidityChange > 0) {
            // User added liquidity
            reputation[tokenId].addPosition(posm.msgSender(), userPosition);
        } else {
            // User remove liquidity
            reputation[tokenId].removeLiquidity(posm.msgSender(), userPosition);
        }
    }


    function notifyTransfer(uint256 tokenId, address previousOwner, address newOwner) external override onlyByPosm {
        /// @notice When a transfer is done, we compute the reputation of the address and delete
        /// all open position by the user.

        // First get the liquidity position
        uint128 liquidity = posm.getPositionLiquidity(tokenId);
        (PoolKey memory poolKey, PositionInfo info) = posm.getPoolAndPositionInfo(tokenId);
        
        IPoolManager manager = IPoolManager(posm.poolManager());
        (uint160 sqrtPriceX96,,,) = manager.getSlot0(poolKey.toId());

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(info.tickLower()),
            TickMath.getSqrtPriceAtTick(info.tickUpper()),
            liquidity
        );
    
        reputation[tokenId].cleanPosition(previousOwner);

        reputation[tokenId].addPosition(newOwner, Position({
            amount0: amount0, 
            amount1: amount1, 
            startTime: block.timestamp
        }));
    }


    function getUserReputation(uint256 tokenId, address user) public view returns (uint256) {
        return reputation[tokenId].computeCurrentReputation(user);
    }
    
}

contract Reputation {

    address owner;

    mapping(address => uint256) score;

    // Store the positions for each token amount
    mapping(address user => AmountPosition[] position0) positions0;
    mapping(address user => AmountPosition[] position1) positions1;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor (address _owner) {
        owner = _owner;
    }

    function addPosition(address user, Position memory position) onlyOwner external {
        positions0[user].push(AmountPosition({amount: position.amount0, startTime: position.startTime}));
        positions1[user].push(AmountPosition({amount: position.amount1, startTime: position.startTime}));
    }

    function removeLiquidity(address user, Position memory position) onlyOwner external {

        // Compute for position0
        uint256 amount0 = position.amount0;
        uint256 i = positions0[user].length - 1;

        while (amount0 > 0) {
            uint256 lastAmount = positions0[user][i].amount;

            // Not enough from the last one, remove last one
            if (amount0 >= lastAmount) {
                score[user] += computePositionReputation(positions0[user][i]);
                positions0[user].pop();
                i -= 1;
            } else {
                // Update reputation accordingly
                score[user] += computePositionReputation(
                    AmountPosition({amount: lastAmount, startTime: positions0[user][i].startTime})
                );

                // Update user position
                positions0[user][i].amount -= lastAmount;

                // Can proceed to the other token
                break;
            }
        }

        // Now need to udpate amount1
        uint256 amount1 = position.amount1;
        i = positions1[user].length - 1;

        while (amount1 > 0) {
            uint256 lastAmount = positions1[user][i].amount;

            // Not enough from the last one, remove last one
            if (amount1 >= lastAmount) {
                score[user] += computePositionReputation(positions1[user][i]);
                positions1[user].pop();
                i -= 1;
            } else {
                // Update reputation accordingly
                score[user] += computePositionReputation(
                    AmountPosition({amount: lastAmount, startTime: positions1[user][i].startTime})
                );

                // Update user position
                positions1[user][i].amount -= lastAmount;

                // No need to proceed further
                return;
            }
        }
    }

    function computeCurrentReputation(address user) public view returns (uint256) {
        uint256 currentPositionReputation = 0;

        // Compute on position 0
        for (uint256 i = 0; i < positions0[user].length; i++) {
            currentPositionReputation += computePositionReputation(positions0[user][i]);
        }

        // Compute on position 1
        for (uint256 i = 0; i < positions1[user].length; i++) {
            currentPositionReputation += computePositionReputation(positions1[user][i]);
        }

        return currentPositionReputation + score[user];
    }

    function cleanPosition(address user) external onlyOwner() {
        // For all user liquidity, compute the reputation
        score[user] = computeCurrentReputation(user);

        // Remove from the previous owner the current position
        delete positions0[user];
        delete positions1[user];
    }

    function computePositionReputation(AmountPosition memory position) internal view returns (uint256) {
        uint256 deltaTime = block.timestamp - position.startTime;

        uint256 rewardPercent = 0;

        if (deltaTime > (3 * 365 days)) {
            // 3 years
            rewardPercent = 100_000;
        } else {
            rewardPercent = (deltaTime * 100_000) / (3 * 365 days);
        }

        return (rewardPercent * position.amount) / 1_000;
    }
}
