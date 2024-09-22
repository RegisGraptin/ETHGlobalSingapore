# Unify Finance

## Project Overview

Unify Finance is a comprehensive DeFi project that aims to enhance liquidity pool management, introduce innovative hooks for Uniswap, and provide a unified interface for portfolio management across multiple wallets.

### Key Features

1. **Reputation Pool for Uniswap**: 
   - Leverages the 'ISubscriber' interface to monitor pool movements
   - Generates reputation scores for users based on their liquidity provision

2. **Custom Hooks for Uniswap**:
   - Stablecoin Pool Hook: Adjusts pool reserves after swaps
   - Dynamic Tick Adjustment Hook: Rotates liquidity tick limits to maintain concentration after large orders

3. **Multi-Wallet Portfolio Management**:
   - Utilizes NEAR Protocol for generating and managing multiple wallets through a single NEAR wallet
   - Provides a unified interface for monitoring positions and managing actions across different wallets

## Technical Implementation

### Uniswap Reputation System
- Built on the 'ISubscriber' interface
- Reputation contract manages the logic for score calculation
- Tracks open positions provided by users
- Reputation increases with the duration of liquidity provision
- Considers the amount of both tokens provided
- Adjusts tracking when users transfer or remove liquidity

### Uniswap Hooks
1. Stablecoin Pool Hook:
   - Implements post-swap pool reserve adjustments
2. Dynamic Tick Adjustment Hook:
   - Rotates liquidity tick limits after significant swaps
   - Maintains liquidity concentration
   - Requires user pre-approval for pool rebalancing

### NEAR Protocol Integration
- Built on top of provided templates
- Developing an SDK approach to simplify cross-chain processes
- Streamlines common behaviors across different blockchains
