# Uniswap V4 Position Manager Subscriber and Reputation System

This project implements a flexible subscriber system for Uniswap V4's Position Manager, along with a reputation system for liquidity providers. It consists of two main contracts: `PositionManagerSubscriber` and `ReputationSubscriber`.

## Overview

1. `PositionManagerSubscriber`: An abstract contract that provides a safe interface for subscribing to Uniswap V4 Position Manager events.
2. `ReputationSubscriber`: A concrete implementation of `PositionManagerSubscriber` that tracks and rewards liquidity providers based on their activity.

## PositionManagerSubscriber Contract

### Purpose
- Provides a base contract for creating subscribers to Uniswap V4 Position Manager events.
- Ensures that only the authorized Position Manager can call notification functions.

### Key Features
- Abstract contract to be inherited by specific subscriber implementations.
- Includes a modifier `onlyByPosm` to restrict access to Position Manager calls.
- Defines virtual functions for different Position Manager events:
  - `notifySubscribe`
  - `notifyUnsubscribe`
  - `notifyModifyLiquidity`
  - `notifyTransfer`

### Usage
Inherit from this contract when creating a new subscriber for the Uniswap V4 Position Manager. Implement the virtual functions as needed for your specific use case.

## ReputationSubscriber Contract

### Purpose
- Implements a reputation system for liquidity providers in Uniswap V4 pools.
- Tracks and rewards users based on their liquidity provision history.

### Key Features
- Inherits from `PositionManagerSubscriber`.
- Manages a `Reputation` contract for each token ID.
- Tracks liquidity changes and transfers for specific token IDs.
- Calculates and updates reputation scores based on user actions.

### Key Functions
- `notifySubscribe`: Initializes reputation tracking for a token ID.
- `notifyUnsubscribe`: Removes reputation tracking for a token ID.
- `notifyModifyLiquidity`: Updates reputation when liquidity is added or removed.
- `notifyTransfer`: Handles reputation changes when a position is transferred.
- `getUserReputation`: Retrieves the current reputation score for a user.

## Reputation Contract

### Purpose
- Stores and calculates reputation scores for users.
- Manages position history for each user.

### Key Features
- Tracks positions separately for token0 and token1 of a liquidity pair.
- Uses time-based calculations to reward longer-term liquidity providers.
- Provides functions for adding positions, removing liquidity, and computing reputation scores.

### Key Functions
- `addPosition`: Adds a new liquidity position for a user.
- `removeLiquidity`: Handles reputation changes when liquidity is removed.
- `computeCurrentReputation`: Calculates the total reputation score for a user.
- `cleanPosition`: Finalizes reputation when a position is fully closed or transferred.
- `computePositionReputation`: Calculates reputation for a single position based on time and amount.

## Reputation Calculation

The system rewards users based on:
1. The amount of liquidity provided.
2. The duration for which the liquidity is provided.

Key points:
- Maximum reward is achieved after 3 years of providing liquidity.
- Reputation increases linearly with time up to the 3-year mark.
- The base reputation is calculated as: `(time_factor * liquidity_amount) / 1000`

## Usage

1. Deploy the `ReputationSubscriber` contract, passing the address of the Uniswap V4 Position Manager.
2. For each pool you want to track, call the appropriate function on the Position Manager to subscribe this contract.
3. The contract will automatically track liquidity changes and transfers, updating reputation scores accordingly.
4. Use `getUserReputation` to query the current reputation score for any user.

## Security Considerations

- The `PositionManagerSubscriber` ensures that only the authorized Position Manager can call notification functions.
- The `Reputation` contract uses an `onlyOwner` modifier to restrict access to sensitive functions.
- Ensure proper access control when deploying and managing these contracts.
- The contracts interact closely with Uniswap V4 components, so any upgrades to Uniswap might require updates to these contracts.

## Future Improvements

- Implement a decay mechanism for inactive users.
- Add governance functionality to adjust reputation calculation parameters.
- Extend the `PositionManagerSubscriber` to support more complex subscription patterns.
- Consider implementing a factory pattern for easy deployment of multiple reputation systems.

## Development and Testing

- The contracts use Forge for testing. Ensure you have Forge installed and set up.
- Run tests using the `forge test` command.
- The `ReputationSubscriber` contract includes some Forge test utilities, which should be removed in a production environment.

## Notes

- The `FIXME` comments in the code indicate areas that may need further attention or improvement.
- The reputation system is designed to incentivize long-term liquidity provision and can be adapted for various DeFi applications.

Remember to thoroughly test these contracts and consider a security audit before deploying to a production environment.