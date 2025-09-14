# BallotBox Smart Contracts

A gas-optimized decentralized voting system built with Foundry.

## 🚀 Deployed Contract

**Sepolia Testnet**: [`0xD9a4Ded9Ae3A3aAda18e9b04bfA4DD5b2a4F1602`](https://sepolia.etherscan.io/address/0xD9a4Ded9Ae3A3aAda18e9b04bfA4DD5b2a4F1602)

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

## Smart Filtering System ✨ NEW

The contract now includes highly efficient filtering functions that work at the contract level:

### Why Contract-Level Filtering?
- **Reduced Gas Costs**: No need to fetch all proposals and filter client-side
- **Better Performance**: Especially beneficial as proposal count grows
- **Proper Pagination**: Filtered results maintain consistent pagination
- **Real-time Status**: Automatically checks proposal expiration based on current block time

### Filtering Options
- **By Status**: Open (active & not expired) vs Closed (inactive or expired)
- **By Author**: Filter proposals by specific creator address
- **Combined**: Get open/closed proposals by specific author
- **Efficient Counts**: Get accurate counts without fetching full data

### Frontend Benefits
```javascript
// Before: Fetch all and filter client-side (expensive)
const allProposals = await contract.getProposals(0, 50)
const openProposals = allProposals.filter(p => isOpen(p))

// After: Direct contract filtering (efficient)
const openProposals = await contract.getOpenProposals(0, 50)
const openCount = await contract.getOpenProposalCount()
```

## Contract Functions

### Core Functions
- `createProposal()` - Create a new proposal
- `vote()` - Vote on a proposal
- `getProposal()` - Get proposal details

### Efficient Filtering Functions ✨ NEW
- `getOpenProposals(offset, limit)` - Get only open proposals with pagination
- `getClosedProposals(offset, limit)` - Get only closed proposals with pagination
- `getOpenProposalsByAuthor(author, offset, limit)` - Get open proposals by specific author
- `getClosedProposalsByAuthor(author, offset, limit)` - Get closed proposals by specific author

### Count Functions ✨ NEW
- `getOpenProposalCount()` - Total count of open proposals
- `getClosedProposalCount()` - Total count of closed proposals
- `getOpenProposalCountByAuthor(author)` - Count of open proposals by author
- `getClosedProposalCountByAuthor(author)` - Count of closed proposals by author

### Legacy Query Functions
- `getProposals(offset, limit)` - Get all proposals with pagination
- `getProposalsByAuthor(author, offset, limit)` - Get all proposals by specific author
- `getProposalIdsByAuthor()` - Get proposal IDs for an author
- `hasVoted()` - Check if address has voted
- `isProposalOpen()` - Check if proposal is open for voting

## Development

Built with [Foundry](https://book.getfoundry.sh/)
