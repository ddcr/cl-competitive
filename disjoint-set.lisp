;;;
;;; Disjoint set by Union-Find algorithm
;;;

(defstruct (disjoint-set
            (:constructor make-disjoint-set
                (size &aux (data (make-array size :element-type 'fixnum :initial-element -1))))
            (:conc-name ds-))
  (data nil :type (simple-array fixnum (*))))

(declaim (ftype (function * (values (mod #.array-total-size-limit) &optional)) ds-root))
(defun ds-root (x disjoint-set)
  "Returns the root of X."
  (declare (optimize (speed 3))
           ((mod #.array-total-size-limit) x))
  (let ((data (ds-data disjoint-set)))
    (if (< (aref data x) 0)
        x
        (setf (aref data x)
              (ds-root (aref data x) disjoint-set)))))

(declaim (inline ds-unite!))
(defun ds-unite! (x1 x2 disjoint-set)
  "Destructively unites X1 and X2 and returns true iff X1 and X2 become
connected for the first time."
  (let ((root1 (ds-root x1 disjoint-set))
        (root2 (ds-root x2 disjoint-set)))
    (unless (= root1 root2)
      (let ((data (ds-data disjoint-set)))
        ;; ensure the size of root1 >= the size of root2
        (when (> (aref data root1) (aref data root2))
          (rotatef root1 root2))
        (incf (aref data root1) (aref data root2))
        (setf (aref data root2) root1)))))

(declaim (inline ds-connected-p))
(defun ds-connected-p (x1 x2 disjoint-set)
  "Returns true iff X1 and X2 have the same root."
  (= (ds-root x1 disjoint-set) (ds-root x2 disjoint-set)))

(declaim (inline ds-size))
(defun ds-size (x disjoint-set)
  "Returns the size of the connected component to which X belongs."
  (- (aref (ds-data disjoint-set)
           (ds-root x disjoint-set))))
