;; EcoPulse - Sustainability Tracking Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var total-organizations uint u0)

;; Data Maps
(define-map organizations principal
  {
    name: (string-ascii 50),
    eco-points: uint,
    total-energy: uint,
    total-waste: uint
  }
)

(define-map monthly-metrics (tuple (org principal) (year uint) (month uint))
  {
    energy-usage: uint,
    waste-produced: uint,
    goals-met: uint
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
        total-waste: u0
      })
    )
    (begin
      (map-set organizations tx-sender new-org)
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
    )
    (begin
      (map-set monthly-metrics {org: tx-sender, year: year, month: month} metrics)
      (map-set organizations tx-sender 
        (merge org-data {
          total-energy: (+ (get total-energy org-data) energy),
          total-waste: (+ (get total-waste org-data) waste)
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