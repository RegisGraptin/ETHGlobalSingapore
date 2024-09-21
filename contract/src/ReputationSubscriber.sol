// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {ISubscriber} from "v4-periphery/src/interfaces/ISubscriber.sol";

import {PositionManagerSubscriber} from "./PositionManagerSubscriber.sol";


import "forge-std/Test.sol";

contract ReputationSubscriber is PositionManagerSubscriber {
    // User position
    struct Position {
        uint256 amount;
        uint256 startTime;
    }

    // Defined the user reputation based on the token ID
    mapping(uint256 tokenId => mapping(address user => uint256 score)) reputation;

    // Stored all user actions
    mapping(uint256 tokenId => mapping(address user => Position[] position)) userPositions;

    constructor(PositionManager _posm) PositionManagerSubscriber(_posm) {}

    function notifySubscribe(uint256 tokenId, bytes memory data) external onlyByPosm override {}

    function notifyUnsubscribe(uint256 tokenId) external onlyByPosm override {}

    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta)
        external onlyByPosm
        override
    {
        if (liquidityChange > 0) {
            // User added liquidity
            userPositions[tokenId][posm.msgSender()].push(
                Position({amount: uint256(liquidityChange), startTime: block.timestamp})
            );
        } else {
            // User remove liquidity
            uint256 positionToRemove = uint256(liquidityChange);
            uint256 i = userPositions[tokenId][posm.msgSender()].length - 1;

            while (positionToRemove > 0) {
                uint256 lastAmount = userPositions[tokenId][posm.msgSender()][i].amount;

                // Not enough from the last one, remove last one
                if (positionToRemove >= lastAmount) {
                    reputation[tokenId][posm.msgSender()] += computePositionReputation(userPositions[tokenId][posm.msgSender()][i]);
                    userPositions[tokenId][posm.msgSender()].pop();
                    i -= 1;
                } else {
                    // Update reputation accordingly
                    reputation[tokenId][posm.msgSender()] += computePositionReputation(
                        Position({amount: lastAmount, startTime: userPositions[tokenId][posm.msgSender()][i].startTime})
                    );

                    // Update user position
                    userPositions[tokenId][posm.msgSender()][i].amount -= lastAmount;

                    // No need to proceed further
                    return;
                }
            }
        }
    }

    function notifyTransfer(uint256 tokenId, address previousOwner, address) external onlyByPosm override {
        /// @notice When a transfer is done, we compute the reputation of the address and delete
        /// all open position by the user. 
        
        // For all user liquidity, compute the reputation
        reputation[tokenId][previousOwner] = computeCurrentReputation(tokenId, previousOwner);

        // Remove from the previous owner the current position
        delete userPositions[tokenId][previousOwner];

    }

    function computeCurrentReputation(uint256 tokenId, address user) public view returns (uint256) {

        uint256 currentPositionReputation = 0;

        for (uint256 i = 0; i < userPositions[tokenId][user].length; i++) {
            currentPositionReputation += computePositionReputation(userPositions[tokenId][user][i]);
        }

        return currentPositionReputation + reputation[tokenId][user];
    }

    function computePositionReputation(Position memory position) internal view returns (uint256) {
        uint256 deltaTime = block.timestamp - position.startTime;

        uint256 rewardPercent = 0;

        if (deltaTime > (3 * 365 days)) { // 3 years
            rewardPercent = 100_000;
        } else {
            rewardPercent = (deltaTime * 100_000) / (3 * 365 days);
        }

        return (rewardPercent * position.amount) / 1_000;
    }

}
