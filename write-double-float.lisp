;; Based on SBCL's implementation
(defun write-double-float (x &optional (stream *standard-output*))
  (declare (double-float x))
  (if (minusp x)
      (progn (write-char #\- stream)
             (when (> x -1d0)
               (write-char #\0 stream)))
      (when (< x 1d0)
        (write-char #\0 stream)))
  (multiple-value-bind (e string)
      (sb-impl::flonum-to-digits x)
    (declare (fixnum e)
             (simple-base-string string))
    (if (plusp e)
        (let ((len (length string)))
          (write-string string stream :end (min len e))
          (dotimes (i (- e len))
            (write-char #\0 stream))
          (write-char #\. stream)
          (write-string string stream :start (min len e)))
        (progn
          (write-char #\. stream)
          (dotimes (i (- e))
            (write-char #\0 stream))
          (write-string string stream)))
    (write-char #\0 stream)))
