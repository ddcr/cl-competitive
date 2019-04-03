(defun parse-bignum (simple-base-string &key (start 0) end)
  "Is a variant of SBCL(x64)'s PARSE-INTEGER. Can also parse fixnum but is
optimized to big integer."
  (sb-c::with-array-data ((string simple-base-string :offset-var offset)
                          (start start)
                          (end end)
                          :check-fill-pointer t)
    (let ((index (do ((i start (1+ i)))
                     ((= i end)
                      (return-from parse-bignum (values nil end)))
                   (declare (fixnum i))
                   (unless (char= #\Space (schar string i)) (return i))))
          (minusp nil)
          (result 0)
          (mid-result 0)
          (index-mod18 0))
      (declare (fixnum index mid-result)
               ((integer 0 19) index-mod18)
               (integer result))
      (let ((char (schar string index)))
        (cond ((char= char #\-)
               (setq minusp t)
               (incf index))
              ((char= char #\+)
               (incf index))))
      (loop
        (when (= index-mod18 18)
          (setq result (+ mid-result (* result #.(expt 10 18))))
          (setq mid-result 0)
          (setq index-mod18 0))
        (when (= index end) (return nil))
        (let* ((char (schar string index))
               (weight (- (char-code char) 48)))
          (if (<= 0 weight 9)
              (setq mid-result (+ weight (* 10 (the (integer 0 #.(expt 10 17)) mid-result))))
              (return nil)))
        (incf index)
        (incf index-mod18))
      (setq result (+ mid-result (* result (expt 10 index-mod18))))
      (values
       (if minusp (- result) result)
       (- index offset)))))
