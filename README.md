
# Raffle Contract

![License](https://img.shields.io/badge/license-MIT-green)
![Foundry](https://img.shields.io/badge/built%20with-Foundry-blue)
![Chainlink](https://img.shields.io/badge/Chainlink-VRF%20v2.5-orange)

A decentralized Raffle smart contract built using the [Foundry](https://getfoundry.sh/) development framework. The contract utilizes Chainlink VRF v2.5 for secure randomness and is deployed on the Ethereum Sepolia testnet.

---

## Features

- **Decentralized Raffle System**: Players can enter the raffle by sending ETH.
- **Secure Randomness**: Uses Chainlink VRF v2.5 to ensure fair winner selection.
- **Event-Driven**: Emits key events (`RaffleEntered`, `WinnerPicked`, `RequestedRaffleWinner`) for transparency and frontend integration.
- **Automated Upkeep**: Implements Chainlink Keepers to check and perform raffle operations automatically.

---

## Table of Contents

- [Raffle Contract](#raffle-contract)
  - [Features](#features)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Entering the Raffle](#entering-the-raffle)
    - [Picking a Winner](#picking-a-winner)
  - [Contract Details](#contract-details)
    - [Constructor Parameters](#constructor-parameters)
    - [Events](#events)
  - [Testing](#testing)
  - [Deployment](#deployment)
    - [Deploying to Sepolia Testnet](#deploying-to-sepolia-testnet)
  - [Technologies Used](#technologies-used)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

---

## Installation

To set up the project locally, follow these steps:

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/raffle-contract.git
   cd raffle-contract
   ```

3. **Install Dependencies**:
   ```bash
   forge install
   ```

---

## Usage

### Entering the Raffle
Participants can enter the raffle by sending ETH equal to or greater than the entrance fee (`i_entranceFee`). The contract keeps track of all players until the winner is selected.

### Picking a Winner
The Chainlink Keepers and VRF automate winner selection:
- **checkUpKeep**: Determines if the raffle conditions are met (time interval, players, ETH).
- **performUpKeep**: Triggers the winner selection using a Chainlink VRF request.

---

## Contract Details

### Constructor Parameters
- `entranceFee`: The ETH required to enter the raffle.
- `interval`: Time interval between raffle executions.
- `vrfCoordinator`: Chainlink VRF coordinator address.
- `gasLane`: Chainlink key hash.
- `subscriptionId`: Subscription ID for Chainlink VRF.
- `callbackGasLimit`: Maximum gas for the VRF callback.

### Events
- `RaffleEntered(address indexed player)`
- `RequestedRaffleWinner(uint256 indexed requestId)`
- `WinnerPicked(address indexed winner)`

---

## Testing

1. **Run Tests**:
   ```bash
   forge test
   ```

2. **Test Coverage**:
   ```bash
   forge coverage
   ```

3. **Simulation**: Use `anvil` to simulate contract interactions locally:
   ```bash
   anvil
   ```

---

## Deployment

### Deploying to Sepolia Testnet
1. **Set Environment Variables**:
   Create a `.env` file with the following:
   ```env
   PRIVATE_KEY=your_private_key
   SEPOLIA_RPC_URL=https://rpc.sepolia.org
   LINK_TOKEN=0x... # LINK token address on Sepolia
   VRF_COORDINATOR=0x... # VRF coordinator address
   ```

2. **Compile the Contract**:
   ```bash
   forge build
   ```

3. **Deploy**:
   ```bash
   forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
   ```

---

## Technologies Used

- [Foundry](https://getfoundry.sh/) for smart contract development.
- [Chainlink VRF](https://docs.chain.link/vrf/v2/introduction/) for randomness.
- [Solidity](https://soliditylang.org/) (version `0.8.19`).

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Chainlink Documentation](https://docs.chain.link/)
- [Foundry Documentation](https://book.getfoundry.sh/)

---
