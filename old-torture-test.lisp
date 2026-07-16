;; ======================================================================
;;  EAGLE LISP TORTURE TEST
;;  Load with: (load "eagle-torture-test.lisp")
;;  Or paste section by section into the REPL.
;;
;;  Each block has an "expect:" comment. Anything that prints
;;  something OTHER than what's expected is a bug report waiting
;;  to happen. Nothing here is meant to be "fair" to the interpreter.
;; ======================================================================


;; ------------------------------------------------------------
;; 1. LET
;; ------------------------------------------------------------

(def x 100)

;; Known-bad shorthand (flat binding, no inner parens).
;; expect: some clean error, NOT a silent fallback to the outer x
(let (x 20) x)

;; Correct nested-pair form.
;; expect: 20
(let ((x 20)) x)

;; Multiple bindings.
;; expect: 30
(let ((a 10) (b 20)) (+ a b))

;; Shadowing across nested lets.
;; expect: 3
(let ((x 1))
  (let ((x 2))
    (let ((x 3))
      x)))

;; Does a later binding in the SAME let see an earlier one?
;; (In real Scheme `let`, it should NOT — that's `let*` behavior.)
;; expect: error OR 100 (sees global x), NOT 5 (sees sibling binding)
(let ((x 5) (b x)) b)

;; Empty bindings list.
;; expect: 42, no crash
(let () 42)

;; let with no body expressions at all.
;; expect: nil or graceful nil, not a crash
(let ((a 1)))

;; Binding to an expression that itself uses outer scope.
;; expect: 105 (a = 100 + 5, using global x)
(let ((a (+ x 5))) a)


;; ------------------------------------------------------------
;; 2. LAMBDA / FUNCTION ENV
;; ------------------------------------------------------------

;; Multi-arg lambda, all params distinct.
;; expect: (10 20)
(def f2 (lambda (a b) (list a b)))
(f2 10 20)

;; Three args.
;; expect: (1 2 3)
(def f3 (lambda (a b c) (list a b c)))
(f3 1 2 3)

;; Five args, to really stress positional binding.
;; expect: (1 2 3 4 5)
(def f5 (lambda (a b c d e) (list a b c d e)))
(f5 1 2 3 4 5)

;; Args used in arithmetic, not just re-listed (catches silent
;; aliasing where every param secretly equals args[1]).
;; expect: 140  (10*1 + 20*2 + 30*3 = 10+40+90 = 140 -- adjust math below)
(def weighted (lambda (a b c) (+ (* a 1) (+ (* b 2) (* c 3)))))
(weighted 10 20 30)

;; Variadic (dotted) params mixed with fixed ones.
;; expect: (1 (2 3 4))
(def firstrest (lambda (a . rest) (list a rest)))
(firstrest 1 2 3 4)

;; Fully variadic (no fixed params).
;; expect: (1 2 3 4 5)
(def allargs (lambda args args))
(allargs 1 2 3 4 5)

;; Zero-arg lambda.
;; expect: "no-args"
(def zeroarg (lambda () "no-args"))
(zeroarg)

;; Too few args -- should error, not silently misbind.
;; expect: error about not enough arguments
(f2 10)

;; Too many args -- should error.
;; expect: error about too many arguments
(f2 10 20 30)


;; ------------------------------------------------------------
;; 3. CLOSURES — do they actually close over mutable state?
;; ------------------------------------------------------------

(def make-counter
  (lambda ()
    (let ((count 0))
      (lambda ()
        (set! count (+ count 1))
        count))))

(def c1 (make-counter))
(def c2 (make-counter))

;; expect: 1 2 3
(c1) (c1) (c1)

;; expect: 1  (c2 must NOT share state with c1)
(c2)

;; Closure capturing a loop-ish variable via let, checking each
;; closure gets its OWN binding, not one shared cell.
;; expect: (1 2 3), NOT (3 3 3)
(def make-adders
  (lambda ()
    (list
      (let ((n 1)) (lambda () n))
      (let ((n 2)) (lambda () n))
      (let ((n 3)) (lambda () n)))))
(map (lambda (fn) (fn)) (make-adders))


;; ------------------------------------------------------------
;; 4. RECURSION — depth, mutual recursion, accumulator style
;; ------------------------------------------------------------

(def factorial (lambda (n) (if (eq n 0) 1 (* n (factorial (- n 1))))))
;; expect: 3628800
(factorial 10)

(def fib (lambda (n) (if (<= n 1) n (+ (fib (- n 1)) (fib (- n 2))))))
;; expect: 55
(fib 10)

;; Mutual recursion -- tests that env lookup for a not-yet-fully-bound
;; sibling def works once both defs exist.
(def is-even (lambda (n) (if (eq n 0) #t (is-odd (- n 1)))))
(def is-odd  (lambda (n) (if (eq n 0) #f (is-even (- n 1)))))
;; expect: #t
(is-even 20)
;; expect: #f
(is-odd 20)

;; Deep non-tail recursion -- stack depth stress test.
;; expect: either a correct large number, or a clean stack-overflow
;; error -- NOT a silent wrong answer or interpreter hang.
(def sum-to (lambda (n) (if (eq n 0) 0 (+ n (sum-to (- n 1))))))
(sum-to 10)

;; Accumulator-passing version of the same thing (tail-call shaped,
;; even if the interpreter doesn't actually optimize it -- worth
;; comparing depth tolerance against sum-to above).
(def sum-to-acc (lambda (n acc) (if (eq n 0) acc (sum-to-acc (- n 1) (+ n acc)))))
;; expect: same result as (sum-to 10)
(sum-to-acc 10 0)


;; ------------------------------------------------------------
;; 5. MACROS — hygiene, nesting, quasiquote/unquote/splicing
;; ------------------------------------------------------------

(defmacro when (test . bodies) `(if ,test (begin ,@bodies) nil))

;; expect: 42
(when (> 5 3) (print "five > three") 42)

;; expect: nil, and "nope" should NOT print
(when (> 3 5) (print "nope") 42)

;; Macro hygiene stress: does the macro's internal naming collide
;; with a user variable also called `test`?
(def test 999)
;; expect: "still 999" printed, and result 999 -- not a hygiene collision
(when (> 1 0) (print "still" test) test)

;; Nested macro expansion.
(defmacro unless (test . bodies) `(if (not ,test) (begin ,@bodies) nil))
;; expect: "printed"
(unless #f (print "printed"))
;; expect: nil, nothing printed
(unless #t (print "should not print"))

;; Recursive-ish macro use: macro calling into code that itself
;; uses another macro.
;; expect: "both" 1
(when #t (unless #f (print "both")) 1)

;; quasiquote with splicing of a computed list.
(def nums (list 1 2 3))
;; expect: (0 1 2 3 4)
`(0 ,@nums 4)

;; nested quasiquote/unquote (classic Lisp gotcha -- deep nesting
;; can break naive implementations).
;; expect: (a (quasiquote (b (unquote (+ 1 2))))) at depth 2 the inner unquote should
;; NOT be evaluated, since it belongs to the outer quasiquote level
`(a `(b ,(+ 1 2)))

;; splicing something that ISN'T a list should error cleanly.
;; expect: a clear "must be a list" style error, not a crash
`(1 ,@5 2)

;; unquote-splicing outside any list context.
;; expect: clean error
,@nums


;; ------------------------------------------------------------
;; 6. LISTS / HIGHER-ORDER FUNCTIONS
;; ------------------------------------------------------------

(def lst (list 1 2 3 4 5))

;; expect: 1
(car lst)
;; expect: (2 3 4 5)
(cdr lst)
;; expect: #t
(nil? (list))
;; expect: #f
(nil? lst)
;; expect: nil (car of empty list, per this interpreter's semantics)
(car (list))
;; expect: nil (cdr of empty list)
(cdr (list))

;; map/filter/apply combo.
(def double (lambda (n) (* n 2)))
(def is-even2 (lambda (n) (eq (% n 2) 0)))
;; expect: (2 4 6 8 10)
(map double lst)
;; expect: (2 4)
(filter is-even2 lst)
;; expect: 15
(apply + lst)

;; apply with a lambda taking fixed args, not just variadic prelude fns.
(def add3 (lambda (a b c) (+ a (+ b c))))
;; expect: 60
(apply add3 (list 10 20 30))

;; deeply nested list construction/access.
(def nested (list (list 1 2) (list 3 4) (list 5 (list 6 7))))
;; expect: 7
(car (cdr (car (cdr (car (cdr (cdr nested)))))))

;; cons onto an empty list, and onto nil directly.
;; expect: (1)
(cons 1 (list))
;; expect: (1) or a clean error -- cons'ing onto NIL is ambiguous,
;; worth knowing which way this interpreter falls
(cons 1 nil)

;; dotted-pair literal parsing (not proper lists).
;; expect: either a genuine dotted-pair value, or a clear error --
;; this interpreter's `car`/`cdr` assume proper arrays, so a raw
;; (1 . 2) is a good place to look for weirdness
(quote (1 . 2))


;; ------------------------------------------------------------
;; 7. COND / IF / AND / OR — branching + short circuit
;; ------------------------------------------------------------

(def classify (lambda (n) (cond ((< n 0) "negative") ((eq n 0) "zero") (else "positive"))))
;; expect: "negative" "zero" "positive"
(classify -5) (classify 0) (classify 5)

;; cond with no matching clause and no else.
;; expect: nil
(cond (#f "a") (#f "b"))

;; and/or short-circuiting -- side effects should NOT fire past
;; the short-circuit point.
(def side-effect-log (list))
(def log! (lambda (tag val) (print "SIDE EFFECT:" tag) val))
;; expect: only "checking-1" printed, result #f -- log-2 must NOT fire
(and (log! "checking-1" #f) (log! "checking-2" #t))
;; expect: only "checking-3" printed, result #t -- log-4 must NOT fire
(or (log! "checking-3" #t) (log! "checking-4" #f))

;; falsiness of nil vs #f -- both should be falsy in `if`.
;; expect: "nil-is-truthy"
(if nil "nil-is-falsy" "nil-is-not-truthy")
;; expect: "zero-is-truthy" (0 should NOT be falsy in most lisps --
;; worth confirming this interpreter agrees)
(if 0 "zero-is-truthy" "zero-is-falsy")
;; expect: "empty-string-is-truthy"
(if "" "empty-string-is-truthy" "empty-string-is-falsy")


;; ------------------------------------------------------------
;; 8. ARITHMETIC / COMPARISON EDGE CASES
;; ------------------------------------------------------------

;; expect: 0 (empty sum)
(+)
;; expect: 1 (empty product)
(*)
;; expect: -5 (unary negation)
(- 5)
;; expect: 0.25 (unary reciprocal)
(/ 4)
;; expect: #t (chained comparison)
(< 1 2 3 4 5)
;; expect: #f (chain breaks at 3 -> 2)
(< 1 2 3 2 5)
;; expect: #t (all equal)
(eq 5 5 5)
;; expect: division by zero -- expect a clean error, not a crash/hang
(/ 1 0)
;; expect: integer/float mixing -- does this coerce sanely?
(+ 1 2.5)
;; expect: negative modulo behavior -- worth knowing the sign convention
(% -7 3)
;; expect: comparing across types (int vs string) -- expect a clean
;; error, not a silent false or a crash
(< 1 "a")


;; ------------------------------------------------------------
;; 9. STRINGS
;; ------------------------------------------------------------

;; expect: "hello world"
(++ "hello" " " "world")
;; expect: "hello 42" (non-string args auto-stringified)
(++ "hello " 42)
;; expect: 5
(length "hello")
;; string containing lisp-significant characters -- parser stress.
;; expect: "(parens) \"nested-quotes\" ; semicolon"
"(parens) \"nested-quotes\" ; semicolon"
;; a semicolon INSIDE a string must not be treated as a comment start.
;; expect: "before;after" printed in full, nothing truncated
(print "before;after")
;; empty string edge cases.
;; expect: 0
(length "")


;; ------------------------------------------------------------
;; 10. DICT / OBJECT OPS
;; ------------------------------------------------------------

(def d (make-dict))
(def d (dict-set d "a" 1))
(def d (dict-set d "b" 2))
;; expect: 1
(dict-get d "a")
;; expect: list containing "a" and "b" (order not guaranteed)
(dict-keys d)
;; expect: {} (cleared)
(dict-clear d)
;; getting a missing key -- expect nil or clean error, not a crash
(dict-get d "does-not-exist")
;; wrong-type args -- expect clean error
(dict-set "not-a-dict" "a" 1)


;; ------------------------------------------------------------
;; 11. set! SCOPE RULES
;; ------------------------------------------------------------

(def g 1)
(def bump! (lambda () (set! g (+ g 1))))
(bump!) (bump!) (bump!)
;; expect: 4
g

;; set! on a symbol that was never def'd anywhere.
;; expect: clean "not defined" error, not a silent no-op
(set! totally-undefined-symbol 5)

;; set! reaching through nested lambda/let scopes to the right frame.
(def outer-var 10)
(def mutate-outer
  (lambda ()
    (let ((inner-var 20))
      (set! outer-var 999)
      (set! inner-var 888)
      (list outer-var inner-var))))
;; expect: (999 888)
(mutate-outer)
;; expect: 999 (mutation of outer-var persisted globally)
outer-var


;; ------------------------------------------------------------
;; 12. ERROR HANDLING / MALFORMED INPUT
;; ------------------------------------------------------------

;; Unbound symbol.
;; expect: clean "symbol not found" error
totally-fake-symbol-xyz

;; Calling a non-function.
;; expect: clean "not a lambda expression" error
(def not-a-fn 42)
(not-a-fn 1 2 3)

;; Mismatched parens -- parser-level stress.
;; expect: clean parse error, not a hang or crash
(+ 1 2

;; Extra close paren.
;; expect: clean "unexpected )" error
(+ 1 2))

;; Calling car/cdr on a non-list, non-nil value.
;; expect: clean error
(car 42)

;; Nested unbalanced quasiquote.
;; expect: clean error, ideally pointing at the unquote
(+ 1 ,2)