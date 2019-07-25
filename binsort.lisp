;; TODO: enable to deal with any ordered sets.

(declaim (inline map-binsort))
(defun map-binsort (function sequence range-max &key from-end key)
  "Calls FUNCTION with each ascending non-negative integer in SEQUENCE if KEY is
null. If KEY is non-nil, this function calls FUNCTION with each element of
SEQUENCE in the order of the (non-negative) integers that (FUNCALL KEY
<element>) returns. Any these integers must not exceed RANGE-MAX. If FROM-END is
true, the descending order is adopted instead. This function is
non-destructive."
  (declare ((mod #.array-total-size-limit) range-max))
  (if key
      (let ((buckets (make-array (1+ range-max) :element-type 'list :initial-element nil))
            (existing-min most-positive-fixnum)
            (existing-max 0))
        (declare (dynamic-extent buckets))
        (sequence:dosequence (e sequence)
          (let ((value (funcall key e)))
            (push e (aref buckets value))
            (setf existing-min (min value existing-min))
            (setf existing-max (max value existing-max))))
        (if from-end
            (loop for x from existing-max downto existing-min
                  do (dolist (e (aref buckets x))
                       (funcall function e)))
            (loop for x from existing-min to existing-max
                  do (dolist (e (aref buckets x))
                       (funcall function e)))))
      ;; If KEY is not given, all we need is counting sort.
      (let ((counts (make-array (1+ range-max) :element-type 'fixnum :initial-element 0))
            (existing-min most-positive-fixnum)
            (existing-max 0))
        (declare (dynamic-extent counts))
        (sequence:dosequence (e sequence)
          (incf (aref counts e))
          (setf existing-min (min e existing-min))
          (setf existing-max (max e existing-max)))
        (if from-end
            (loop for x from existing-max downto existing-min
                  do (loop repeat (aref counts x)
                           do (funcall function x)))
            (loop for x from existing-min to existing-max
                  do (loop repeat (aref counts x)
                           do (funcall function x)))))))

(defmacro do-binsort ((var sequence range-max &key from-end key finally) &body body)
  "DO-style macro of MAP-BINSORT"
  `(block nil
     (map-binsort (lambda (,var) ,@body) ,sequence ,range-max
                    :from-end ,from-end :key ,key)
     ,finally))
