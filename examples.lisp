;; Some basic code examples here ...

;; (def factorial (lambda (n) (if (eq n 0) 1 (* n (factorial (- n 1)))))) (factorial 5) (factorial 10)

;; (def fib (lambda (n) (if (<= n 1) n (+ (fib (- n 1)) (fib (- n 2)))))) (fib 10) (fib 15)

;; (def classify (lambda (x) (cond ((< x 0) "Negative") ((eq x 0) "Zero") (else "Positive")))) (print (classify 5))

;; (let ((x 10) (y 20)) (print "x is" x "and y is" y) (+ x y))

;; (def make-counter (lambda () (let ((count 0)) (lambda () (set! count (+ count 1)) count))))

;; (def c1 (make-counter)) (def c2 (make-counter))

;; (print "C1:" (c1) (c1) (c1)) (print "C2:" (c2) (c2))

;; (def my-list (list 1 2 3 4 5))

;; (print "First element:" (car my-list)) (print "The rest:" (cdr my-list)) (print "Prepend a zero:" (cons 0 my-list))

;; (def double (lambda (x) (* x 2))) (print "Doubled:" (map double my-list))

;; (def is-even? (lambda (x) (eq (% x 2) 0))) (print "Evens only:" (filter is-even? my-list))

;; (def add-three (lambda (a b c) (+ a (+ b c)))) (print "Applied:" (apply add-three (list 10 20 30)))

;; (print "Empty sum:" (+)) (print "Empty product:" (*))

;; Unary Inverses (print "Negative 5:" (- 5)) (print "Reciprocal of 4:" (/ 4))

;; Chaining Comparisons (print "Is 1 < 2 < 3?" (< 1 2 3)) (print "Is 5 = 5 = 5?" (eq 5 5 5))

;; Variadic Math (print "Sum:" (+ 1 2 3 4 5)) (print "Left-associative sub:" (- 100 10 5 2))

;; (def pythagoras (lambda (a b) (def a2 (* a a)) (def b2 (* b b)) (+ a2 b2)))

;; (print "Result; is:" (pythagoras 3 4))

;; (defmacro when (test . bodies) `(if ,test (begin ,@bodies)))

;; (when (> 5 3) (print "Five is greater than three") (print "Math works!") 42)

;; (def my-list (lambda (first . rest) (cons first rest)))

;; (print "Rest params:" (my-list 1 2 3))

;; (defmacro when (test . bodies) `(if ,test (begin ,@bodies)))

;; (when (> 5 3) (print "When macro works!") (print "Multiple body expressions too!") 42)

;; (defmacro my-list (. items) `(list ,@items))

;; (print (my-list 1 2 3))

;; (def log-with-prefix (lambda (prefix . messages) (map (lambda (msg) (print prefix ":" msg)) messages)))

;; (log-with-prefix "[INFO]" "Server started" "Listening on port 8080" "Ready!")

;; (def sum-to-acc (lambda (n acc) (if (eq n 0) acc (sum-to-acc (- n 1) (+ n acc)))))

;; (def mutate-outer (lambda () (let ((inner-var 20)) (set! outer-var 999) (set! inner-var 888) (list outer-var inner-var))))

;; (def make-adders (lambda () (list (let ((n 1)) (lambda () n)) (let ((n 2)) (lambda () n)) (let ((n 3)) (lambda () n)))))

;; (def mutate-outer (lambda () (let ((inner-var 20)) (set! outer-var 999) (set! inner-var 888) (list outer-var inner-var))))

;; (def gensym-counter (list 0))

;; (def gensym (lambda () (set! gensym-counter (list (+ (car gensym-counter) 1))) (make-symbol (++ "**S-y-M-b-O-l**" (to-string (car gensym-counter))))))

;; (defmacro my-or (a b) (let ((g (gensym))) `(let ((,g ,a)) (if ,g ,g ,b))))

;; (defmacro my-or2 (a b) `(let ((temp ,a)) (if temp temp ,b)))

;; (defmacro capture-check (val) `(let ((alpha ,val)) (print alpha)))

;; (defmacro my-and (. exprs) (cond ((nil? exprs) #t) ((nil? (cdr exprs)) (car exprs)) (else `(if ,(car exprs) (my-and ,@(cdr exprs)) #f))))

;; (defmacro my-or (. exprs) (cond ((nil? exprs) #f) ((nil? (cdr exprs)) (car exprs)) (else `(if ,(car exprs) #t (my-or ,@(cdr exprs))))))

;; (defmacro my-let (bindings . body) (let ((names (map car bindings)) (values (map (lambda (b) (car (cdr b))) bindings))) `((lambda ,names ,@body) ,@values)))

;; (defmacro aif (test then otherwise) `(let ((it ,test)) (if it ,then ,otherwise)))

;; (defmacro awhile (test . body) `(let ((loop nil)) (set! loop (lambda () (if ,test (begin ,@body (loop))))) (loop)))

;; (defmacro defstruct (name . fields) `(def ,(string->symbol (++ "make-" (symbol->string name))) (lambda ,fields (let ((s (make-dict))) ,@(map (lambda (f) `(dict-set s ,(symbol->string f) ,f)) fields) s))))

;; (def remove-if (lambda (f xs) (if (null? xs) nil (if (f (car xs)) (remove-if f (cdr xs)) (cons (car xs) (remove-if f (cdr xs)))))))

;; (def is-even (lambda (x) (eq (% x 2) 0)))

;; (remove-if is-even (list 1 2 3 4 5 6 7 8 9))
