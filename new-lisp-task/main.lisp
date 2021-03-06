(defun print-with-tab(body &optional (count 1))
   (dotimes (n count)
      (princ #\tab)
   )
   (funcall body))

(defun print-word(word quote)
   (if quote
       (format t "\"~A\"" word)
       (format t "~A" word)))

(defun print-pair(key val &key (left-quote t) (right-quote t))
   (print-word key left-quote)
   (princ ":")
   (print-word val right-quote))

(defun print-alist(alist body)
   (mapcar (lambda (pair)
              (let ((key (car pair)) (val (cadr pair)) )
                 (funcall body key val)
              ))
    alist))

(defun print-attr(key val)
   (print-with-tab (lambda ()
                      (print-pair key val)
                      (format t "~%")) 2))

(defun print-commaln()
   (format t ",~%"))

(let ((name (read)))
   (if (eq name nil)
       (princ "no arguments")
       (progn
          (format t "{~%")
          (print-with-tab (lambda ()
                             (format t "\"label\": \"~A\"" name)
                             (print-commaln)))
          (print-with-tab (lambda ()
                             (print-pair "type" "shell")
                             (print-commaln)))
          (print-with-tab (lambda ()
                             (print-pair "options" "{" :right-quote nil)
                             (format t "~%")
                             ))
          (print-alist (list
              (list "cwd"  name)
          ) #'print-attr)
          (print-with-tab (lambda ()
                             (princ "}")
                             (print-commaln)))
          (print-with-tab (lambda ()
                             (print-pair "command" "ros -l main.lisp")))
          (format t "~%},"))
   ))