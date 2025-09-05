# BitVault - Next-Generation NFT Treasury & Yield Protocol

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-blue)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Language-Clarity-purple)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen)](tests/)

## Overview

BitVault is an advanced NFT ecosystem built on the Stacks blockchain that revolutionizes digital asset management by combining Bitcoin's unmatched security with Stacks' programmability. The protocol enables secure asset vaulting, liquidity generation through fractional ownership, and automated yield distribution.

### Key Features

- **🔒 Collateral-Backed NFT Minting**: Secure NFT creation with STX collateral requirements
- **🏪 Peer-to-Peer Marketplace**: Seamless NFT trading with integrated fee structure
- **🔄 Fractional Ownership**: Share-based ownership models for increased liquidity
- **📈 Staking & Yield Generation**: Transform idle NFTs into yield-generating assets
- **⚡ Automated Reward Distribution**: Smart contract-based yield calculation and distribution
- **🛡️ Enterprise-Grade Security**: Built for institutions and collectors demanding security and profitability

## Protocol Architecture

### Core Components

1. **NFT Management System**
   - Collateral-backed minting with configurable ratios
   - Secure ownership transfers with validation
   - URI-based metadata management

2. **Marketplace Engine**
   - Decentralized listing and trading
   - Protocol fee collection
   - Active listing management

3. **Fractional Ownership Framework**
   - Share-based token ownership
   - Secure share transfers between principals
   - Overflow protection mechanisms

4. **Staking & Yield Infrastructure**
   - NFT staking with timestamp tracking
   - Block-based yield calculations
   - Automated reward accumulation and distribution

## Smart Contract Specifications

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ERR-OWNER-ONLY` | u100 | Owner-only function access error |
| `ERR-NOT-TOKEN-OWNER` | u101 | Non-owner token operation error |
| `ERR-INSUFFICIENT-BALANCE` | u102 | Insufficient balance error |
| `ERR-INVALID-TOKEN` | u103 | Invalid token ID error |
| `ERR-LISTING-NOT-FOUND` | u104 | Marketplace listing not found |
| `ERR-INVALID-PRICE` | u105 | Invalid price specification |
| `ERR-INSUFFICIENT-COLLATERAL` | u106 | Insufficient collateral error |
| `ERR-ALREADY-STAKED` | u107 | Token already staked error |
| `ERR-NOT-STAKED` | u108 | Token not staked error |

### Protocol Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `min-collateral-ratio` | 150% | Minimum collateral requirement for NFT minting |
| `protocol-fee` | 2.5% | Fee charged on marketplace transactions |
| `yield-rate` | 5% | Annual yield rate for staked NFTs |
| `total-staked` | 0 | Current number of staked NFTs |
| `total-supply` | 0 | Total number of minted NFTs |

## API Reference

### Core NFT Functions

#### `mint-nft`

Creates a new NFT with collateral backing.

```clarity
(mint-nft (uri (string-ascii 256)) (collateral uint))
```

**Parameters:**

- `uri`: Metadata URI for the NFT (max 256 characters)
- `collateral`: Collateral amount in microSTX

**Returns:** `(response uint uint)` - Token ID on success

**Requirements:**

- Valid URI format
- Sufficient STX balance for collateral requirement
- Collateral meets minimum ratio (150% of specified amount)

#### `transfer-nft`

Transfers NFT ownership between principals.

```clarity
(transfer-nft (token-id uint) (recipient principal))
```

**Parameters:**

- `token-id`: Unique identifier of the NFT
- `recipient`: Principal address receiving the NFT

**Requirements:**

- Caller must own the token
- Token must not be currently staked
- Recipient must be a valid principal

### Marketplace Functions

#### `list-nft`

Lists an NFT for sale on the marketplace.

```clarity
(list-nft (token-id uint) (price uint))
```

**Parameters:**

- `token-id`: NFT to list for sale
- `price`: Sale price in microSTX

**Requirements:**

- Caller must own the token
- Price must be greater than 0
- Token must not be staked

#### `purchase-nft`

Purchases a listed NFT from the marketplace.

```clarity
(purchase-nft (token-id uint))
```

**Parameters:**

- `token-id`: NFT to purchase

**Effects:**

- Transfers STX from buyer to seller
- Deducts protocol fee (2.5%)
- Transfers NFT ownership to buyer
- Clears marketplace listing

### Fractional Ownership

#### `transfer-shares`

Transfers fractional shares of an NFT between principals.

```clarity
(transfer-shares (token-id uint) (recipient principal) (share-amount uint))
```

**Parameters:**

- `token-id`: NFT for which shares are being transferred
- `recipient`: Principal receiving the shares
- `share-amount`: Number of shares to transfer

**Requirements:**

- Sender must have sufficient shares
- Recipient must be valid
- Overflow protection ensures mathematical safety

### Staking System

#### `stake-nft`

Stakes an NFT to begin earning yield rewards.

```clarity
(stake-nft (token-id uint))
```

**Effects:**

- Marks token as staked with current block height
- Initializes reward tracking
- Increments total staked counter

#### `unstake-nft`

Unstakes an NFT and claims final rewards.

```clarity
(unstake-nft (token-id uint))
```

**Effects:**

- Claims accumulated rewards
- Marks token as unstaked
- Decrements total staked counter

### Query Functions

#### `get-token-info`

Retrieves comprehensive token information.

```clarity
(get-token-info (token-id uint))
```

**Returns:** Token metadata including owner, URI, collateral, and staking status

#### `calculate-rewards`

Calculates current rewards for a staked NFT.

```clarity
(calculate-rewards (token-id uint))
```

**Returns:** Total accumulated rewards in microSTX

## Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.0+
- Node.js v16+
- TypeScript

### Installation

```bash
# Clone the repository
git clone https://github.com/femi-kingsley/BitVault.git
cd BitVault

