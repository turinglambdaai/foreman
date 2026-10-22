#lang racket/base

;; Working memory. An element is a flat datum whose first position is a
;; class symbol followed by attribute/value alternation —
;; (monkey location tree1 holds nil) — stamped with a unique id and the
;; logical time it was produced. Time stamps drive recency, the first
;; conflict-resolution criterion.

(require racket/list)

(provide (struct-out element)
         make-element
         element-class
         element-ref
         next-time!)

(define current-time 0)

;; One logical clock for the process: recency comparisons are meaningless
;; across engines with shared clock state, so the clock is global and
;; monotonic — the simplest stamp that cannot lie.
(define (next-time!)
  (set! current-time (add1 current-time))
  current-time)

(define next-id
  (let ([id 0])
    (lambda ()
      (set! id (add1 id))
      id)))

(struct element (id time datum) #:transparent)

;; datum is (list class attr val attr val ...), an even-length tail.
(define (make-element . datum)
  (unless (and (pair? datum)
               (symbol? (car datum))
               (even? (length (cdr datum))))
    (raise-argument-error
     'make-element
     "a class symbol followed by attribute/value pairs"
     datum))
  (element (next-id) (next-time!) datum))

(define (element-class e)
  (car (element-datum e)))

;; Value stored under ATTR, or #f. Attribute order does not matter for
;; lookups; it matters for pattern position matching, which pattern.rkt
;; deliberately shares with this layout.
(define (element-ref e attr)
  (let loop ([slots (cdr (element-datum e))])
    (cond
      [(null? slots) #f]
      [(eq? (car slots) attr) (cadr slots)]
      [else (loop (cddr slots))])))
