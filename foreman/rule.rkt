#lang racket/base

;; Rules. The left-hand side is a list of patterns; the right-hand side is
;; an ordinary Racket procedure from a match to a list of actions. The
;; declarative part stays declarative; everything the patterns cannot say,
;; the procedure says with the full language.

(require "memory.rkt")

(provide (struct-out rule)
         (struct-out match-record)
         (struct-out make-action)
         fact
         (struct-out remove-action)
         (struct-out modify-action)
         action?)

(struct rule (name patterns action) #:transparent)
;; action : (-> match-record? (listof action?))

;; What one satisfied rule instantiation hands to its RHS: the variable
;; bindings across all patterns and the matched elements themselves (so an
;; RHS can remove or modify exactly what it saw).
(struct match-record (vars elements) #:transparent)

;; datum: flat (class attr val attr val ...) — the same shape working
;; memory stores.
(struct make-action (datum) #:transparent)

(define (fact class . slots)
  (make-action (cons class slots)))

(struct remove-action (element) #:transparent)
(struct modify-action (element new-slots) #:transparent)
;; modify replaces an element's slots wholesale: production systems reason
;; on the fact level, and partial updates hide which fact version a match
;; used.

(define (action? v)
  (or (make-action? v) (remove-action? v) (modify-action? v)))