# Install dependencies
npm install

# Verify Clarinet installation
clarinet --version
```

### Running Tests

```bash
# Run all tests
npm test

# Check contract syntax and semantics
clarinet check

# Format contract code
clarinet fmt --in-place
```

### Project Structure

BitVault/
├── contracts/
│   └── bitvault.clar          # Main smart contract
├── tests/
│   └── bitvault.test.ts       # Comprehensive test suite
├── settings/
│   ├── Devnet.toml           # Development network config
│   ├── Testnet.toml          # Testnet configuration
│   └── Mainnet.toml          # Mainnet configuration
├── Clarinet.toml             # Project configuration
├── package.json              # Node.js dependencies
├── tsconfig.json             # TypeScript configuration
└── vitest.config.js          # Test configuration

## Security Considerations

### Implemented Protections

- **Overflow Protection**: Safe arithmetic operations with `safe-add` utility
- **Access Controls**: Owner validation for sensitive operations
- **Input Validation**: URI format and recipient validation
- **State Consistency**: Proper staking state management
- **Collateral Security**: Minimum collateral ratio enforcement

### Audit Recommendations

- Conduct formal verification of mathematical operations
- Implement time-locked withdrawals for large stakes
- Add emergency pause functionality for critical bugs
- Consider multi-signature requirements for protocol parameter changes

## Gas Optimization

The contract implements several gas-efficient patterns:

- Minimal storage operations through strategic map design
- Efficient calculation methods for rewards
- Optimized validation functions
- Reduced redundant checks through proper error handling

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow Clarity best practices and naming conventions
- Add comprehensive tests for all new features
- Ensure all tests pass before submitting PRs
- Update documentation for API changes

## Roadmap

- [ ] **v1.1**: Governance token integration
- [ ] **v1.2**: Advanced yield farming mechanisms  
- [ ] **v1.3**: Cross-chain asset bridging
- [ ] **v1.4**: Institutional custody features
- [ ] **v2.0**: Layer 2 scaling solutions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ for the Stacks ecosystem
