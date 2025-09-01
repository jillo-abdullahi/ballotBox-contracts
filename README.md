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
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <anvil_private_key> --broadcast
```

### Deploy to Sepolia Testnet
```shell
# Deploy to Sepolia
forge script script/Deploy.s.sol \
  --rpc-url https://sepolia.infura.io/v3/<your_infura_key> \
  --private-key <your_private_key> \
  --broadcast \
  --verify \
  --etherscan-api-key <your_etherscan_api_key>
```

### Deploy to Mainnet
```shell
# Deploy to Ethereum Mainnet (use with caution!)
forge script script/Deploy.s.sol \
  --rpc-url https://mainnet.infura.io/v3/<your_infura_key> \
  --private-key <your_private_key> \
  --broadcast \
  --verify \
  --etherscan-api-key <your_etherscan_api_key>
```

### Environment Variables (Recommended)
Create a `.env` file for safer key management:
```bash
# .env file
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_infura_key
MAINNET_RPC_URL=https://mainnet.infura.io/v3/your_infura_key
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Then deploy with:
```shell
source .env
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
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
