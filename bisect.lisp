(declaim (inline bisect-left))
(defun bisect-left (target value &key (start 0) end (order #'<) (key #'identity))
  "TARGET := vector | function (taking an integer argument)
ORDER := strict order

Analogue of lower_bound() of C++ or bisect_left() of Python: Returns the
smallest index (or input) i that fulfills TARGET[i] >= VALUE, where '>=' is the
complement of ORDER. In other words, this function returns the leftmost index at
which VALUE can be inserted with keeping the order. Therefore, TARGET must be
monotonically non-decreasing with respect to ORDER.

- This function returns END if VALUE exceeds TARGET[END-1]. 
- The range [START, END) is half-open.
- END must be explicitly specified if TARGET is function.
- KEY is applied to each element of TARGET before comparison."
  (declare (function key order)
           (integer start)
           ((or null integer) end))
  (macrolet
      ((frob (accessor &optional declaration)
         `(progn
            (assert (<= start end))
            (if (= start end) end
                (labels
                    ((%bisect-left (left ok)
                       ;; TARGET[OK] >= VALUE always holds (assuming
                       ;; TARGET[END] = +infinity)
                       ,@(when declaration (list declaration))
                       (let ((mid (ash (+ left ok) -1)))
                         (if (= mid left)
                             (if (funcall order (funcall key (,accessor target left)) value)
                                 ok
                                 left)
                             (if (funcall order (funcall key (,accessor target mid)) value)
                                 (%bisect-left mid ok)
                                 (%bisect-left left mid))))))
                  (%bisect-left start end))))))
    (etypecase target
      (vector
       (let ((end (or end (length target))))
         (frob aref (declare ((integer 0 #.most-positive-fixnum) left ok)))))
      (function
       (assert end () "Requires END argument if TARGET is a function.")
       (frob funcall)))))

(declaim (inline bisect-right))
(defun bisect-right (target value &key (start 0) end (order #'<) (key #'identity))
  "TARGET := vector | function (taking an integer argument)
ORDER := strict order

Analogue of upper_bound() of C++ or bisect_right() of Python: Returns the
smallest index (or input) i that fulfills TARGET[i] > VALUE. In other words,
this function returns the rightmost index at which VALUE can be inserted with
keeping the order. Therefore, TARGET must be monotonically non-decreasing with
respect to ORDER.

- This function returns END if VALUE >= TARGET[END-1].
- The range [START, END) is half-open.
- END must be explicitly specified if TARGET is function.
- KEY is applied to each element of TARGET before comparison."
  (declare (function key order)
           (integer start)
           ((or null integer) end))
  (macrolet
      ((frob (accessor &optional declaration)
         `(progn
            (assert (<= start end))
            (if (= start end)
                end
                (labels
                    ((%bisect-right (left ok)
                       ;; TARGET[OK] > VALUE always holds (assuming
                       ;; TARGET[END] = +infinity)
                       ,@(when declaration (list declaration))
                       (let ((mid (ash (+ left ok) -1)))
                         (if (= mid left)
                             (if (funcall order value (funcall key (,accessor target left)))
                                 left
                                 ok)
                             (if (funcall order value (funcall key (,accessor target mid)))
                                 (%bisect-right left mid)
                                 (%bisect-right mid ok))))))
                  
                  (%bisect-right start end))))))
    (etypecase target
      (vector
       (let ((end (or end (length target))))
         (frob aref (declare ((integer 0 #.most-positive-fixnum) left ok)))))
      (function
       (assert end () "Requires END argument if TARGET is a function.")
       (frob funcall)))))
