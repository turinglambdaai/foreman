#lang racket/base

(require rackunit
         foreman)

(test-case "elements carry class, slots, id, and time"
  (define a (make-element 'monkey 'location 'tree1 'holds 'nil))
  (check-equal? (element-class a) 'monkey)
  (check-equal? (element-ref a 'location) 'tree1)
  (check-equal? (element-ref a 'holds) 'nil)
  (check-equal? (element-ref a 'bananas) #f))

(test-case "attribute order does not matter for lookups"
  (define a (make-element 'box 'at 'shelf3 'weight 12))
  (check-equal? (element-ref a 'weight) 12)
  (check-equal? (element-ref a 'at) 'shelf3))

(test-case "malformed datums are rejected"
  (check-exn exn:fail:contract? (lambda () (make-element)))
  (check-exn exn:fail:contract? (lambda () (make-element 42 'x 1)))
  (check-exn exn:fail:contract? (lambda () (make-element 'box 'x))))

(test-case "ids and times are unique and monotonic"
  (define a (make-element 'box 'at 'shelf1))
  (define b (make-element 'box 'at 'shelf2))
  (check-true (< (element-id a) (element-id b)))
  (check-true (< (element-time a) (element-time b))))
