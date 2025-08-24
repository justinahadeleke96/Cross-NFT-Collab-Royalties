Cross-NFT Collaboration Royalties Smart Contract

Overview

This smart contract enables revenue sharing between two NFT projects when they collaborate on sales or royalties. It ensures that creators receive their fair share of revenue according to pre-defined percentages, while providing mechanisms to withdraw funds, track balances, and deactivate collaborations if needed.

✨ Features

Collaboration Creation

Define a collaboration between two NFT projects.

Assign creators and their royalty split percentages (must total 100%).

Each creator gets a revenue balance initialized at zero.

Revenue Distribution

Distribute incoming sales/royalties between the two creators based on agreed percentages.

Automatically updates individual balances and total revenue tracked under the collaboration.

Withdrawals

Creators can withdraw their accumulated revenue anytime.

Contract owner can also withdraw on behalf of a creator (admin override).

Prevents withdrawals of zero balances.

Collaboration Management

Any of the two creators or the contract owner can deactivate a collaboration.

Once deactivated, no new revenue can be distributed under that collaboration.

Read-Only Queries

Fetch details of a collaboration.

Check a creator’s pending revenue balance.

View the contract owner.

🛠️ Data Structures

collaborations → stores metadata about each collaboration (creators, split, total revenue, active status).

revenue-balances → stores balances per creator under each collaboration.

⚖️ Error Codes

u100 → Unauthorized

u101 → Invalid percentage split

u102 → Collaboration not found

u103 → Collaboration already exists

u104 → Insufficient funds

🚀 Example Workflow

Create Collaboration
create-collaboration projectA projectB creatorA creatorB 60 40
→ Creates a collaboration with a 60/40 split.

Distribute Revenue
distribute-revenue projectA projectB 1000
→ Allocates 600 STX to Creator A and 400 STX to Creator B.

Withdraw Funds
withdraw-revenue projectA projectB creatorA
→ Transfers Creator A’s accumulated STX balance to their wallet.

Deactivate Collaboration
deactivate-collaboration projectA projectB
→ Marks the collaboration as inactive (cannot distribute new revenue).

🔒 Security

Only creators or the contract owner can deactivate a collaboration.

Withdrawals are limited to creators themselves or contract owner (acting on behalf).

Percentages must sum to exactly 100%.

📚 Use Cases

Cross-NFT project collaborations (e.g., joint art drops).

Revenue-sharing in NFT partnerships.

Merged NFT collections with ongoing royalty agreements.