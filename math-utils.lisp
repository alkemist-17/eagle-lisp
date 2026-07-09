;; math-utils.lisp
(def PI 3.14159)

(def square 
  (lambda (x) (* x x)))

(def greet 
  (lambda (name) 
    (puts "Hello from the external file," name)))
