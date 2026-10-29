#lang info

(define collection 'multi)
(define deps
  '(["base" #:version "9.0"]
    "rackunit-lib"))
(define build-deps '("racket-doc" "scribble-lib"))
(define pkg-desc "A production rule system: declarative patterns, procedural right-hand sides")
(define version "0.1")
(define pkg-authors '(turlamai))
(define license 'Apache-2.0)
