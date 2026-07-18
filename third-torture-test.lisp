;; ============================================================================
;; Eagle Lisp Torture Test Suite
;; Written against interpreter version 0.9.4, post Step-1 (symName/keyword-
;; as-identifier) fix, pre Step-2 (Pair/array unification).
;;
;; RUN IT:
;;   From the REPL prompt:  (load "torture-test.lisp")
;;   (adjust the path to wherever you saved this file)
;;
;; Each check prints PASS or FAIL as it runs; a final tally prints at the end.
;;
;; A NOTE ON WHAT CAN'T BE AUTO-CHECKED:
;; Eagle Lisp has no `error?` / type-of predicate exposed to Lisp code, so
;; a result that's *expected* to be a Vida error object can't be asserted
;; generically from inside Lisp. Two workarounds are used below:
;;   1. Identity trick (Sections 7-8): capture the error value in a variable,
;;      then check that if/cond/and/or/macro-call return that *exact same
;;      object* unchanged when they short-circuit on it (equal? on the same
;;      reference is reliably true even without a dedicated predicate).
;;   2. A couple of spots are marked MANUAL-VERIFY: they print the raw
;;      result (errors render via their custom toString as "error: ...")
;;      next to a comment describing what should appear, for you to eyeball.
;; ============================================================================

(def test-total (list 0))
(def test-pass (list 0))

(def check
  (lambda (name actual expected)
    (begin
      (set! test-total (list (+ (car test-total) 1)))
      (if (equal? actual expected)
          (begin
            (set! test-pass (list (+ (car test-pass) 1)))
            (print "  PASS" name))
          (print "  FAIL" name "-- expected" expected "got" actual)))))

(def section (lambda (title) (print (++ "\n=== " title " ==="))))


