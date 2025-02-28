;; EcoPulse - Sustainability Tracking Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-goal (err u103))
(define-constant err-invalid-date (err u104))
(define-constant err-list-full (err u105))

;; Data Variables 
(define-data-var total-organizations uint u0)

;; Data Maps
[... remaining maps stay the same ...]

;; Helper functions
(define-private (validate-date (month uint) (year uint))
  (and
    (>= month u1)
    (<= month u12)
    (>= year u2000)
    (<= year u9999)
  )
)

(define-private (can-append-achievement (achievement-data {
  milestones: (list 10 (string-ascii 100)),
  dates: (list 10 uint),
  points-earned: (list 10 uint)
}))
  (< (len (get milestones achievement-data)) u10)
)

;; Modified public functions

;; Award achievement (now owner-only)
(define-public (award-achievement (org principal) (milestone (string-ascii 100)) (points uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let
      (
        (org-data (unwrap! (map-get? organizations org) err-not-found))
        (achievement-data (unwrap! (map-get? achievements org) err-not-found))
      )
      (asserts! (can-append-achievement achievement-data) err-list-full)
      (begin
        (map-set achievements org {
          milestones: (append (get milestones achievement-data) milestone),
          dates: (append (get dates achievement-data) block-height),
          points-earned: (append (get points-earned achievement-data) points)
        })
        (map-set organizations org 
          (merge org-data {
            eco-points: (+ (get eco-points org-data) points),
            total-achievements: (+ (get total-achievements org-data) u1)
          })
        )
        (ok true)
      )
    )
  )
)

;; Record monthly metrics with validation
(define-public (record-monthly-metrics (year uint) (month uint) (energy uint) (waste uint))
  (begin
    (asserts! (validate-date month year) err-invalid-date)
    (let
      (
        (org-data (unwrap! (map-get? organizations tx-sender) err-not-found))
        (metrics {
          energy-usage: energy,
          waste-produced: waste,
          goals-met: u0
        })
        (goals (map-get? sustainability-goals tx-sender))
      )
      [... rest of function remains the same ...]
    )
  )
)

[... remaining functions stay the same ...]
