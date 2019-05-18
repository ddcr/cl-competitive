;;
;; Calculate a^n in log(n) time on any monoids
;;

(declaim (inline power))
(defun power (base exponent op identity)
  (declare ((integer 0) exponent)
           (function op))
  (labels ((recur (x p)
             (declare ((integer 0 #.most-positive-fixnum) p))
             (cond ((zerop p) identity)
                   ((evenp p) (recur (funcall op x x) (ash p -1)))
                   (t (funcall op x (recur x (- p 1))))))
           (recur-big (x p)
             (declare ((integer 0) p))
             (cond ((zerop p) identity)
                   ((evenp p) (recur-big (funcall op x x) (ash p -1)))
                   (t (funcall op x (recur-big x (- p 1)))))))
    (typecase exponent
      (fixnum (recur base exponent))
      (otherwise (recur-big base exponent)))))