;; ----------------------------------------------------------------------
(section "1. Arithmetic & comparison")
;; ----------------------------------------------------------------------
(check "add" (+ 1 2 3) 6)
(check "add-empty" (+) 0)
(check "mul-empty" (*) 1)
(check "sub-unary-negation" (- 5) -5)
(check "sub-variadic" (- 100 10 5 2) 83)
(check "div-unary-reciprocal" (/ 4) 0.25)
(check "mod" (% 7 3) 1)
(check "lt-chain-true" (< 1 2 3) #t)
(check "lt-chain-false" (< 1 3 2) #f)
(check "le-chain" (<= 1 1 2) #t)
(check "gt-chain" (> 3 2 1) #t)
(check "ge-chain" (>= 3 3 1) #t)
(check "eq-numeric-chain" (eq 5 5 5) #t)


;; ----------------------------------------------------------------------
(section "2. Pair/list primitives")
;; ----------------------------------------------------------------------
(def L (list 1 2 3 4 5))
(check "car" (car L) 1)
(check "cdr" (cdr L) (list 2 3 4 5))
(check "cons" (cons 0 L) (list 0 1 2 3 4 5))
(check "length-list" (length L) 5)
(check "length-string" (length "hello") 5)
(check "nil-true" (nil? (cdr (list 1))) #t)
(check "nil-false" (nil? L) #f)
(check "nil-token" (nil? (quote nil)) #t)
(check "list-append" (list-append L 6) (list 1 2 3 4 5 6))
(check "map" (map (lambda (x) (* x 2)) L) (list 2 4 6 8 10))
(check "filter" (filter (lambda (x) (eq (% x 2) 0)) L) (list 2 4))
(check "apply" (apply + L) 15)


;; ----------------------------------------------------------------------
(section "3. quote / quasiquote / unquote / unquote-splicing")
;; ----------------------------------------------------------------------
(check "quote-list" (quote (1 2 3)) (list 1 2 3))
(check "quote-symbol" (quote foo) (string->symbol "foo"))
(def x 10)
(check "quasiquote-basic" `(a b ,x) (list (string->symbol "a") (string->symbol "b") 10))
(check "quasiquote-splice" `(1 ,@(list 2 3) 4) (list 1 2 3 4))
;; Nested-depth tracking: the INNER unquote is one quasiquote-level deeper
;; than the outer one, so (+ 1 2) must stay unevaluated code, not become 3.
;; NOTE: "quasiquote"/"unquote" markers here come from readFrom's `/,/,@
;; sugar, which injects them as bare Vida strings (never through Symbol()),
;; so the expected value below uses string literals "quasiquote"/"unquote"
;; for the markers, but (quote +) for the head of (+ 1 2) since that token
;; WAS parsed as a genuine identifier. This asymmetry is real and worth
;; re-checking once Step 2 rewrites expandQuasiquote to walk Pairs.
(check "quasiquote-nested-depth-not-evaluated"
       `(1 `(2 ,(+ 1 2)))
       (list 1 (list "quasiquote" (list 2 (list "unquote" (list (quote +) 1 2))))))


;; ----------------------------------------------------------------------
(section "4. let / set! / closures")
;; ----------------------------------------------------------------------
(check "let-basic" (let ((a 1) (b 2)) (+ a b)) 3)
(def make-counter (lambda () (let ((count 0)) (lambda () (set! count (+ count 1)) count))))
(def c1 (make-counter))
(check "closure-call-1" (c1) 1)
(check "closure-call-2" (c1) 2)
(def c2 (make-counter))
(check "closure-independent-state" (c2) 1)


;; ----------------------------------------------------------------------
(section "5. lambda: rest, dotted, and symbol-only parameters")
;; ----------------------------------------------------------------------
(def my-rest (lambda (first . rest) (cons first rest)))
(check "dotted-rest-params" (my-rest 1 2 3) (list 1 2 3))
(def variadic-sum (lambda args (apply + args)))
(check "symbol-only-params" (variadic-sum 1 2 3 4) 10)


;; ----------------------------------------------------------------------
(section "6. cond / and / or (values & short-circuit)")
;; ----------------------------------------------------------------------
(def classify (lambda (x) (cond ((< x 0) "Negative") ((eq x 0) "Zero") (else "Positive"))))
(check "cond-negative" (classify -5) "Negative")
(check "cond-zero" (classify 0) "Zero")
(check "cond-else-clause" (classify 5) "Positive")
(check "and-short-circuit" (and #t #t #f (error "should not reach")) #f)
(check "and-returns-last-truthy" (and 1 2 3) 3)
(check "or-short-circuit" (or #f #f 5 (error "should not reach")) 5)
(check "or-all-false" (or #f #f) #f)


;; ----------------------------------------------------------------------
(section "7. if/cond/and/or error propagation (regression: Bug #2)")
;; ----------------------------------------------------------------------
;; Before the fix, an error value was truthy under Vida's native rules, so
;; `if`/`cond` would misread it as "true", `and` would drop it silently,
;; and `or` only worked by accident. All four now check .isError() first
;; and return the error unchanged (same object) instead of proceeding.
(def bad-car (car 5))  ;; car on a non-pair/non-nil -> a real error value
(check "if-returns-error-unchanged" (if bad-car "then-branch" "else-branch") bad-car)
(check "cond-returns-error-unchanged" (cond (bad-car "hit") (else "fallback")) bad-car)
(check "and-returns-error-unchanged" (and #t bad-car (error "should not reach")) bad-car)
(check "or-returns-error-unchanged" (or #f bad-car (error "should not reach")) bad-car)


;; ----------------------------------------------------------------------
(section "8. defmacro arity errors (regression: Bug #1)")
;; ----------------------------------------------------------------------
;; Before the fix, calling a macro with the wrong arity crashed the Vida VM
;; ("not callable") instead of returning a clean Eagle Lisp error, because
;; defmacro's macroFn never checked makeFunctionEnv's error result.
(defmacro needs-one-arg (x) `(+ ,x 1))
;; MANUAL-VERIFY: must NOT crash the VM/session. Should print a clean
;; error like "error: not enough arguments for parameter `x`".
(print "macro-arity-error result ->" (needs-one-arg))
;; If we reach this line at all, the call above didn't crash the session.
(check "survived-macro-arity-error" 1 1)


;; ----------------------------------------------------------------------
(section "9. macro args -> astToData conversion (regression: Bug #3)")
;; ----------------------------------------------------------------------
;; Before the fix, macro call arguments bypassed astToData entirely, so a
;; macro taking a *positional* (non-rest) parameter bound to compound data
;; (e.g. a let-style binding list) would fail as soon as it called
;; map/car/cdr on that parameter.
(defmacro my-let (bindings . body)
  (let ((names (map car bindings))
        (values (map (lambda (b) (car (cdr b))) bindings)))
    `((lambda ,names ,@body) ,@values)))
(check "my-let-basic" (my-let ((a 1) (b 2)) (+ a b)) 3)
(check "my-let-shadowing" (my-let ((x 100)) (* x 2)) 200)


;; ----------------------------------------------------------------------
(section "10. recursive self-expanding macros")
;; ----------------------------------------------------------------------
(defmacro my-and (. exprs)
  (cond ((nil? exprs) #t)
        ((nil? (cdr exprs)) (car exprs))
        (else `(if ,(car exprs) (my-and ,@(cdr exprs)) #f))))
(check "my-and-all-true" (my-and 1 2 3) 3)
(check "my-and-short-circuit" (my-and 1 #f 3) #f)
(check "my-and-empty" (my-and) #t)

(defmacro my-or (. exprs)
  (cond ((nil? exprs) #f)
        ((nil? (cdr exprs)) (car exprs))
        (else `(if ,(car exprs) #t (my-or ,@(cdr exprs))))))
(check "my-or-first-true" (my-or #f #f 5) #t)
(check "my-or-all-false" (my-or #f #f) #f)
(check "my-or-empty" (my-or) #f)


;; ----------------------------------------------------------------------
(section "11. runtime-recursive macros (awhile)")
;; ----------------------------------------------------------------------
(defmacro awhile (test . body)
  `(let ((loop nil))
     (set! loop (lambda () (if ,test (begin ,@body (loop)))))
     (loop)))
(def awhile-counter (list 0))
(def awhile-sum (list 0))
(awhile (< (car awhile-counter) 5)
  (set! awhile-sum (list (+ (car awhile-sum) (car awhile-counter))))
  (set! awhile-counter (list (+ (car awhile-counter) 1))))
(check "awhile-accumulated-sum" (car awhile-sum) 10)
(check "awhile-final-counter" (car awhile-counter) 5)


;; ----------------------------------------------------------------------
(section "12. gensym / macro hygiene")
;; ----------------------------------------------------------------------
(def gensym-counter (list 0))
(def gensym
  (lambda ()
    (set! gensym-counter (list (+ (car gensym-counter) 1)))
    (make-symbol (++ "**S-y-M-b-O-l**" (to-string (car gensym-counter))))))

(defmacro my-or2 (a b) `(let ((temp ,a)) (if temp temp ,b)))
;; Positive control: no name collision -> works fine.
(def something 42)
(check "my-or2-no-capture-when-no-clash" (my-or2 #f something) 42)
;; Capture bug demonstration: caller's OWN variable is named `temp`, which
;; collides with the macro template's internal binding and gets shadowed.
;; This is EXPECTED to be "wrong" (#f, not 999) -- it demonstrates exactly
;; the problem gensym exists to solve, not a regression.
(def temp 999)
(check "my-or2-capture-bug-demonstrated" (my-or2 #f temp) #f)

(defmacro my-or-hygienic (a b) (let ((g (gensym))) `(let ((,g ,a)) (if ,g ,g ,b))))
(def temp2 7)
(check "my-or-hygienic-avoids-capture" (my-or-hygienic #f temp2) 7)


;; ----------------------------------------------------------------------
(section "13. Dict operations")
;; ----------------------------------------------------------------------
(def d (make-dict))
(dict-set d "name" "Eagle")
(dict-set d "version" "0.9.4")
(check "dict-get" (dict-get d "name") "Eagle")
(check "dict-keys-length" (length (dict-keys d)) 2)
(def d2 (dict-clear d))
(check "dict-clear-produces-empty" (length (dict-keys d2)) 0)


;; ----------------------------------------------------------------------
(section "14. equal? vs eq divergence")
;; ----------------------------------------------------------------------
;; equal? does recursive structural comparison (custom pairEqual); eq is
;; raw Vida `==`, which does not see two separately-built Pair chains (or
;; two separately-built Symbols with the same name) as identical.
(check "equal-structural-lists" (equal? (list 1 2 3) (list 1 2 3)) #t)
(check "eq-lists-diverge" (eq (list 1 2 3) (list 1 2 3)) #f)
(check "equal-symbols-by-name" (equal? (quote foo) (quote foo)) #t)


;; ----------------------------------------------------------------------
(section "15. keyword-as-identifier (regression: Step 1 symName fix)")
;; ----------------------------------------------------------------------
;; Before Step 1, any name that used to appear in the old specialForms set
;; (if/def/defmacro/quasiquote/lambda/quote/begin/cond/let/else/set!/and/
;; or/load/nil/atom) was returned as a bare Vida string by Symbol(),
;; unconditionally -- so it could never resolve through env.find, even
;; when used as an ordinary identifier (a macro parameter, a let binding).
(defmacro aif (test then else) `(let ((it ,test)) (if it ,then ,else)))
(check "aif-then-branch" (aif (> 5 3) "yes" "no") "yes")
;; This specific case is the one that was actually broken pre-fix: the
;; `else` parameter's `,else` reference inside the template used to
;; evaluate to the literal string "else" instead of resolving via
;; env.find to the caller's real "no" argument.
(check "aif-else-branch-uses-real-arg" (aif (> 3 5) "yes" "no") "no")
(check "aif-anaphoric-it-binding" (aif 42 it "no-match") 42)

;; `else` bound and referenced as a plain let-binding, unrelated to cond.
(check "else-as-ordinary-let-binding" (let ((else 7)) (+ else 1)) 8)

;; Keyword names still work correctly AS keywords (unaffected by the fix).
(check "atom-still-works-as-keyword" (atom 5) #t)
(check "and-still-works-as-keyword" (and 1 2) 2)
;; `load` still works as a keyword too -- this whole file loading and
;; reaching this point without error is itself a live proof of that.


;; ----------------------------------------------------------------------
(section "16. Recursion sanity")
;; ----------------------------------------------------------------------
(def factorial (lambda (n) (if (eq n 0) 1 (* n (factorial (- n 1))))))
(check "factorial-5" (factorial 5) 120)
(def fib (lambda (n) (if (<= n 1) n (+ (fib (- n 1)) (fib (- n 2))))))
(check "fib-10" (fib 10) 55)


;; ----------------------------------------------------------------------
(section "17. print() calls .toString() on compound values (regression: Bug #4)")
;; ----------------------------------------------------------------------
;; prelude's print() used to hand raw args straight to Vida's native print,
;; which does a generic struct dump instead of calling a value's custom
;; toString() -- so printing a Pair/Symbol/NIL/Dict/error showed something
;; like {[car: {[symbol: A]}], [cdr: ...]} instead of "(A B C)". This can't
;; be auto-checked (print's return value is always NIL either way -- the
;; bug is purely about what gets written to the screen), so eyeball it:
;; MANUAL-VERIFY: this should print "(A B C)", not a raw struct dump.
(print (quote (A B C)))
(check "print-returns-nil-either-way" (print "manual-check above ^") NIL)


;; ----------------------------------------------------------------------
(section "18. ' quote sugar, and backtick's tokenizer-adjacency fix")
;; ----------------------------------------------------------------------
;; ' now desugars to (quote ...) exactly like ` desugars to (quasiquote ...),
;; via its own explicit alternative in the tokenizer regex (mirroring ,/,@)
;; plus a matching readFrom branch. eval needed no changes: symName-based
;; dispatch already treats a bare-string "quote" head (from ' sugar) the
;; same as a genuine Symbol("quote") head (from typing (quote ...) by hand).
(check "quote-sugar-list" '(1 2 3) (list 1 2 3))
(check "quote-sugar-symbol" 'foo (string->symbol "foo"))
(check "quote-sugar-matches-longform" '(a b) (quote (a b)))
;; ' directly against a paren, no space -- always worked, included as a
;; baseline alongside the adjacency case below.
(check "quote-sugar-adjacent-to-paren" '(x y) (list (string->symbol "x") (string->symbol "y")))
;; ' directly against a bare atom, no space -- this is the case that would
;; have broken without ''s own regex alternative (it would have tokenized
;; as the single identifier "'foo" instead of desugaring at all). Same
;; underlying gap existed for ` before this fix (masked only because every
;; existing use of ` in this codebase happens to be immediately followed
;; by "(", which was already excluded from the old catch-all).
(check "quote-sugar-adjacent-to-atom-no-space" 'foo (quote foo))
;; ' nested inside quasiquote stays literal, unevaluated data (quote does
;; not participate in unquote/depth tracking -- it's an independent
;; reader macro, not one of expandQuasiquote's three special heads).
(def qval 99)
(check "quote-nested-in-quasiquote-stays-literal"
       `(a 'b)
       (list (string->symbol "a") (list "quote" (string->symbol "b"))))
;; backtick against a bare atom, no space -- this exercises the same
;; adjacency gap being closed for ` in this same fix.
(check "quasiquote-sugar-adjacent-to-atom-no-space" `foo (quote foo))


;; ----------------------------------------------------------------------
(section "19. Pair/array unification (Step 2) -- structural regression checks")
;; ----------------------------------------------------------------------
;; eval now walks Pair-based code directly (readFrom builds Pairs, not
;; arrays; astToData/dataToAst are gone). Every section above already
;; re-validates that the visible behavior didn't change -- this section
;; targets what's specifically NEW or restructured by that rewrite.

;; A dotted quasiquote-template tail like `(1 2 . ,tail-val) reads, via
;; ordinary dotted-pair flattening, as the flat Pair chain
;; (1 2 unquote tail-val) -- structurally identical to what you'd get by
;; typing `(1 2 unquote tail-val) literally, since (a . (X . (Y . nil)))
;; IS (a X Y) in any Lisp reader. The old array-based version handled
;; this correctly only by accident (a "." sentinel string survived
;; expandQuasiquote's walk untouched, interpreted afterward by
;; astToData). The Pair-native rewrite has no such marker, so this
;; needed an explicit fix in expandQuasiquote's general-case loop.
(def tail-val 99)
(check "quasiquote-dotted-tail-unquote"
       `(1 2 . ,tail-val)
       (cons 1 (cons 2 tail-val)))

;; makeFunctionEnv was rewritten from a "."-sentinel array scan to a
;; direct Pair-chain walk (a dotted parameter list's final cdr is now
;; just a bare symbol instead of NIL). Confirm mixed fixed + rest params
;; still bind correctly.
(def combo (lambda (a b . rest) (list a b rest)))
(check "mixed-fixed-and-rest-params" (combo 1 2 3 4 5) (list 1 2 (list 3 4 5)))


(print "TOTAL:" (car test-pass) "/" (car test-total) "auto-checks passed")
(print "(plus the MANUAL-VERIFY lines in Sections 8 and 17 -- eyeball those)")
(print "====================================================\n")