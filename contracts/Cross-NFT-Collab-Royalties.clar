;; Cross-NFT Collab Royalties Smart Contract
;; Revenue split among creators when two NFT projects merge

;; Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PERCENTAGE (err u101))
(define-constant ERR-COLLAB-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))

;; Data Variables
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map collaborations
  { project-a: principal, project-b: principal }
  {
    creator-a: principal,
    creator-b: principal,
    split-percentage-a: uint,
    split-percentage-b: uint,
    total-revenue: uint,
    is-active: bool
  }
)

(define-map revenue-balances
  { collaboration-id: { project-a: principal, project-b: principal }, creator: principal }
  { balance: uint }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (validate-split-percentage (percentage-a uint) (percentage-b uint))
  (is-eq (+ percentage-a percentage-b) u100)
)

;; Public Functions

;; Create a new collaboration between two NFT projects
(define-public (create-collaboration 
  (project-a principal)
  (project-b principal)
  (creator-a principal)
  (creator-b principal)
  (split-percentage-a uint)
  (split-percentage-b uint)
)
  (let ((collab-id { project-a: project-a, project-b: project-b }))
    (asserts! (validate-split-percentage split-percentage-a split-percentage-b) ERR-INVALID-PERCENTAGE)
    (asserts! (is-none (map-get? collaborations collab-id)) ERR-ALREADY-EXISTS)

    (map-set collaborations collab-id
      {
        creator-a: creator-a,
        creator-b: creator-b,
        split-percentage-a: split-percentage-a,
        split-percentage-b: split-percentage-b,
        total-revenue: u0,
        is-active: true
      }
    )

    (map-set revenue-balances { collaboration-id: collab-id, creator: creator-a } { balance: u0 })
    (map-set revenue-balances { collaboration-id: collab-id, creator: creator-b } { balance: u0 })

    (ok collab-id)
  )
)

;; Distribute revenue from NFT sales/royalties
(define-public (distribute-revenue
  (project-a principal)
  (project-b principal)
  (amount uint)
)
  (let (
    (collab-id { project-a: project-a, project-b: project-b })
    (collab-data (unwrap! (map-get? collaborations collab-id) ERR-COLLAB-NOT-FOUND))
  )
    (asserts! (get is-active collab-data) ERR-COLLAB-NOT-FOUND)

    (let (
      (creator-a (get creator-a collab-data))
      (creator-b (get creator-b collab-data))
      (split-a (get split-percentage-a collab-data))
      (split-b (get split-percentage-b collab-data))
      (amount-a (/ (* amount split-a) u100))
      (amount-b (/ (* amount split-b) u100))
      (current-balance-a (default-to { balance: u0 } 
        (map-get? revenue-balances { collaboration-id: collab-id, creator: creator-a })))
      (current-balance-b (default-to { balance: u0 } 
        (map-get? revenue-balances { collaboration-id: collab-id, creator: creator-b })))
    )

      (map-set revenue-balances 
        { collaboration-id: collab-id, creator: creator-a }
        { balance: (+ (get balance current-balance-a) amount-a) }
      )

      (map-set revenue-balances 
        { collaboration-id: collab-id, creator: creator-b }
        { balance: (+ (get balance current-balance-b) amount-b) }
      )

      (map-set collaborations collab-id
        (merge collab-data { total-revenue: (+ (get total-revenue collab-data) amount) })
      )

      (ok { amount-a: amount-a, amount-b: amount-b })
    )
  )
)

;; Withdraw accumulated revenue
(define-public (withdraw-revenue
  (project-a principal)
  (project-b principal)
  (creator principal)
)
  (let (
    (collab-id { project-a: project-a, project-b: project-b })
    (collab-data (unwrap! (map-get? collaborations collab-id) ERR-COLLAB-NOT-FOUND))
    (balance-data (unwrap! (map-get? revenue-balances { collaboration-id: collab-id, creator: creator }) 
                           ERR-COLLAB-NOT-FOUND))
    (withdrawal-amount (get balance balance-data))
  )
    (asserts! (or (is-eq tx-sender creator) (is-contract-owner)) ERR-UNAUTHORIZED)
    (asserts! (> withdrawal-amount u0) ERR-INSUFFICIENT-FUNDS)

    (try! (stx-transfer? withdrawal-amount tx-sender creator))

    (map-set revenue-balances 
      { collaboration-id: collab-id, creator: creator }
      { balance: u0 }
    )

    (ok withdrawal-amount)
  )
)

;; Deactivate a collaboration
(define-public (deactivate-collaboration
  (project-a principal)
  (project-b principal)
)
  (let (
    (collab-id { project-a: project-a, project-b: project-b })
    (collab-data (unwrap! (map-get? collaborations collab-id) ERR-COLLAB-NOT-FOUND))
  )
    (asserts! (or (is-eq tx-sender (get creator-a collab-data))
                  (is-eq tx-sender (get creator-b collab-data))
                  (is-contract-owner)) ERR-UNAUTHORIZED)

    (map-set collaborations collab-id
      (merge collab-data { is-active: false })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get collaboration details
(define-read-only (get-collaboration
  (project-a principal)
  (project-b principal)
)
  (map-get? collaborations { project-a: project-a, project-b: project-b })
)

;; Get creator's revenue balance
(define-read-only (get-revenue-balance
  (project-a principal)
  (project-b principal)
  (creator principal)
)
  (default-to { balance: u0 }
    (map-get? revenue-balances { collaboration-id: { project-a: project-a, project-b: project-b }, creator: creator })
  )
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)