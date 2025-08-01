# Decentralized Voting System Architecture

## System Overview

This Mermaid diagram illustrates the architecture and flow of the decentralized voting system built with Solidity smart contracts and Next.js frontend.

```mermaid
graph TB
    %% Frontend Layer
    subgraph "Frontend (Next.js)"
        A[User Interface] --> B[ConnectButton]
        A --> C[PollManager Component]
        B --> D[RainbowKit Wallet Connection]
        C --> E[Poll Details Display]
        C --> F[Poll ID Input]
        
        subgraph "React Hooks & State"
            G[useAccount Hook]
            H[useReadContract Hook]
            I[useState - pollId]
            J[useState - inputValue]
        end
        
        subgraph "Web3 Integration"
            K[Wagmi Provider]
            L[RainbowKit Provider]
            M[QueryClient Provider]
        end
    end

    %% Blockchain Layer
    subgraph "Smart Contracts (Ethereum/Local)"
        subgraph "PollManager Contract"
            N[Poll Creation]
            O[Token Minting]
            P[Voting Logic]
            Q[Poll Storage]
            R[Vote Counting]
        end
        
        subgraph "VotingToken Contract (ERC20)"
            S[Token Minting]
            T[Token Burning]
            U[Token Transfer]
            V[Balance Tracking]
        end
        
        subgraph "Contract State"
            W[polls Array]
            X[hasVoted Mapping]
            Y[voteCounts Mapping]
            Z[hasMintedForPoll Mapping]
        end
    end

    %% Data Flow
    D --> K
    K --> H
    H --> |Contract Calls| N
    H --> |Read Functions| Q
    
    N --> W
    O --> S
    P --> X
    P --> Y
    R --> Y
    
    G --> |Check Connection| C
    I --> |Poll ID| H
    H --> |Poll Data| E
    
    %% Contract Interactions
    N --> |Creates| W
    O --> |Mints to User| S
    P --> |Records Vote| X
    P --> |Updates Count| Y
    P --> |Burns Token| T

    %% Events
    subgraph "Events"
        AA[PollCreated Event]
        BB[TokenMinted Event]
        CC[VoteCast Event]
    end
    
    N --> AA
    O --> BB
    P --> CC

    %% Styling
    classDef frontend fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef contract fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef event fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    
    class A,B,C,D,E,F,G,H,I,J,K,L,M frontend
    class N,O,P,Q,R,S,T,U,V contract
    class W,X,Y,Z storage
    class AA,BB,CC event
```

## User Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Wallet
    participant PollManager
    participant VotingToken

    %% Connection Flow
    User->>Frontend: Access Application
    Frontend->>User: Display Connect Button
    User->>Wallet: Connect Wallet
    Wallet->>Frontend: Wallet Connected
    Frontend->>PollManager: Check Total Polls
    PollManager->>Frontend: Return Poll Count

    %% Poll Query Flow
    User->>Frontend: Enter Poll ID
    Frontend->>PollManager: Query Poll Details
    PollManager->>Frontend: Return Poll Data
    Frontend->>PollManager: Check Poll Status
    PollManager->>Frontend: Return Open/Closed Status
    Frontend->>User: Display Poll Information

    %% Voting Flow (Future Enhancement)
    Note over User,VotingToken: Voting Flow (Not implemented in current UI)
    User->>PollManager: Mint Voting Token
    PollManager->>VotingToken: Mint Token to User
    VotingToken->>User: Token Minted
    User->>PollManager: Cast Vote
    PollManager->>VotingToken: Burn Voting Token
    PollManager->>PollManager: Record Vote
    PollManager->>User: Vote Confirmed
```

## Smart Contract Architecture

```mermaid
classDiagram
    class PollManager {
        +Poll[] polls
        +VotingToken votingToken
        +mapping hasVoted
        +mapping voteCounts
        +mapping hasMintedForPoll
        +createPoll(title, options, duration)
        +mintVotingToken(pollId)
        +vote(pollId, optionIndex)
        +getTotalPolls()
        +pollDetails(pollId)
        +isPollOpen(pollId)
        +getVoteCount(pollId, option)
    }
    
    class VotingToken {
        +string name
        +string symbol
        +uint256 totalSupply
        +mint(to, amount)
        +burn(amount)
        +transfer(to, amount)
        +balanceOf(account)
    }
    
    class Poll {
        +uint256 id
        +string title
        +string[] options
        +uint256 deadline
    }
    
    class Ownable {
        +address owner
        +onlyOwner modifier
        +transferOwnership(newOwner)
    }
    
    class ERC20 {
        +mapping balances
        +mapping allowances
        +transfer(to, amount)
        +approve(spender, amount)
        +transferFrom(from, to, amount)
    }
    
    PollManager --> Poll : contains
    PollManager --> VotingToken : uses
    PollManager --|> Ownable : inherits
    VotingToken --|> ERC20 : inherits
    VotingToken --|> Ownable : inherits
```

## Component Architecture

```mermaid
graph TD
    subgraph "Next.js Application"
        A[layout.tsx] --> B[Providers.tsx]
        B --> C[page.tsx]
        C --> D[PollManager.tsx]
        
        subgraph "Providers Setup"
            E[WagmiProvider]
            F[QueryClientProvider]
            G[RainbowKitProvider]
        end
        
        subgraph "Configuration"
            H[RainbowKitConfig.tsx]
            I[Contract ABIs]
        end
        
        B --> E
        E --> F
        F --> G
        H --> E
        I --> D
    end
    
    subgraph "External Dependencies"
        J[RainbowKit]
        K[Wagmi]
        L[TanStack Query]
        M[Ethereum Wallet]
    end
    
    G --> J
    E --> K
    F --> L
    D --> M

    classDef component fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef provider fill:#f1f8e9,stroke:#558b2f,stroke-width:2px
    classDef external fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    
    class A,C,D,H,I component
    class B,E,F,G provider
    class J,K,L,M external
```

## Key Features & Functions

### Smart Contract Functions

- **Poll Management**: Create polls with title, options, and deadline
- **Token System**: ERC20 voting tokens minted per poll
- **Voting Logic**: One vote per token, token burned after voting
- **Access Control**: Owner-only poll creation
- **State Tracking**: Vote counts, user participation status

### Frontend Features

- **Wallet Integration**: RainbowKit for seamless wallet connection
- **Real-time Data**: Live poll status and details fetching
- **Responsive UI**: Modern design with Tailwind CSS
- **Error Handling**: Comprehensive error states and loading indicators
- **Poll Display**: Detailed poll information including status and deadline

### Technology Stack

- **Smart Contracts**: Solidity, Foundry, OpenZeppelin
- **Frontend**: Next.js, TypeScript, Tailwind CSS
- **Web3 Integration**: Wagmi, RainbowKit, TanStack Query
- **Development**: Local Ethereum node, TypeScript configuration
