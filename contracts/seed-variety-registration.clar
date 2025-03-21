;; Seed Variety Registration Contract
;; Records details of heirloom plant varieties

(define-data-var admin principal tx-sender)

;; Data Maps
(define-map seed-varieties
  { variety-id: uint }
  {
    name: (string-utf8 100),
    species: (string-utf8 100),
    origin: (string-utf8 100),
    description: (string-utf8 500),
    year-documented: uint,
    rarity-level: uint,
    registered-by: principal,
    registration-date: uint,
    active: bool
  }
)

(define-map variety-stewards
  { variety-id: uint, steward: principal }
  {
    since: uint,
    active: bool
  }
)

;; Counter for variety IDs
(define-data-var next-variety-id uint u1)

;; Public Functions
(define-public (register-variety
    (name (string-utf8 100))
    (species (string-utf8 100))
    (origin (string-utf8 100))
    (description (string-utf8 500))
    (year-documented uint)
    (rarity-level uint)
  )
  (let
    (
      (caller tx-sender)
      (variety-id (var-get next-variety-id))
      (current-block-height block-height)
    )
    (begin
      ;; Validate rarity level (1-5 scale)
      (asserts! (<= rarity-level u5) (err u1))

      ;; Register the variety
      (map-set seed-varieties
        { variety-id: variety-id }
        {
          name: name,
          species: species,
          origin: origin,
          description: description,
          year-documented: year-documented,
          rarity-level: rarity-level,
          registered-by: caller,
          registration-date: current-block-height,
          active: true
        }
      )

      ;; Add the registrant as the first steward
      (map-set variety-stewards
        { variety-id: variety-id, steward: caller }
        {
          since: current-block-height,
          active: true
        }
      )

      ;; Increment the variety ID counter
      (var-set next-variety-id (+ variety-id u1))

      ;; Return the new variety ID
      (ok variety-id)
    )
  )
)

(define-public (update-variety-details
    (variety-id uint)
    (name (string-utf8 100))
    (description (string-utf8 500))
    (rarity-level uint)
  )
  (let
    (
      (caller tx-sender)
      (variety-opt (map-get? seed-varieties { variety-id: variety-id }))
    )
    (begin
      ;; Check if variety exists
      (asserts! (is-some variety-opt) (err u2))

      ;; Check if caller is a steward
      (asserts! (is-steward variety-id caller) (err u3))

      ;; Validate rarity level (1-5 scale)
      (asserts! (<= rarity-level u5) (err u1))

      ;; Update the variety details
      (map-set seed-varieties
        { variety-id: variety-id }
        (merge (unwrap-panic variety-opt)
          {
            name: name,
            description: description,
            rarity-level: rarity-level
          }
        )
      )

      (ok true)
    )
  )
)

(define-public (add-steward (variety-id uint) (new-steward principal))
  (let
    (
      (caller tx-sender)
      (variety-opt (map-get? seed-varieties { variety-id: variety-id }))
    )
    (begin
      ;; Check if variety exists
      (asserts! (is-some variety-opt) (err u2))

      ;; Check if caller is a steward
      (asserts! (is-steward variety-id caller) (err u3))

      ;; Add the new steward
      (map-set variety-stewards
        { variety-id: variety-id, steward: new-steward }
        {
          since: block-height,
          active: true
        }
      )

      (ok true)
    )
  )
)

(define-public (deactivate-variety (variety-id uint))
  (let
    (
      (caller tx-sender)
      (variety-opt (map-get? seed-varieties { variety-id: variety-id }))
    )
    (begin
      ;; Check if variety exists
      (asserts! (is-some variety-opt) (err u2))

      ;; Check if caller is a steward
      (asserts! (is-steward variety-id caller) (err u3))

      ;; Deactivate the variety
      (map-set seed-varieties
        { variety-id: variety-id }
        (merge (unwrap-panic variety-opt) { active: false })
      )

      (ok true)
    )
  )
)

;; Read-only Functions
(define-read-only (get-variety (variety-id uint))
  (map-get? seed-varieties { variety-id: variety-id })
)

(define-read-only (is-steward (variety-id uint) (user principal))
  (let
    (
      (steward-data (map-get? variety-stewards { variety-id: variety-id, steward: user }))
    )
    (and
      (is-some steward-data)
      (get active (unwrap-panic steward-data))
    )
  )
)

(define-read-only (get-next-variety-id)
  (var-get next-variety-id)
)
