(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../min-cost-flow.lisp"))

(use-package :test-util)

(with-test (:name min-cost-flow)
  (let ((graph (make-array '(5) :element-type 'list :initial-element nil)))
    (push-edge 0 1 10 2 graph)
    (push-edge 0 2 2 4 graph)
    (push-edge 1 2 6 6 graph)
    (push-edge 1 3 6 2 graph)
    (push-edge 3 2 3 3 graph)
    (push-edge 3 4 8 6 graph)
    (push-edge 2 4 5 2 graph)
    (assert (= 80 (min-cost-flow! 0 4 9 graph)))
    (assert (= 0 (min-cost-flow! 0 4 0 graph)))
    (signals not-enough-capacity-error (min-cost-flow! 0 4 90 graph))))
