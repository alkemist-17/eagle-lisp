;; =============================================
;; EAGLE-LISP EXAMPLE LIBRARY (some-lib.lisp)
;; =============================================

;; Some lispy stuff for fun

;; STACK
;; Pure functional
(def stack-new (lambda () (list)))
(def stack-push (lambda (s item) (cons item s)))
(def stack-pop (lambda (s) (car s)))
(def stack-rest (lambda (s) (cdr s)))

(print "`some-lib` loaded successfully")
