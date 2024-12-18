;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-CAP-REACHED (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-NOT-ADMINISTRATOR (err u104))
(define-constant ERR-ALREADY-REGISTERED (err u105))
(define-constant ERR-INVALID-PARAMETER (err u106))
(define-constant ERR-INVALID-RECIPIENT (err u107))
(define-constant ERR-INVALID-PRINCIPAL (err u108))
(define-constant ERR-EMPTY-NAME (err u109))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant TOKEN-NAME "EcoRewards")
(define-constant TOKEN-SYMBOL "ECO")
(define-constant TOKEN-DECIMALS u6)
(define-constant INITIAL-CAP u1000000000000000) ;; 1 billion tokens with 6 decimals
(define-constant BURN-THRESHOLD-PERCENTAGE u100) ;; 10% threshold for cap adjustment
(define-constant MAX-BURN-RATE u100) ;; Maximum 10% burn rate

;; Data Variables
(define-data-var administrator principal CONTRACT-OWNER)
(define-data-var total-supply uint u0)
(define-data-var current-cap uint INITIAL-CAP)
(define-data-var burn-rate uint u5) ;; 0.5% default burn rate (multiplied by 10)
(define-data-var paused bool false)
(define-data-var burn-threshold uint u100000000000000) ;; 10% of total supply

;; Data Maps
(define-map balances principal uint)
(define-map burn-exemptions principal bool)
(define-map allowances {owner: principal, spender: principal} uint)
(define-map verified-businesses 
    principal 
    {
        business-name: (string-ascii 64),
        verification-date: uint,
        carbon-credits: uint
    }
)

;; Private functions
(define-private (check-recipient (recipient principal))
    (ok (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-RECIPIENT)))

(define-private (check-name-length (name (string-ascii 64)))
    (ok (asserts! (> (len name) u0) ERR-EMPTY-NAME)))

;; Read-only functions
(define-read-only (get-name)
    (ok TOKEN-NAME))

(define-read-only (get-symbol)
    (ok TOKEN-SYMBOL))

(define-read-only (get-decimals)
    (ok TOKEN-DECIMALS))

(define-read-only (get-balance (account principal))
    (ok (default-to u0 (map-get? balances account))))

(define-read-only (get-total-supply)
    (ok (var-get total-supply)))

(define-read-only (get-current-cap)
    (ok (var-get current-cap)))

(define-read-only (get-burn-rate)
    (ok (var-get burn-rate)))

(define-read-only (is-exempted (account principal))
    (default-to false (map-get? burn-exemptions account)))

(define-read-only (get-business-info (business principal))
    (map-get? verified-businesses business))

;; Administrative functions
(define-public (set-administrator (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (try! (check-recipient new-admin))
        (var-set administrator new-admin)
        (ok true)))

(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (var-set paused true)
        (ok true)))

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (var-set paused false)
        (ok true)))

;; Business verification functions
(define-public (register-business (business principal) (name (string-ascii 64)) (initial-credits uint))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (is-none (map-get? verified-businesses business)) ERR-ALREADY-REGISTERED)
        (try! (check-recipient business))
        (try! (check-name-length name))
        
        (map-set verified-businesses
            business
            {
                business-name: name,
                verification-date: block-height,
                carbon-credits: initial-credits
            })
        (ok true)))

;; Supply control functions
(define-public (adjust-cap (new-cap uint))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
        (asserts! (>= new-cap (var-get total-supply)) ERR-INVALID-AMOUNT)
        (var-set current-cap new-cap)
        (ok true)))

(define-public (update-burn-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (<= new-rate MAX-BURN-RATE) ERR-INVALID-PARAMETER)
        (var-set burn-rate new-rate)
        (ok true)))

(define-public (set-burn-exemption (address principal) (exempt bool))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (try! (check-recipient address))
        (map-set burn-exemptions address exempt)
        (ok true)))

;; Token operations
(define-public (mint (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
        (asserts! (<= (+ (var-get total-supply) amount) (var-get current-cap)) ERR-CAP-REACHED)
        (try! (check-recipient recipient))
        
        (map-set balances
            recipient
            (+ (default-to u0 (map-get? balances recipient)) amount))
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok true)))

(define-public (transfer (amount uint) (recipient principal))
    (let (
        (sender-balance (default-to u0 (map-get? balances tx-sender)))
        (burn-amount (if (is-exempted tx-sender)
            u0
            (/ (* amount (var-get burn-rate)) u1000)))
        (transfer-amount (- amount burn-amount))
    )
    (begin
        (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
        (asserts! (>= sender-balance amount) ERR-INSUFFICIENT-BALANCE)
        (try! (check-recipient recipient))
        
        ;; Process burning
        (if (> burn-amount u0)
            (begin
                (var-set total-supply (- (var-get total-supply) burn-amount))
                
                ;; Adjust cap if burn threshold is reached
                (if (>= burn-amount (var-get burn-threshold))
                    (var-set current-cap (- (var-get current-cap) burn-amount))
                    true)
            )
            true)
        
        ;; Process transfer
        (map-set balances
            tx-sender
            (- sender-balance amount))
        
        (map-set balances
            recipient
            (+ (default-to u0 (map-get? balances recipient)) transfer-amount))
        
        (ok true))))

;; Emergency functions
(define-public (emergency-burn (amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (<= amount (var-get total-supply)) ERR-INSUFFICIENT-BALANCE)
        
        (var-set total-supply (- (var-get total-supply) amount))
        (var-set current-cap (- (var-get current-cap) amount))
        (ok true)))

(define-public (emergency-transfer (from principal) (to principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get administrator)) ERR-NOT-ADMINISTRATOR)
        (asserts! (>= (default-to u0 (map-get? balances from)) amount) ERR-INSUFFICIENT-BALANCE)
        (try! (check-recipient to))
        
        (map-set balances
            from
            (- (default-to u0 (map-get? balances from)) amount))
        
        (map-set balances
            to
            (+ (default-to u0 (map-get? balances to)) amount))
        (ok true)))