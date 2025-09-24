;; Title: BitVault - Next-Generation NFT Treasury & Yield Protocol        
;;
;; Summary: Advanced NFT ecosystem enabling secure asset vaulting,        
;; liquidity generation through fractional ownership, and automated       
;; yield distribution on Bitcoin's most secure layer.                     
;;
;; Description: BitVault revolutionizes digital asset management by       
;; combining Bitcoin's unmatched security with Stacks' programmability.   
;; Our protocol introduces collateral-backed NFT minting, seamless        
;; peer-to-peer trading, innovative share-based ownership models, and     
;; a sophisticated staking engine that transforms idle NFTs into          
;; yield-generating assets. Built for institutions and collectors who      
;; demand both security and profitability in their digital portfolios.    

;;                                CONSTANTS

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-LISTING-NOT-FOUND (err u104))
(define-constant ERR-INVALID-PRICE (err u105))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u106))
(define-constant ERR-ALREADY-STAKED (err u107))
(define-constant ERR-NOT-STAKED (err u108))
(define-constant ERR-INVALID-PERCENTAGE (err u109))
(define-constant ERR-INVALID-URI (err u110))
(define-constant ERR-INVALID-RECIPIENT (err u111))
(define-constant ERR-OVERFLOW (err u112))

;;                            PROTOCOL VARIABLES

(define-data-var min-collateral-ratio uint u150) ;; 150% minimum collateral ratio
(define-data-var protocol-fee uint u25) ;; 2.5% fee in basis points
(define-data-var total-staked uint u0)
(define-data-var yield-rate uint u50) ;; 5% annual yield rate in basis points
(define-data-var total-supply uint u0)

;;                               DATA STORAGE

(define-map tokens
  { token-id: uint }
  {
    owner: principal,
    uri: (string-ascii 256),
    collateral: uint,
    is-staked: bool,
    stake-timestamp: uint,
    fractional-shares: uint,
  }
)

(define-map token-listings
  { token-id: uint }
  {
    price: uint,
    seller: principal,
    active: bool,
  }
)

(define-map fractional-ownership
  {
    token-id: uint,
    owner: principal,
  }
  { shares: uint }
)

(define-map staking-rewards
  { token-id: uint }
  {
    accumulated-yield: uint,
    last-claim: uint,
  }
)

;;                          VALIDATION UTILITIES

(define-private (validate-uri (uri (string-ascii 256)))
  (let ((uri-len (len uri)))
    (and
      (> uri-len u0)
      (<= uri-len u256)
    )
  )
)

(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient (as-contract tx-sender)))
)

(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((sum (+ a b)))
    (asserts! (>= sum a) ERR-OVERFLOW)
    (ok sum)
  )
)

;;                           NFT CORE FUNCTIONS

(define-public (mint-nft
    (uri (string-ascii 256))
    (collateral uint)
  )
  (let (
      (token-id (+ (var-get total-supply) u1))
      (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
    )
    (asserts! (validate-uri uri) ERR-INVALID-URI)
    (asserts! (>= (stx-get-balance tx-sender) collateral-requirement)
      ERR-INSUFFICIENT-COLLATERAL
    )
    (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))
    (map-set tokens { token-id: token-id } {
      owner: tx-sender,
      uri: uri,
      collateral: collateral,
      is-staked: false,
      stake-timestamp: u0,
      fractional-shares: u0,
    })
    (var-set total-supply token-id)
    (ok token-id)
  )
)

(define-public (transfer-nft
    (token-id uint)
    (recipient principal)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    (map-set tokens { token-id: token-id } (merge token { owner: recipient }))
    (ok true)
  )
)

;;                          MARKETPLACE FUNCTIONS

(define-public (list-nft
    (token-id uint)
    (price uint)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    (map-set token-listings { token-id: token-id } {
      price: price,
      seller: tx-sender,
      active: true,
    })
    (ok true)
  )
)

