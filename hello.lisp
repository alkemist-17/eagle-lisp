; ===============================
;           Eagle Lisp
; ===============================



(print "Welcome to Eagle Lisp")



(def ___g (lambda ()
    (load "hello.lisp")))




(def nothing nil)




(defmacro defstruct (name . fields)
  `(def ,(string->symbol (++ "make-" (symbol->string name)))
     (lambda ,fields
       (let ((s (make-dict)))
         ,@(map (lambda (f) `(dict-set s ,(symbol->string f) ,f)) fields)
         s))))




(defmacro awhile (test . body)
  `(let ((loop nil))
     (set! loop (lambda ()
       (if ,test
           (begin ,@body (loop)))))
     (loop)))




(defmacro aif (test then otherwise)
  `(let ((it ,test))
     (if it ,then ,otherwise)))




(defmacro my-let (bindings . body)
  (let ((names (map car bindings))
        (values (map (lambda (b) (car (cdr b))) bindings)))
    `((lambda ,names ,@body) ,@values)))




(defmacro my-or (. exprs)
  (cond
    ((null? exprs) #f)
    ((null? (cdr exprs)) (car exprs))
    (else `(if ,(car exprs) #t (my-or ,@(cdr exprs))))))




(defmacro unless (test . bodies) `(if (not ,test) (begin ,@bodies) "test was truthy!"))




(defmacro arg-count (. args) `,(list-length args))




(defmacro my-or2 (a b)
  (let ((g (gensym)))
    `(let ((,g ,a))
       (if ,g ,g ,b))))




(def gensym-counter (list 0))




(def gensym
  (lambda ()
    (set! gensym-counter (list (+ (car gensym-counter) 1)))
    (string->symbol (++ "**g-S-y-M-b-O-l**$" (to-string (car gensym-counter))))))




(defmacro when (test . bodies) `(if ,test (begin ,@bodies) nil))




(defmacro my-eval-atom (x) x)




(def tiny-eval
  (lambda (expr)
    (cond
      ((atom expr) expr)
      ((eq (car expr) (quote quote)) (car (cdr expr)))
      ((eq (car expr) (quote if))
       (if (tiny-eval (car (cdr expr)))
           (tiny-eval (car (cdr (cdr expr))))
           (tiny-eval (car (cdr (cdr (cdr expr)))))))
      ((eq (car expr) (quote +))
       (+ (tiny-eval (car (cdr expr))) (tiny-eval (car (cdr (cdr expr))))))
      ((eq (car expr) (quote -))
       (- (tiny-eval (car (cdr expr))) (tiny-eval (car (cdr (cdr expr))))))
      ((eq (car expr) (quote *))
       (* (tiny-eval (car (cdr expr))) (tiny-eval (car (cdr (cdr expr))))))
      ((eq (car expr) (quote /))
       (/ (tiny-eval (car (cdr expr))) (tiny-eval (car (cdr (cdr expr))))))
      (else (error "tiny-eval: unrecognized form"))))) ;; still does not exist an error function




(print nothing)







