;; EcoPulse - Sustainability Tracking Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-goal (err u103))
(define-constant err-invalid-date (err u104))
(define-constant err-list-full (err u105))
(define-constant err-invalid-points (err u106))
(define-constant max-points-per-achievement u1000)

;; Data Variables 
(define-data-var total-organizations uint u0)

;; Helper functions
(define-private (validate-date (month uint) (year uint))
  (and
    (>= month u1)
    (<= month u12)
    (>= year u2000)
    (<= year u9999)
  )
)

(define-private (validate-points (points uint))
  (<= points max-points-per-achievement)
)

(define-private (can-append-achievement (achievement-data {
  milestones: (list 10 (string-ascii 100)),
  dates: (list 10 uint),
  points-earned: (list 10 uint)
}))
  (< (len (get milestones achievement-data)) u10)
)

;; Award achievement with enhanced validation
(define-public (award-achievement (org principal) (milestone (string-ascii 100)) (points uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (validate-points points) err-invalid-points)
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

[... remaining functions stay the same ...]