(define-public (purchase-nft (token-id uint))
  (let (
      (listing (unwrap! (get-listing token-id) ERR-LISTING-NOT-FOUND))
      (price (get price listing))
      (seller (get seller listing))
      (fee (/ (* price (var-get protocol-fee)) u1000))
    )
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    (asserts! (is-eq (get active listing) true) ERR-LISTING-NOT-FOUND)
    ;; Transfer STX from buyer to seller
    (try! (stx-transfer? price tx-sender seller))
    ;; Transfer protocol fee
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
    ;; Update token ownership
    (try! (transfer-nft token-id tx-sender))
    ;; Clear listing
    (map-set token-listings { token-id: token-id } {
      price: u0,
      seller: seller,
      active: false,
    })
    (ok true)
  )
)

;;                       FRACTIONAL OWNERSHIP SYSTEM

(define-public (transfer-shares
    (token-id uint)
    (recipient principal)
    (share-amount uint)
  )
  (let (
      (sender-shares (unwrap! (get-fractional-shares token-id tx-sender)
        ERR-INSUFFICIENT-BALANCE
      ))
      (current-recipient-shares (default-to { shares: u0 } (get-fractional-shares token-id recipient)))
      (recipient-new-shares (unwrap! (safe-add (get shares current-recipient-shares) share-amount)
        ERR-OVERFLOW
      ))
    )
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (>= (get shares sender-shares) share-amount)
      ERR-INSUFFICIENT-BALANCE
    )
    ;; Update sender's shares
    (map-set fractional-ownership {
      token-id: token-id,
      owner: tx-sender,
    } { shares: (- (get shares sender-shares) share-amount) }
    )
    ;; Update recipient's shares
    (map-set fractional-ownership {
      token-id: token-id,
      owner: recipient,
    } { shares: recipient-new-shares }
    )
    (ok true)
  )
)

;;                           STAKING MECHANISMS

(define-public (stake-nft (token-id uint))
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: true,
        stake-timestamp: stacks-block-height,
      })
    )
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })
    (var-set total-staked (+ (var-get total-staked) u1))
    (ok true)
  )
)

(define-public (unstake-nft (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
      (rewards (unwrap! (get-staking-rewards token-id) ERR-NOT-STAKED))
    )
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (get is-staked token) ERR-NOT-STAKED)
    ;; Calculate and distribute final rewards
    (try! (claim-staking-rewards token-id))
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: false,
        stake-timestamp: u0,
      })
    )
    (var-set total-staked (- (var-get total-staked) u1))
    (ok true)
  )
)

;;                            QUERY FUNCTIONS

(define-read-only (get-token-info (token-id uint))
  (map-get? tokens { token-id: token-id })
)

(define-read-only (get-listing (token-id uint))
  (map-get? token-listings { token-id: token-id })
)

(define-read-only (get-fractional-shares
    (token-id uint)
    (owner principal)
  )
  (map-get? fractional-ownership {
    token-id: token-id,
    owner: owner,
  })
)

(define-read-only (get-staking-rewards (token-id uint))
  (map-get? staking-rewards { token-id: token-id })
)

(define-read-only (calculate-rewards (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
      (rewards (unwrap! (get-staking-rewards token-id) ERR-NOT-STAKED))
      (blocks-staked (- stacks-block-height (get stake-timestamp token)))
      (yield-per-block (/ (var-get yield-rate) u52560)) ;; Approximate blocks per year
      (new-rewards (* blocks-staked yield-per-block))
    )
    (ok (+ (get accumulated-yield rewards) new-rewards))
  )
)

;;                           INTERNAL FUNCTIONS

(define-private (claim-staking-rewards (token-id uint))
  (let (
      (rewards (unwrap! (calculate-rewards token-id) ERR-NOT-STAKED))
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
    )
    (asserts! (get is-staked token) ERR-NOT-STAKED)
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })
    ;; Transfer rewards in STX
    (as-contract (stx-transfer? rewards (as-contract tx-sender) (get owner token)))
  )
)
