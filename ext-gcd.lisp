(declaim (inline ext-gcd))
(defun ext-gcd (a b)
  "Returns two integers X and Y where AX + BY = gcd(A, B) holds."
  (declare (fixnum a b))
  (labels ((%gcd (a b)
             (declare (fixnum a b))
             (if (zerop b)
                 (values 1 0)
                 (multiple-value-bind (p q) (floor a b) ; a = pb + q
                   (multiple-value-bind (v u) (%gcd b q)
                     (declare (fixnum u v))
                     (values u (the fixnum (- v (the fixnum (* p u))))))))))
    (if (>= a 0)
        (if (>= b 0)
            (%gcd a b)
            (multiple-value-bind (x y) (%gcd a (- b))
              (declare (fixnum x y))
              (values x (- y))))
        (if (>= b 0)
            (multiple-value-bind (x y) (%gcd (- a) b)
              (declare (fixnum x y))
              (values (- x) y))
            (multiple-value-bind (x y) (%gcd (- a) (- b))
              (declare (fixnum x y))
              (values (- x) (- y)))))))

(declaim (inline mod-inverse))
(defun mod-inverse (a m)
  "Solves ax ≡ 1 mod m. A and M must be coprime."
  (declare (fixnum a)
           ((integer 1 #.most-positive-fixnum) m))
  (mod (ext-gcd a m) m))

(declaim (ftype (function * (values (or null (integer 1 #.most-positive-fixnum)) &optional)) mod-log))
(defun mod-log (x y divisor)
  "Returns the smallest positive integer k that satiefies x^k ≡ y mod p and
returns NIL if it is infeasible."
  (declare (integer x y)
           ((integer 1 #.most-positive-fixnum) divisor))
  (let ((x (mod x divisor))
        (y (mod y divisor)))
    (declare ((mod #.most-positive-fixnum) x y))
    (if (= 1 (gcd x divisor))
        (let* ((m (+ 1 (isqrt (- divisor 1)))) ; smallest integer equal or larger than √p
               (x^m (loop for i below m
                          for res of-type (integer 0 #.most-positive-fixnum) = x
                          then (mod (* res x) divisor)
                          finally (return res)))
               (table (make-hash-table :size m)))
          ;; Construct TABLE: yx^j |-> j (j = 0, ..., m-1)
          (loop for j from 0 below m
                for res of-type (integer 0 #.most-positive-fixnum) = y
                then (mod (* res x) divisor)
                do (setf (gethash res table) j))
          ;; Find i, j that satisfies (x^m)^i = yx^j and returns m*i-j
          (loop for i from 1 to m
                for x^m^i of-type (integer 0 #.most-positive-fixnum) = x^m
                then (mod (* x^m^i x^m) divisor)
                for j = (gethash x^m^i table)
                when j
                do (locally
                       (declare ((integer 0 #.most-positive-fixnum) j))
                     (return (- (* i m) j)))
                finally (return nil)))
        ;; If x and p are not coprime, let g := gcd(x, p), x := gx', y := gy', p
        ;; := gp' and solve x^(k-1) ≡ y'x'^(-1) mod p' instead. See
        ;; https://math.stackexchange.com/questions/131127/ for the detail.
        (let ((g (gcd x divisor)))
          (declare ((integer 0 #.most-positive-fixnum) g))
          ;; KLUDGE: special treatment for the case x ≡ y. Without this (mod-log
          ;; 4 0 4) returns not 1 but 2.
          (when (= x y)
            (return-from mod-log 1))
          (multiple-value-bind (y-prime rem) (floor y g)
            (if (zerop rem)
                (let* ((x-prime (floor x g))
                       (p-prime (floor divisor g))
                       (next-rhs (mod (* y-prime (mod-inverse x-prime p-prime)) p-prime))
                       (res (mod-log x next-rhs p-prime)))
                  (declare ((integer 0 #.most-positive-fixnum) next-rhs))
                  (if res (+ 1 res) nil))
                nil))))))

;; test
;; (progn
;;   (dotimes (i 100)
;;     (let ((a (- (random 20) 10))
;;           (b (- (random 20) 10)))
;;       (multiple-value-bind (x y) (ext-gcd a b)
;;         (assert (= (+ (* a x) (* b y)) (gcd a b))))))
;;   (dotimes (i 1000)
;;     (let ((a (random 100))
;;           (m (+ 2 (random 100))))
;;       (assert (or (/= 1 (gcd a m))
;;                   (= 1 (mod (* a (mod-inverse a m)) m)))))))

;; (progn
;;   (assert (= 8 (mod-log 6 4 44)))
;;   (assert (= 8 (mod-log -38 -40 44)))
;;   (assert (null (mod-log 6 2 44)))
;;   (assert (= 2 (mod-log 8 4 12)))
;;   (assert (= 4 (mod-log 3 13 17)))
;;   (assert (= 1 (mod-log 12 0 4)))
;;   (assert (= 2 (mod-log 12 0 8)))
;;   (assert (null (mod-log 12 1 8)))
;;   (assert (= 1 (mod-log 0 0 100))))
