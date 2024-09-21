// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {ISubscriber} from "v4-periphery/src/interfaces/ISubscriber.sol";

/// @title PositionManagerSubscriber contract
/// @dev Create a new 'ISubscriber' which can be called only by the position manager.
abstract contract PositionManagerSubscriber is ISubscriber {

    error NotAuthorizedNotifer(address sender);

    // Keep the position manager address to check authorize call
    PositionManager posm;

    constructor(PositionManager _posm) {
        posm = _posm;
    }

    modifier onlyByPosm() {
        if (msg.sender != address(posm)) revert NotAuthorizedNotifer(msg.sender);
        _;
    }

    function notifySubscribe(
        uint256 tokenId,
        bytes memory data
    ) external onlyByPosm virtual {}

    function notifyUnsubscribe(uint256 tokenId) external onlyByPosm virtual {}

    function notifyModifyLiquidity(
        uint256 tokenId,
        int256 liquidityChange,
        BalanceDelta feesAccrued
    ) external onlyByPosm virtual {}

    function notifyTransfer(
        uint256 tokenId,
        address previousOwner,
        address newOwner
    ) external onlyByPosm virtual {}
}