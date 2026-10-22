#lang racket/base

(require racket/list
         rackunit
         foreman)

(test-case
  "a counting rule drives to quiescence"
  (define e
    (make-engine
     #:rules
     (list
      (rule
       'count-up
       (list '(counter value (? v)))
       (lambda (m)
         (let ((v (hash-ref (match-record-vars m) 'v))
               (elt (car (match-record-elements m))))
           (if (< v 5)
             (list (modify-action elt (list 'value (+ v 1))))
             (list (remove-action elt)))))))))
  (engine-assert! e 'counter 'value 0)
  (define cycles (engine-run! e))
  (check-equal? cycles 6)
  (check-equal? (engine-elements e) '()))

(test-case
  "a no-op right-hand side hits the cycle cap"
  (define e
    (make-engine
     #:rules
     (list (rule 'stare (list '(wall color (? c))) (lambda (m) '())))))
  (engine-assert! e 'wall 'color 'white)
  (check-equal? (engine-run! e #:max-cycles 10) 10))

(test-case
  "recency wins when specificity ties"
  (define e
    (make-engine
     #:rules
     (list
      (rule
       'plain
       (list '(task status (? s)))
       (lambda (m)
         (list
          (fact 'fired 'rule 'plain)
          (remove-action (car (match-record-elements m))))))
      (rule
       'urgent
       (list '(task status urgent))
       (lambda (m)
         (list
          (fact 'fired 'rule 'urgent)
          (remove-action (car (match-record-elements m)))))))))
  (engine-assert! e 'task 'status 'open)
  (engine-assert! e 'task 'status 'urgent)
  (engine-run! e)
  (define fired
    (for/list
     ((elt (in-list (engine-elements e)))
      #:when
      (equal? (element-class elt) 'fired))
     (element-ref elt 'rule)))
  (check-equal? (first fired) 'urgent))

(test-case
  "specificity wins when recency ties"
  (define e
    (make-engine
     #:rules
     (list
      (rule
       'loose
       (list '(item kind (? k) state new))
       (lambda (m)
         (list
          (fact 'result 'winner 'loose)
          (remove-action (car (match-record-elements m))))))
      (rule
       'tight
       (list '(item kind widget state new))
       (lambda (m)
         (list
          (fact 'result 'winner 'tight)
          (remove-action (car (match-record-elements m)))))))))
  (engine-assert! e 'item 'kind 'widget 'state 'new)
  (engine-run! e)
  (define winners
    (for/list
     ((elt (in-list (engine-elements e)))
      #:when
      (equal? (element-class elt) 'result))
     (element-ref elt 'winner)))
  (check-equal? winners '(tight)))

(test-case
  "declaration order breaks full ties"
  (define e
    (make-engine
     #:rules
     (list
      (rule
       'second-claim
       (list '(coin side heads))
       (lambda (m)
         (list
          (fact 'result 'winner 'second-claim)
          (remove-action (car (match-record-elements m))))))
      (rule
       'first-claim
       (list '(coin side heads))
       (lambda (m)
         (list
          (fact 'result 'winner 'first-claim)
          (remove-action (car (match-record-elements m)))))))))
  (engine-assert! e 'coin 'side 'heads)
  (engine-run! e)
  (define winners
    (for/list
     ((elt (in-list (engine-elements e)))
      #:when
      (equal? (element-class elt) 'result))
     (element-ref elt 'winner)))
  (check-equal? winners '(second-claim)))

(test-case
  "patterns join across elements"
  (define e
    (make-engine
     #:rules
     (list
      (rule
       'match-make
       (list '(part left (? sym)) '(part right (? sym)))
       (lambda (m)
         (let ((elts (match-record-elements m)))
           (list
            (fact 'coupled 'symbol (hash-ref (match-record-vars m) 'sym))
            (remove-action (car elts))
            (remove-action (cadr elts)))))))))
  (engine-assert! e 'part 'left 'gear)
  (engine-assert! e 'part 'right 'gear)
  (engine-assert! e 'part 'right 'bolt)
  (engine-run! e)
  (check-equal? (engine-count-of-class e 'coupled) 1)
  (check-equal? (for/list ([elt (in-list (engine-elements e))]
                             #:when (equal? (element-class elt) 'coupled))
                        (element-ref elt 'symbol))
               '(gear)))

