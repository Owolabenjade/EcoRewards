# EcoRewards Protocol

A deflationary token system designed for carbon credit marketplace on the Stacks blockchain, featuring dynamic supply control and automated burning mechanisms.

## Features

### Core Token Features
- Fixed initial cap of 1 billion tokens
- 6 decimal places precision
- Pausable functionality for emergency situations
- Administrator controls for system management

### Dynamic Supply Control
- Automated burning on transfers (configurable rate)
- Dynamic cap adjustment based on burning thresholds
- Supply optimization through burn exemptions
- Configurable burn rate (max 10%)

### Business Integration
- Business registration system
- Carbon credits tracking
- Verification timestamps
- Business information management

### Security Features
- Input validation for all critical operations
- Administrative access controls
- Emergency functions for crisis management
- Automated balance checks
- Pausing mechanism for emergencies

## Functions

### Administrative
```clarity
set-administrator             ;; Update contract administrator
pause-contract               ;; Pause all contract operations
unpause-contract            ;; Resume contract operations
```

### Business Management
```clarity
register-business            ;; Register new business with carbon credits
get-business-info           ;; Retrieve business information
```

### Supply Control
```clarity
adjust-cap                  ;; Modify the token cap
update-burn-rate           ;; Update the burning percentage
set-burn-exemption         ;; Set burning exemptions for addresses
```

### Token Operations
```clarity
mint                       ;; Create new tokens (admin only)
transfer                   ;; Transfer tokens with automatic burning
emergency-burn            ;; Emergency token burning
emergency-transfer        ;; Emergency transfer function
```

### Read-Only Functions
```clarity
get-name                   ;; Get token name
get-symbol                 ;; Get token symbol
get-decimals               ;; Get decimal places
get-balance               ;; Get account balance
get-total-supply          ;; Get current total supply
get-current-cap           ;; Get current supply cap
get-burn-rate             ;; Get current burn rate
is-exempted               ;; Check if address is burn-exempted
```

## Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized operation
- `ERR-INSUFFICIENT-BALANCE (u101)`: Insufficient balance for operation
- `ERR-CAP-REACHED (u102)`: Supply cap reached
- `ERR-INVALID-AMOUNT (u103)`: Invalid amount specified
- `ERR-NOT-ADMINISTRATOR (u104)`: Not administrator
- `ERR-ALREADY-REGISTERED (u105)`: Business already registered
- `ERR-INVALID-PARAMETER (u106)`: Invalid parameter provided
- `ERR-INVALID-RECIPIENT (u107)`: Invalid recipient address
- `ERR-EMPTY-NAME (u109)`: Empty business name

## Usage

1. Deploy the contract on Stacks blockchain
2. Initialize administrator
3. Register businesses with initial carbon credits
4. Configure burn exemptions if needed
5. Monitor and adjust burn rates as necessary

## Security Considerations

- Administrative functions are protected
- Input validation for all operations
- Emergency controls available
- Pausing mechanism for critical situations
- Balance checks before transfers
- Dynamic cap adjustments with safety checks