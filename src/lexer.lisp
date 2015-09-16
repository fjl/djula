(in-package #:djula)

#|

The lexer tokens are of the form of (:type <string>)

The token types are:
- :comment
- :unparsed-variable
- :unparsed-translation-variable
- :unparsed-tag
- :verbatim

Although not a lexer token, the keyword :not-special is used to signify that the string following a { is not a tag. 

- :not-special: The previous { is converted into the token (:string "{")

|#

(defun token-type (char)
  "Return the token-type for CHAR."
  (case char
    (#\# :comment)
    (#\{ :unparsed-variable)
    (#\_ :unparsed-translation-variable)
    (#\% :unparsed-tag)
    (#\$ :verbatim)
    (otherwise :not-special)))

(defun get-closing-delimiter (type)
  "Return the string that closes the corresponding token TYPE."
  (ecase type
    (:comment "#}")
    (:unparsed-variable "}}")
    (:unparsed-translation-variable "_}")
    (:unparsed-tag "%}")
    (:verbatim "$}")))

(defun next-tag (string start)
  "Return the position of the start of next tag in STRING starting from START."
  (position #\{ string :start start :test 'char=))

(defun parse-tag (string current-position)
  "Return the lexer token and the index where the tag ended."
  (let ((type (token-type (char string (1+ current-position)))))
    (ecase type
      ((:comment
        :unparsed-variable
        :unparsed-translation-variable
        :unparsed-tag
        :verbatim) (let ((end (search (get-closing-delimiter type) string :start2 (1+ current-position))))
                     (if (null end)
                         (values `(:string ,(subseq string current-position)) (length string))
                         (values (list type (subseq string (+ 2 current-position) end)) (+ 2 end))))) ;; The 2 is the hard-coded length of the closing delimiters
      (:not-special (values '(:string "{")
                            (1+ current-position))))))

(defun split-template-string (template current-position)
  "Transform the TEMPLATE into a list of lexer tokens "
  (let (results)
    (loop
      :for { := (next-tag template current-position)
      :until (null {)
      :do
         (when (> { current-position)
           (push `(:string ,(subseq template current-position {)) results))
         (multiple-value-bind (token next-position) (parse-tag template {)
           (push token results)
           (setf current-position next-position)))
    (when (< current-position (length template))
      (push `(:string ,(subseq template current-position)) results))
    (nreverse results)))

(def-token-compiler :verbatim (string)
  (lambda (stream)
    (write-string string stream)))

(defun parse-template-string (string)
  (split-template-string string 0))