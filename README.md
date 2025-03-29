# Calcutta Madness

Website for hosting March Madness calcutta auctions

## User Experience

### Onboarding
1. Create Account / Login

2. Create an Auction (auction.state -> "upcoming")
  - Enter a name
  - Optional: Add Users
    - Email

3. Optional: Edit Auction Settings
  - Create / Edit / Delete Team Groupings
  - Set an ordering (random, seed)

### Running the Auction as Admin

1. Login to Account

2. Open your Auction

3. Click "Start Auction" (auction.state -> "active")
  - First team available will show up an bidding begins

4. Close Bidding for Team
  - Next team will pop up

5. Continues until no teams remain (auction.state -> "complete")

### Auction Room

  if "upcoming" -> view the board, prepare strategy, etc
  if "active" -> live auction mode
  if "complete" -> auction review / results mode

### Live Auction - Block View (Non Admin)

1. Next/first team gets placed on the block with current price = 0 and active countdown timer

2. Any user can "place bid", which either gets "accepted" or "rejected"

3. Each new "accepted" bid 
  - resets that timer
  - updates the current price
  - shows highest bidder

4. When timer hits 0
   - Price gets charged to highest bidder
   - Team gets placed in auction history log with the purchase info
   - If more teams remaining, back to step 1

### Live Auction - Block View (Admin)

Same experience as non-admin plus
- Ability to reset timer
- override bid
- restore to previous bid
  (gets a stack of bids)

### Live Auction - Bracket View

1. Display the tournament bracket with all teams in their respective positions.
2. Highlight the teams that have been purchased with the buyer's name and purchase price.
3. Show the current team on the block with the active countdown timer.
4. Allow users to click on a team to view bidding history and details.
5. Update the bracket in real-time as teams are purchased and placed.
6. Provide a summary section showing total spent by each user and remaining budget.

## Infrastructure

### Authentication / Authorization

AWS Cognito Pools

### Database

AWS Dynamo
