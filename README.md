# 🏏 PSL Teams Auction Protocol

A decentralized auction house for trading unique Pakistan Super League (PSL) Team NFTs. Built on Ethereum using **Solidity** and the **Foundry** framework.

This protocol allows the "Chairman" (Owner) to mint unique Team NFTs and list them for auction. Users bid using a custom ERC20 token (PKR), with anti-sniping protection built directly into the smart contract.

The Team NFT represents a team in the PSL, the owner of the NFT would own the team in real aswell. Inshort, the teams are Tokenized into NFTS.

## Architecture

### Contracts
1.  **`PSLTeams.sol` (ERC721)**
    * Standard NFT contract using OpenZeppelin `ERC721URIStorage`.
    * **Role:** Represents ownership of a PSL Team.
    * **Metadata:** Stores IPFS URIs for team branding/logos.

2.  **`PSLTeamsBidding.sol` (Auction Logic)**
    * **Escrow System:** Holds NFTs during the auction.
    * **Custom Currency:** Bidding accepts specific ERC20 tokens PKR instead of ETH.
    * **Anti-Sniping:** Every bid placed within the last 5 minutes extends the auction by another 5 minutes.
    * **Validation:** Enforces a strict base price of **1 Billion PKR (100 Crore)**.

3.  **`MockPKR.sol`**
    * A test ERC20 token to simulate the payment currency during testing.

## Tech Stack

* **Language:** Solidity ^0.8.24
* **Framework:** Foundry
* **Standards:** ERC721, ERC20, Ownable

## Installation & Setup

**1. Install Foundry**
```bash
curl -L [https://foundry.paradigm.xyz](https://foundry.paradigm.xyz) | bash
foundryup

```

**2. Clone & Install Dependencies**

```bash
git clone <the-repo-url>
cd <the-repo-directory>
forge install

```

**3. Compile Contracts**

```bash
forge build

```

## Testing

The project includes a comprehensive test suite covering minting, listing, bidding wars, and settlement logic.

```bash
# Run all tests
forge test

# Run with detailed logs
forge test -vv

# Check test coverage
forge coverage

```

## Deployment

**1. Set up Environment Variables**
Create a `.env` file in the root directory:

```env
PRIVATE_KEY=0xYourPrivateKey...
RPC_URL=[https://sepolia.infura.io/v3/YourKey](https://sepolia.infura.io/v3/YourKey)...
ETHERSCAN_API_KEY=YourEtherscanKey...

```

**2. Deploy to Testnet (e.g., Sepolia)**

```bash
source .env
forge script script/DeployPSLTeamsBidding.s.sol:DeployPSLTeamsBidding --rpc-url $RPC_URL --broadcast --verify

```

## Verified Addresses (Sepolia)

* **PSLTeams (NFT):** `[UPDATE_WITH_YOUR_ADDRESS]`
* **Bidding Contract:** `[UPDATE_WITH_YOUR_ADDRESS]`
* **PKR Token:** `[UPDATE_WITH_YOUR_ADDRESS]`

## 🛡 License

MIT