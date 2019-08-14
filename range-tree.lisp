;;;
;;; Range tree (unfinished)
;;;

(defstruct (xnode (:constructor make-xnode (xkey ykey ynode left right))
                  (:conc-name %xnode-)
                  (:copier nil))
  (xkey 0 :type fixnum)
  (ykey 0 :type fixnum)
  ynode
  left right)

(defstruct (ynode (:constructor make-ynode (xkey ykey left right &key (count 1)))
                  (:conc-name %ynode-)
                  (:copier nil))
  (xkey 0 :type fixnum)
  (ykey 0 :type fixnum)
  left
  right
  (count 1 :type (integer 0 #.most-positive-fixnum)))

(declaim (inline ynode-count))
(defun ynode-count (ynode)
  (if (null ynode)
      0
      (%ynode-count ynode)))

(declaim (inline ynode-update-count))
(defun ynode-update-count (ynode)
  (setf (%ynode-count ynode)
        (+ 1
           (ynode-count (%ynode-left ynode))
           (ynode-count (%ynode-right ynode)))))

;;
;; Merging w.r.t. Y-axis in O(n) time:
;; 1. transform two trees to pathes (with copying);
;; 2. merge the two pathes into a path (destructively);
;; 3. transform the path to a tree (destructively);
;;

(defun %ynode-to-path (ynode)
  "Returns a path that is equivalent to YNODE but in reverse order."
  (declare (inline make-ynode))
  (let ((res nil))
    (labels ((recur (node)
               (when node
                 (recur (%ynode-left node))
                 (setq res (make-ynode (%ynode-xkey node) (%ynode-ykey node) nil res))
                 (recur (%ynode-right node)))))
      (recur ynode)
      res)))

(declaim (inline %ynode-merge-path!))
(defun %ynode-merge-path! (ypath1 ypath2 &key (order #'<))
  "Destructively merges two pathes in reverse order."
  (let ((res nil))
    (macrolet ((%push (y)
                 `(let ((rest (%ynode-right ,y)))
                    (setf (%ynode-right ,y) res
                          res ,y
                          ,y rest))))
      (loop (unless ypath1
              (loop while ypath2 do (%push ypath2))
              (return))
            (unless ypath2
              (loop while ypath1 do (%push ypath1))
              (return))
            (if (funcall order (%ynode-key ypath1) (%ynode-key ypath2))
                (%push ypath2)
                (%push ypath1)))
      res)))

(defun %path-to-ynode! (ypath length)
  "Destructively transforms a path to a balanced binary tree."
  (declare ((integer 0 #.most-positive-fixnum) length))
  (let* ((max-depth (- (integer-length length) 1)))
    (macrolet ((%pop ()
                 `(let ((rest (%ynode-right ypath)))
                    (setf (%ynode-right ypath) nil)
                    (prog1 ypath
                      (setq ypath rest)))))
      (labels ((build (depth)
                 (declare ((integer 0 #.most-positive-fixnum) depth))
                 (when ypath
                   (if (= depth max-depth)
                       (%pop)
                       (let ((left (build (+ 1 depth))))
                         (if (null ypath)
                             left
                             (let* ((node (%pop))
                                    (right (build (+ 1 depth))))
                               (setf (%ynode-left node) left)
                               (setf (%ynode-right node) right)
                               (ynode-update-count node)
                               node)))))))
        (build 0)))))

(declaim (inline ynode-merge))
(defun ynode-merge (ynode1 ynode2 &key (order #'<))
  "Merges two ynodes non-destructively."
  (let* ((length (+ (ynode-count ynode1) (ynode-count ynode2))))
    (%path-to-ynode!
     (%ynode-merge-path! (%ynode-to-path ynode1)
                         (%ynode-to-path ynode2)
                         :order order)
     (the fixnum length))))

(defun make-range-tree (vector)
  (declare (vector vector))
  (labels ((build (l r)
             (declare ((integer 0 #.most-positive-fixnum) l r))
             (if (= (- r l) 1)
                 (let ((cell (aref vector l)))
                   (make-xnode (car cell) (cdr cell)
                               (make-ynode (car cell) (cdr cell) nil nil)
                               nil nil))
                 (let* ((mid (ash (+ l r) -1))
                        (med (aref vector mid))
                        (left (build l mid))
                        (right (build mid r)))
                   (make-xnode (car med) (cdr med)
                               (ynode-merge (%xnode-ynode left)
                                            (%xnode-ynode right))
                               left right)))))
    (build 0 (length vector))))

(defconstant +neg-inf+ most-negative-fixnum)
(defconstant +pos-inf+ most-positive-fixnum)

(declaim (inline xleaf-p))
(defun xleaf-p (xnode)
  (and (null (%xnode-left xnode)) (null (%xnode-right xnode))))

(defun rt-count (range-tree x1 y1 x2 y2)
  "Returns the number of the nodes in the rectangle [x1, y1)*[x2, y2)"
  (declare (optimize (speed 3))
           ((or null fixnum) x1 y1 x2 y2))
  (setq x1 (or x1 +neg-inf+)
        x2 (or x2 +pos-inf+)
        y1 (or y1 +neg-inf+)
        y2 (or y2 +pos-inf+))
  (labels ((xrecur (xnode x1 x2)
             (declare ((or null xnode) xnode)
                      (fixnum x1 x2))
             (cond ((null xnode) 0)
                   ((and (= x1 +neg-inf+) (= x2 +pos-inf+))
                    (yrecur (%xnode-ynode xnode) y1 y2))
                   (t
                    (let ((key (%xnode-key xnode)))
                      (if (<= x1 key)
                          (if (< key x2)
                              (if (xleaf-p xnode)
                                  (yrecur (%xnode-ynode xnode) y1 y2)
                                  (+ (xrecur (%xnode-left xnode) x1 +pos-inf+)
                                     (xrecur (%xnode-right xnode) +neg-inf+ x2)))
                              (xrecur (%xnode-left xnode) x1 x2))
                          (xrecur (%xnode-right xnode) x1 x2))))))
           (yrecur (ynode y1 y2)
             (declare ((or null ynode) ynode)
                      (fixnum y1 y2))
             (cond ((null ynode) 0)
                   ((and (= y1 +neg-inf+) (= y2 +pos-inf+))
                    (%ynode-count ynode))
                   (t
                    (let ((key (%ynode-key ynode)))
                      (if (<= y1 key)
                          (if (< key y2)
                              (+ 1
                                 (yrecur (%ynode-left ynode) y1 +pos-inf+)
                                 (yrecur (%ynode-right ynode) +neg-inf+ y2))
                              (yrecur (%ynode-left ynode) y1 y2))
                          (yrecur (%ynode-right ynode) y1 y2)))))))
    (declare (ftype (function * (values (integer 0 #.most-positive-fixnum) &optional)) xrecur yrecur))
    (xrecur range-tree x1 x2)))

;; For development
(defun list-to-ynode (list &optional length)
  (declare (list list))
  (let* ((length (or length (length list)))
         (max-depth (- (integer-length length) 1)))
    (labels ((build (depth)
               (declare ((integer 0 #.most-positive-fixnum) depth))
               (when list
                 (if (= depth max-depth)
                     (make-ynode 0 (pop list) nil nil)
                     (let ((left (build (+ 1 depth))))
                       (if (null list)
                           left
                           (let* ((med (pop list))
                                  (right (build (+ 1 depth)))
                                  (node (make-ynode 0 med left right)))
                             (ynode-update-count node)
                             node)))))))
      (build 0))))