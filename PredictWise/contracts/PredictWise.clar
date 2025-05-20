;; PredictWise: AI-Decentralized Prediction Market Smart Contract
;; This contract allows users to create prediction markets, participate in them,
;; and resolve them based on real-world outcomes.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MARKET-CLOSED (err u101))
(define-constant ERR-MARKET-NOT-RESOLVED (err u102))
(define-constant ERR-INVALID-OUTCOME (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-MARKET-NOT-FOUND (err u105))
(define-constant ERR-ALREADY-RESOLVED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-DEADLINE-PASSED (err u108))

;; Data structures
(define-map markets
  { market-id: uint }
  {
    creator: principal,
    question: (string-utf8 256),
    description: (string-utf8 1024),
    possible-outcomes: (list 10 (string-utf8 64)),
    resolution-deadline: uint,
    participation-deadline: uint,
    resolved: bool,
    winning-outcome: (optional uint),
    total-stake: uint,
    oracle: principal
  }
)

(define-map market-stakes
  { market-id: uint, outcome: uint }
  { total-stake: uint }
)

(define-map user-stakes
  { market-id: uint, user: principal, outcome: uint }
  { amount: uint }
)

(define-data-var market-nonce uint u0)

;; Read-only functions
(define-read-only (get-market (market-id uint))
  (map-get? markets { market-id: market-id })
)

(define-read-only (get-market-stake (market-id uint) (outcome uint))
  (default-to { total-stake: u0 }
    (map-get? market-stakes { market-id: market-id, outcome: outcome })
  )
)

(define-read-only (get-user-stake (market-id uint) (user principal) (outcome uint))
  (default-to { amount: u0 }
    (map-get? user-stakes { market-id: market-id, user: user, outcome: outcome })
  )
)

(define-read-only (get-next-market-id)
  (var-get market-nonce)
)

;; Create a new prediction market
(define-public (create-market 
                (question (string-utf8 256)) 
                (description (string-utf8 1024))
                (possible-outcomes (list 10 (string-utf8 64)))
                (participation-deadline uint)
                (resolution-deadline uint)
                (oracle principal))
  (let ((market-id (var-get market-nonce)))
    ;; Validate inputs
    (asserts! (> (len possible-outcomes) u0) ERR-INVALID-OUTCOME)
    (asserts! (> participation-deadline block-height) ERR-DEADLINE-PASSED)
    (asserts! (> resolution-deadline participation-deadline) ERR-DEADLINE-PASSED)
    
    ;; Create the market
    (map-set markets
      { market-id: market-id }
      {
        creator: tx-sender,
        question: question,
        description: description,
        possible-outcomes: possible-outcomes,
        resolution-deadline: resolution-deadline,
        participation-deadline: participation-deadline,
        resolved: false,
        winning-outcome: none,
        total-stake: u0,
        oracle: oracle
      }
    )
    
    ;; Increment the market nonce
    (var-set market-nonce (+ market-id u1))
    
    ;; Return the market ID
    (ok market-id)
  )
)

;; Place a stake on a specific outcome
(define-public (place-stake (market-id uint) (outcome uint) (amount uint))
  (let (
    (market (unwrap! (get-market market-id) ERR-MARKET-NOT-FOUND))
    (current-stake (get-user-stake market-id tx-sender outcome))
  )
    ;; Validate inputs
    (asserts! (< block-height (get participation-deadline market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (< outcome (len (get possible-outcomes market))) ERR-INVALID-OUTCOME)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer tokens from user to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update market stakes
    (let (
      (market-stake (get-market-stake market-id outcome))
      (new-market-stake (+ (get total-stake market-stake) amount))
      (new-total-stake (+ (get total-stake market) amount))
      (new-user-stake (+ (get amount current-stake) amount))
    )
      (map-set market-stakes
        { market-id: market-id, outcome: outcome }
        { total-stake: new-market-stake }
      )
      
      (map-set user-stakes
        { market-id: market-id, user: tx-sender, outcome: outcome }
        { amount: new-user-stake }
      )
      
      (map-set markets
        { market-id: market-id }
        (merge market { total-stake: new-total-stake })
      )
      
      (ok true)
    )
  )
)

;; Resolve a market (can only be called by the oracle)
(define-public (resolve-market (market-id uint) (winning-outcome uint))
  (let ((market (unwrap! (get-market market-id) ERR-MARKET-NOT-FOUND)))
    ;; Validate inputs
    (asserts! (is-eq tx-sender (get oracle market)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (< winning-outcome (len (get possible-outcomes market))) ERR-INVALID-OUTCOME)
    
    ;; Update market as resolved
    (map-set markets
      { market-id: market-id }
      (merge market { 
        resolved: true,
        winning-outcome: (some winning-outcome)
      })
    )
    
    (ok true)
  )
)

;; Claim rewards for a resolved market
(define-public (claim-rewards (market-id uint))
  (let (
    (market (unwrap! (get-market market-id) ERR-MARKET-NOT-FOUND))
    (winning-outcome (unwrap! (get winning-outcome market) ERR-MARKET-NOT-RESOLVED))
  )
    ;; Validate market is resolved
    (asserts! (get resolved market) ERR-MARKET-NOT-RESOLVED)
    
    ;; Calculate reward
    (let (
      (user-stake (get amount (get-user-stake market-id tx-sender winning-outcome)))
      (total-winning-stake (get total-stake (get-market-stake market-id winning-outcome)))
      (total-market-stake (get total-stake market))
    )
      ;; Ensure user has a stake in the winning outcome
      (asserts! (> user-stake u0) ERR-INSUFFICIENT-FUNDS)
      
      ;; Calculate proportional reward
      (let ((reward (/ (* user-stake total-market-stake) total-winning-stake)))
        ;; Transfer reward to user
        (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
        
        ;; Reset user stake to prevent double claiming
        (map-set user-stakes
          { market-id: market-id, user: tx-sender, outcome: winning-outcome }
          { amount: u0 }
        )
        
        (ok reward)
      )
    )
  )
)

;; Advanced market analytics and reporting function
(define-public (generate-market-analytics-report (market-id uint))
  (let (
    (market (unwrap! (get-market market-id) ERR-MARKET-NOT-FOUND))
    (outcomes-count (len (get possible-outcomes market)))
    (total-participants u0)
    (participation-rate u0)
    (market-confidence-score u0)
    (market-volatility u0)
    (outcome-distribution (list))
  )
    ;; Calculate total unique participants
    ;; This would require iterating through all stakes, but for simplicity
    ;; we'll use a placeholder calculation
    (let (
      (estimated-participants (/ (get total-stake market) u1000000))
      (participation-score (if (> estimated-participants u100) 
                              u100 
                              estimated-participants))
      (market-age (- block-height (- (get participation-deadline market) u10000)))
      (time-remaining (- (get resolution-deadline market) block-height))
      (market-maturity-factor (/ (* market-age u100) (+ market-age time-remaining)))
      (outcome-stakes (list))
      (highest-stake u0)
      (lowest-stake u0)
      (avg-stake u0)
    )
      ;; Calculate stakes for each outcome
      ;; In a real implementation, we would iterate through each outcome
      ;; For simplicity, we'll use placeholder calculations
      
      ;; Calculate market confidence score based on stake distribution
      ;; Higher concentration in fewer outcomes indicates higher confidence
      (let (
        (confidence-base (if (get resolved market) u90 u75))
        (time-factor (/ (* time-remaining u25) (- (get resolution-deadline market) 
                                                 (- (get participation-deadline market) u10000))))
        (stake-factor (if (> (get total-stake market) u1000000000) 
                         u25 
                         (/ (* (get total-stake market) u25) u1000000000)))
        (final-confidence-score (+ confidence-base (/ (+ time-factor stake-factor) u2)))
        (volatility-base (- u100 final-confidence-score))
        (volatility-factor (if (< market-age u1000) 
                             (+ volatility-base u20) 
                             (- volatility-base u10)))
        (final-volatility (if (< volatility-factor u5) u5 volatility-factor))
      )
        ;; Generate report data
        (let (
          (report-data {
            market-id: market-id,
            question: (get question market),
            total-stake: (get total-stake market),
            estimated-participants: estimated-participants,
            participation-score: participation-score,
            market-maturity: market-maturity-factor,
            confidence-score: final-confidence-score,
            volatility: final-volatility,
            resolved: (get resolved market),
            winning-outcome: (get winning-outcome market)
          })
        )
          ;; In a real implementation, we would store this report
          ;; For now, we'll just return the data
          (ok report-data)
        )
      )
    )
  )
)

