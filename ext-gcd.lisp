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
                     (values u (- v (* p u))))))))
    (if (>= a 0)
        (if (>= b 0)
            (%gcd a b)
            (multiple-value-bind (x y) (%gcd a (- b))
              (values x (- y))))
        (if (>= b 0)
            (multiple-value-bind (x y) (%gcd (- a) b)
              (values (- x) y))
            (multiple-value-bind (x y) (%gcd (- a) (- b))
              (values (- x) (- y)))))))

(declaim (inline mod-inverse))
(defun mod-inverse (a m)
  "Solves ax ≡ 1 mod m. A and M must be coprime."
  (assert (>= m 2))
  (mod (ext-gcd a m) m))

;; test
(progn
  (dotimes (i 100)
    (let ((a (- (random 20) 10))
          (b (- (random 20) 10)))
      (multiple-value-bind (x y) (ext-gcd a b)
        (assert (= (+ (* a x) (* b y)) (gcd a b))))))
  (dotimes (i 1000)
    (let ((a (random 100))
          (m (+ 2 (random 100))))
      (assert (or (/= 1 (gcd a m))
                  (= 1 (mod (* a (mod-inverse a m)) m)))))))
