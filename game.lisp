; ===============================
;           Eagle Lisp
; ===============================


(clear)


(print "Welcome to Eagle Lisp")


(def g (lambda ()
    (load "game.lisp")))


(defmacro alpha ()
    `(+ 1 ,(+ 2 3)))



(print "`game.lisp` loaded successfully")






