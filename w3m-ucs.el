;;; w3m-ucs.el --- CCL codes to handle UCS characters.

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>
;; Keywords: w3m, WWW, hypermedia

;; This file is a part of emacs-w3m.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.


;;; Commentary:

;; This file contains CCL codes to handle UCS characters in emacs-w3m.
;; For more detail about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/

;; This module requires `Mule-UCS' package.  It can be downloaded from:
;;
;;    ftp://ftp.m17n.org/pub/mule/Mule-UCS/


;;; How to install:

;; Please put this file to appropriate directory, and if you want
;; byte-compile it.  And add following lisp expressions to your
;; ~/.emacs.
;;
;;     (setq w3m-use-mule-ucs t)


;;; Code:
(require 'un-define)


(defun w3m-ucs-to-char (codepoint)
  (or (ucs-to-char codepoint) ?~))


(eval-and-compile
  (defconst w3m-ucs-generate-ncr-program
    `(;; (1) Convert a set of r1 (charset-id) and r0 (codepoint) to a
      ;; character in Emacs internal representation.
      (if (r0 > 255)
	  ((r4 = (r0 & 127))
	   (r0 = (((r0 >> 7) * 96) + r4))
	   (r0 |= (r1 << 16)))
	((r0 |= (r1 << 16))))
      ;; (2) Convert a character in Emacs to a UCS codepoint.
      (call emacs-char-to-ucs-codepoint-conversion)
     ;; (3) Generate a string which represents a UCS codepoint in NCR.
      (if (r0 <= 0)
	  (write ?~)			; unknown character.
	((r1 = 0)
	 (r2 = 0)
	 (loop
	  (r1 = (r1 << 4))
	  (r1 |= (r0 & 15))
	  (r0 = (r0 >> 4))
	  (if (r0 == 0)
	      (break)
	    ((r2 += 1)
	     (repeat))))
	 (write "&#x")
	 (loop
	  (branch (r1 & 15)
		  ,@(mapcar
		     (lambda (i)
		       (list 'write (string-to-char (format "%x" i))))
		     '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))
	  (r1 = (r1 >> 4))
	  (if (r2 == 0)
	      ((write ?\;)
	       (break))
	    ((r2 -= 1)
	     (repeat))))))
      (repeat))
    "CCL program to represents other characters in NCR
(Numeric Character References)."))


(define-ccl-program w3m-euc-japan-encoder
  `(4
    (loop
     (read-multibyte-character r1 r0)
     (if (r1 == ,(charset-id 'ascii))
	 ;; (1) ASCII characters
	 (write-repeat r0))
     (if (r1 == ,(charset-id 'latin-jisx0201))
	 ;; (2) Latin Part of Japanese JISX0201.1976
	 ;;     Convert to ASCII
	 (write-repeat r0))
     (r2 = (r1 == ,(charset-id 'japanese-jisx0208-1978)))
     (if ((r1 == ,(charset-id 'japanese-jisx0208)) | r2)
	 ;; (3) Characters of Japanese JISX0208.
	 ((r1 = ((r0 & 127) | 128))
	  (r0 = ((r0 >> 7) | 128))
	  (write r0)
	  (write-repeat r1)))
     (if (r1 == ,(charset-id 'katakana-jisx0201))
	 ;; (4) Katakana Part of Japanese JISX0201.1976
	 ((r0 |= 128)
	  (write ?\x8e)
	  (write-repeat r0)))
     ,@w3m-ucs-generate-ncr-program)))


(define-ccl-program w3m-iso-latin-1-encoder
  `(4
    (loop
     (read-multibyte-character r1 r0)
     (if (r1 == ,(charset-id 'ascii))
	 ;; (1) ASCII characters
	 (write-repeat r0))
     (if (r1 == ,(charset-id 'latin-jisx0201))
	 ;; (2) Latin Part of Japanese JISX0201.1976
	 ;;     Convert to ASCII
	 (write-repeat r0))
     (if (r1 == ,(charset-id 'latin-iso8859-1))
	 ;; (3) Latin-1 characters
	 ((r0 |= ?\x80)
	  (write-repeat r0)))
     ,@w3m-ucs-generate-ncr-program)))


(provide 'w3m-ucs)
;;; w3m-ucs.el ends here.
