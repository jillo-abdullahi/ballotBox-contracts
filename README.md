# BallotBox Smart Contracts

A gas-optimized decentralized voting system built with Foundry.

## Overview

BallotBox allows users to create proposals and vote on them in a decentralized manner. The contract has been optimized for gas efficiency while maintaining security and functionality.

## Features

- ✅ Create proposals with title, description, and IPFS content hash
- ✅ Vote on active proposals (Yes/No voting)
- ✅ Query proposals with pagination
- ✅ Author-based proposal filtering
- ✅ Gas-optimized storage with packed structs
- ✅ IPFS integration for large content
- ✅ Overflow protection and safety checks

## Quick Start

### Build
```shell
forge build
```

### Test
```shell
forge test
```

### Test with Gas Report
```shell
forge test --gas-report
```

### Deploy Locally
```shell
# Start local node
anvil

# Deploy (in another terminal)
forge script script/Counter.s.sol --rpc-url http://localhost:8545 --private-key <anvil_private_key> --broadcast
```

## Gas Optimizations

This contract includes several gas optimizations:

- **Packed structs**: Reduces storage slots
- **Author indexing**: O(1) author queries instead of O(n)
- **IPFS integration**: Store large proposal details content off-chain
- **uint96 vote counts**: Sufficient range with packed storage
- **Unchecked arithmetic**: Where overflow is impossible

## Contract Functions

### Core Functions
- `createProposal()` - Create a new proposal
- `vote()` - Vote on a proposal
- `getProposal()` - Get proposal details
- `getProposals()` - Get proposals with pagination

### Query Functions
- `getProposalsByAuthor()` - Get proposals by specific author
- `getProposalIdsByAuthor()` - Get proposal IDs for an author
- `hasVoted()` - Check if address has voted
- `isProposalOpen()` - Check if proposal is open for voting

## Development

Built with [Foundry](https://book.getfoundry.sh/)
