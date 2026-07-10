;; =============================================
;; 🦅 EAGLE-LISP STANDARD LIBRARY (stdlib.lisp)
;; =============================================

;; Some lispy stuff for fun

;; Reverses a string using pure Lisp recursion!
(def string-reverse
  (lambda (s)
    (let ((len (list-length s)))
      (if (<= len 1)
          s
          (string-append 
            (string-reverse (substring s 1 len)) 
            (substring s 0 1))))))

(def string-append
  (lambda (s1 s2)
    (string-join "" (list s1 s2))))

(def palindrome?
  (lambda (s)
    (eq s (string-reverse s))))


;; STACK
;; Pure functional
(def stack-new (lambda () (list)))
(def stack-push (lambda (s item) (cons item s)))
(def stack-pop (lambda (s) (car s)))
(def stack-rest (lambda (s) (cdr s)))


;; QUEUE
;; Pure functional
;; Queues are FIFO (First In, First Out). We append to the back, and pop from the front.
(def queue-new 
  (lambda () 
    (list)))

(def queue-enqueue
  (lambda (q item)
    (list-append q item)))

(def queue-dequeue
  (lambda (q)
    (car q))) ;; Returns the oldest item

(def queue-rest
  (lambda (q)
    (cdr q))) ;; Returns the queue without the oldest item


;; Some maths
(def abs
  (lambda (n)
    (if (< n 0) (- n) n)))

(def max
  (lambda (a b)
    (if (> a b) a b)))

(def min
  (lambda (a b)
    (if (< a b) a b)))


(puts "standard library loaded successfully")
