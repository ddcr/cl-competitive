(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../buffered-read-line.lisp")
  (load "../read-line-into.lisp"))

(use-package :test-util)

;;;
;;; buffered-read-line.lisp
;;; read-line-into.lisp
;;;

;; acknowledge: https://stackoverflow.com/questions/41378669/how-to-get-a-stream-from-a-bit-vector-in-common-lisp
(defclass octet-input-stream (fundamental-binary-input-stream)
  ((data :initarg :data :type (vector (unsigned-byte 8)))
   (position :initform 0)))

(defmethod stream-element-type ((stream octet-input-stream))
  '(unsigned-byte 8))

(defmethod stream-read-byte ((stream octet-input-stream))
  (with-slots (data position) stream
    (if (< position (length data))
        (prog1 (aref data position)
          (incf position))
        :eof)))

(defun make-octet-input-stream (data)
  (etypecase data
    (string (let ((octets (make-array (length data) :element-type '(unsigned-byte 8))))
              (dotimes (i (length data))
                (setf (aref octets i) (char-code (aref data i))))
              (make-instance 'octet-input-stream :data octets)))
    (sequence (make-instance 'octet-input-stream
                              :data (coerce data '(simple-array (unsigned-byte 8) (*)))))))

(with-test (:name buffered-read-line)
  (let ((*standard-input* (make-octet-input-stream "foo")))
    (assert (equalp "foo  " (buffered-read-line 5))))
  (let ((*standard-input* (make-octet-input-stream "foo")))
    (assert (equalp "foo" (buffered-read-line 3)))))

(with-test (:name read-line-into)
  (let ((buf (make-string 5 :element-type 'base-char))
        (*standard-input* (make-octet-input-stream "foo")))
    (assert (equalp "foo  " (read-line-into buf))))
  (let ((buf (make-string 3))
        (*standard-input* (make-octet-input-stream "foo")))
    (assert (equalp "foo" (read-line-into buf)))))

