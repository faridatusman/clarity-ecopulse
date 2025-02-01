;; EcoPulse - Sustainability Tracking Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-goal (err u103))

;; Data Variables 
(define-data-var total-organizations uint u0)

;; Data Maps
(define-map organizations principal
  {
    name: (string-ascii 50),
    eco-points: uint,
    total-energy: uint,
    total-waste: uint,
    total-achievements: uint
  }
)

(define-map monthly-metrics (tuple (org principal) (year uint) (month uint))
  {
    energy-usage: uint,
    waste-produced: uint,
    goals-met: uint
  }
)

(define-map sustainability-goals principal
  {
    energy-target: uint,
    waste-target: uint,
    points-threshold: uint,
    active: bool
  }
)

(define-map achievements principal 
  {
    milestones: (list 10 (string-ascii 100)),
    dates: (list 10 uint),
    points-earned: (list 10 uint)
  }
)

;; Public Functions

;; Register new organization
(define-public (register-organization (name (string-ascii 50)))
  (let 
    (
      (new-org {
        name: name,
        eco-points: u0,
        total-energy: u0,
        total-waste: u0,
        total-achievements: u0
      })
    )
    (begin
      (map-set organizations tx-sender new-org)
      (map-set achievements tx-sender {
        milestones: (list ),
        dates: (list ),
        points-earned: (list )
      })
      (var-set total-organizations (+ (var-get total-organizations) u1))
      (ok true)
    )
  )
)

;; Record monthly metrics
(define-public (record-monthly-metrics (year uint) (month uint) (energy uint) (waste uint))
  (let
    (
      (org-data (unwrap! (map-get? organizations tx-sender) (err u101)))
      (metrics {
        energy-usage: energy,
        waste-produced: waste,
        goals-met: u0
      })
      (goals (map-get? sustainability-goals tx-sender))
    )
    (begin
      (map-set monthly-metrics {org: tx-sender, year: year, month: month} metrics)
      (map-set organizations tx-sender 
        (merge org-data {
          total-energy: (+ (get total-energy org-data) energy),
          total-waste: (+ (get total-waste org-data) waste)
        })
      )
      (match goals goals-data
        (if (and
              (<= energy (get energy-target goals-data))
              (<= waste (get waste-target goals-data))
            )
          (award-achievement tx-sender (concat "Monthly goals met for " (to-string month)) u50)
          true
        )
        true
      )
      (ok true)
    )
  )
)

;; Set sustainability goals
(define-public (set-sustainability-goals (energy-target uint) (waste-target uint) (points uint))
  (begin
    (asserts! (> energy-target u0) err-invalid-goal)
    (asserts! (> waste-target u0) err-invalid-goal)
    (asserts! (> points u0) err-invalid-goal)
    (ok (map-set sustainability-goals tx-sender {
      energy-target: energy-target,
      waste-target: waste-target,
      points-threshold: points,
      active: true
    }))
  )
)

;; Award achievement
(define-public (award-achievement (org principal) (milestone (string-ascii 100)) (points uint))
  (let
    (
      (org-data (unwrap! (map-get? organizations org) err-not-found))
      (achievement-data (unwrap! (map-get? achievements org) err-not-found))
    )
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

;; Award eco-points
(define-public (award-eco-points (org principal) (points uint))
  (if (is-eq tx-sender contract-owner)
    (let
      (
        (org-data (unwrap! (map-get? organizations org) (err u101)))
      )
      (begin
        (map-set organizations org 
          (merge org-data {
            eco-points: (+ (get eco-points org-data) points)
          })
        )
        (ok true)
      )
    )
    err-owner-only
  )
)

;; Read-only functions

(define-read-only (get-organization-data (org principal))
  (ok (unwrap! (map-get? organizations org) err-not-found))
)

(define-read-only (get-monthly-metrics (org principal) (year uint) (month uint))
  (ok (unwrap! (map-get? monthly-metrics {org: org, year: year, month: month}) err-not-found))
)

(define-read-only (get-total-organizations)
  (ok (var-get total-organizations))
)

(define-read-only (get-achievements (org principal))
  (ok (unwrap! (map-get? achievements org) err-not-found))
)

(define-read-only (get-sustainability-goals (org principal))
  (ok (unwrap! (map-get? sustainability-goals org) err-not-found))
)
