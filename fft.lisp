;;;
;;; FFT by simple recursion
;;;

(deftype fft-float () 'double-float)

(declaim (inline power2-at-least))
(defun power2-at-least (x)
  "Returns the smallest power of 2 equal or larger than x."
  (ash 1 (integer-length (- x 1))))

(declaim (inline logreverse))
(defun logreverse (x size)
  (declare ((unsigned-byte 64) x)
           ((integer 0 64) size))
  (if (<= size 8)
      (ash (mod (logand (* x #x0202020202) #x010884422010) 1023)
           (- size 8))
      (progn
        (setq x (logior (ash (logand x #xaaaaaaaaaaaaaaaa) -1)
                        (ash (logand x #x5555555555555555) 1)))
        (setq x (logior (ash (logand x #xcccccccccccccccc) -2)
                        (ash (logand x #x3333333333333333) 2)))
        (setq x (logior (ash (logand x #xf0f0f0f0f0f0f0f0) -4)
                        (ash (logand x #x0f0f0f0f0f0f0f0f) 4)))
        (setq x (logior (ash (logand x #xff00ff00ff00ff00) -8)
                        (ash (logand x #x00ff00ff00ff00ff) 8)))
        (setq x (logior (ash (logand x #xffff0000ffff0000) -16)
                        (ash (logand x #x0000ffff0000ffff) 16)))
        (ash (logior (ash x -32)
                     (ldb (byte 64 0) (ash x 32)))
             (- size 64)))))

(defun dft! (f size)
  (declare ((simple-array (complex fft-float) (*)) f))
  (prog1 f
    (let ((n (length f))) ; must be power of 2
      (unless (= n 1)
        (let ((f0 (make-array (floor n 2) :element-type '(complex fft-float)))
              (f1 (make-array (floor n 2) :element-type '(complex fft-float))))
          (dotimes (i (floor n 2))
            (setf (aref f0 i) (aref f (* i 2))
                  (aref f1 i) (aref f (+ (* i 2) 1))))
          (dft! f0)
          (dft! f1)
          (let ((zeta (cis (/ #.(coerce (* 2 pi) 'fft-float) n)))
                (power-zeta #.(coerce #c(1d0 0d0) '(complex fft-float))))
            (declare ((complex fft-float) power-zeta))
            (dotimes (i n)
              (let ((subindex (mod i (ash n -1))))
                (setf (aref f i)
                      (+ (aref f0 subindex)
                         (* power-zeta (aref f1 subindex))))
                (setf power-zeta (* power-zeta zeta))))))))))

(defun inverse-dft! (f)
  (declare ((simple-array (complex fft-float) (*)) f))
  (labels ((%idft! (f)
             (declare ((simple-array (complex fft-float) (*)) f))
             (prog1 f
               (let ((n (length f))) ; must be power of 2
                 (unless (= n 1)
                   (let ((f0 (make-array (floor n 2) :element-type '(complex fft-float)))
                         (f1 (make-array (floor n 2) :element-type '(complex fft-float))))
                     (dotimes (i (floor n 2))
                       (setf (aref f0 i) (aref f (* i 2))
                             (aref f1 i) (aref f (+ (* i 2) 1))))
                     (%idft! f0)
                     (%idft! f1)
                     (let ((zeta (cis (/ #.(coerce (* -2 pi) 'fft-float) n)))
                           (power-zeta #.(coerce #c(1d0 0d0) '(complex fft-float))))
                       (declare ((complex fft-float) power-zeta))
                       (dotimes (i n)
                         (let ((subindex (mod i (ash n -1))))
                           (setf (aref f i)
                                 (+ (aref f0 subindex)
                                    (* power-zeta (aref f1 subindex))))
                           (setf power-zeta (* power-zeta zeta)))))))))))
    (let* ((n (length f))
           (/n (/ (coerce n 'fft-float))))
      (%idft! f)
      (dotimes (i n f)
        (setf (aref f i) (* (aref f i) /n))))))

(declaim (inline power2-p))
(defun power2-p (x)
  "Checks if X is a power of 2."
  (zerop (logand x (- x 1))))

(declaim (inline poly-multiply!))
(defun poly-multiply! (g h)
  (declare ((simple-array (complex fft-float) (*)) g h))
  (assert (and (power2-p (length g))
               (power2-p (length h))
               (= (length g) (length h))))
  (let ((n (length g)))
    (dft! g)
    (dft! h)
    (let ((f (make-array n :element-type '(complex fft-float))))
      (dotimes (i n)
        (setf (aref f i) (* (aref g i) (aref h i))))
      (inverse-dft! f))))

(defun to-fft-array (f)
  (let ((res (make-array (length f) :element-type '(complex fft-float))))
    (dotimes (i (length f))
      (setf (aref res i) (coerce (aref f i) '(complex double-float))))
    res))

;; test
(map ()
     (lambda (x y) (assert (< (abs (- (realpart x) y)) 1d-8)))
     (poly-multiply! (to-fft-array #(1 2 3 4 0 0 0 0))
		     (to-fft-array #(-1 -1 -1 -1 0 0 0 0)))
     #(-1 -3 -6 -10 -9 -7 -4 0))
