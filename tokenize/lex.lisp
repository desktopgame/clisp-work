(defun not-eq(a b)
   (not (eq a b)))

(defstruct segment (chars (list)) (next nil) (id nil) (undefined nil))

(defun debug-print(a)
   (princ ": ")
   (princ a)
   (format t "~%"))


(defun read-many(cond)
   "cond に source の先頭から一文字ずつ文字を与えて、
    t を返す限り文字列をバッファします。
    t 以外の値が返されると、その時点のバッファと source から segment を作成して返します。"
   (lambda (source)
      (let ((c (car source)) (tail (cdr source)) (buf '()) (len 0) (e nil))
         (loop while (and (not-eq c nil) (funcall cond c)) do
            (setf e c)
            (setf c (car tail))
            (setf tail (cdr tail))
            (incf len)
            (push e buf))  (make-segment :chars (nreverse buf)
                                         :next (make-segment :chars (push c tail))) )))

(defun read-identifier()
   "read-many の カバー関数です。
    文字が アルファベット で有る限りバッファします。"
   (read-many #'isident))

(defun read-digit()
   "read-many の カバー関数です。
    文字が 数字 で有る限りバッファします。"
   (read-many #'isdigit))

(defun defun-read-once(name a)
   "`一文字だけ読み取って、それが a と同じなら segment を返す`
    関数を定義するマクロです。"
   (lambda (source)
        (if (char= a (car source))
            (make-segment :chars (list (car source))
                       :next (make-segment :chars (cdr source)))
            (make-segment :chars nil
                       :next (make-segment :chars source)))))

(defun defun-read-fusion(name a b)
   "`a の戻り値 seg-a を入力として b を呼び出し、
    両方の chars を連結した新しい segment を返す` 関数を定義するマクロです。"
   (lambda (source)
       (let* ((al (funcall a source)) (ala (segment-chars al)) (ald (segment-next al)))
          (if ala
             (let* ((bl (funcall b  (segment-chars ald))) (bla (segment-chars bl)) (bld (segment-next bl)))
                (make-segment :chars (append ala bla)
                           :next (make-segment :chars bld))
             )
             (make-segment :chars nil
                        :next (make-segment :chars ald)) ))))


(defun scan-word(source word)
   "source から一文字ずつ読み取って、 word と前方一致する限りそれを続行します。
    前方一致が途絶えた、あるいは完全に一致することが確認された場合には
    その時点での残りの文字列を返します。"
   (if word
       (if (char= (car source) (car word))
           (scan-word (cdr source) (cdr word))
           source)
        source))

(defun defun-read-word(name word)
   "`word という文字列との前方一致によって segment を返す` 関数を定義するマクロです。"
   (lambda (source)
       (let ((tail (scan-word source word)))
          (if (= (+ (length word) (length tail)) (length source))
              (make-segment :chars word
                            :next (make-segment :chars tail))
              (make-segment :chars nil
                            :next (make-segment :chars source))
          ))))

(defmacro defun-read-string(name word)
    "引数を list へ変換して、defun-read-word へ渡すマクロです。"
   `(defun-read-word ,name (coerce ,word 'list)))

(defun wrap-reader(proxy id)
   "`proxy の戻り値の segment の segment-id を id に変更して返す`
     ラムダを返します。"
   (format t "~a ~a~%" (type-of proxy) (type-of id))
   (lambda (source)
      (let ((seg (funcall proxy source)))
         (setf (segment-id seg) id) seg)))

(defun define-reader(head tailing)
   (let ((id (car tailing)))
      (values (wrap-reader head id) (cdr tailing))))

(defun define-readers-by(values)
   (let ((ret (list)))
      (loop while values do
         (multiple-value-bind (reader tailing) (define-reader (car values) (cdr values))
            (push reader ret)
            (setf values tailing)
         )) ret))

(defmacro define-readers(&body elements)
   `(define-readers-by (list ,@elements)))

(defun read-lex-one(source readers)
   "source に対して 一つづつ readers を適用して、
    有効な segment が返された時点でそれを戻り値とします。"
   (if readers
      (let ((ca (funcall (car readers) source)))
         (if (segment-chars ca)
             ca
             (read-lex-one source (cdr readers))))
      (make-segment :id :none)))

(defun read-lex-all(source readers)
   "source が空になるまで readers によって解析します。
    解析された segment のリストが戻り値となります。"
   (let ((buf (list)))
      (loop while source do
         (let ((ca (read-lex-one source readers)))
            (if (not-eq (segment-chars ca) nil)
                (progn
                   (push ca buf)
                   (setf source (segment-chars (segment-next ca))))
                (progn
                   (let ((segment (make-segment)))
                      (setf (segment-undefined segment) t)
                      (push (car source) (segment-chars segment))
                      (push segment buf)
                      (setf source (cdr source))
                      ))
            )))
    (nreverse buf)))