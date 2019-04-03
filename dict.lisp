
(declaim (inline dict<))
(defun dict< (str1 str2)
  (let* ((len1 (length str1))
         (len2 (length str2)))
    (loop for i below (min len1 len2)
          for c1 = (aref str1 i)
          for c2 = (aref str2 i)
          do (cond ((char< c1 c2) (return t))
                   ((char> c1 c2) (return nil)))
          finally (return (if (< len1 len2) t nil)))))
