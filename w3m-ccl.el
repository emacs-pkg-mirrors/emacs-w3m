;;; w3m-ccl.el --- CCL programs to process Unicode and internal characters.

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;          ARISAWA Akihiro <ari@mbf.sphere.ne.jp>
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

;; This file contains CCL programs to process Unicode and internal
;; characters of w3m.  For more detail about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/

;;; MEMO:

;; It is possible to support multi scripts without Mule-UCS.  For more
;; detail, see [emacs-w3m:01950]

;;; Code:

(require 'ccl)

;;; CCL programs:

(eval-and-compile
  (defconst w3m-internal-characters-alist
    '((?\x90 . ? )			; ANSP (use for empty anchor)
      (?\x91 . ? )			; IMSP (blank around image)
      (?\xa0 . ? ))			; NBSP (non breakble space)
    "Alist of internal characters v.s. ASCII characters.")

  (defun w3m-ccl-write-repeat (charset &optional r0 r1)
    (unless r0
      (setq r0 'r0))
    (unless r1
      (setq r1 (if (eq r0 'r1) 'r0 'r1)))
    (let* ((spec (cdr
		  (assq charset
			'((latin-iso8859-1 .   (nil . lc-ltn1))
			  (japanese-jisx0208 . (t   . lc-jp))
			  (japanese-jisx0212 . (t   . lc-jp2))
			  (katakana-jisx0201 . (nil . lc-kana))))))
	   (id (eval (if (boundp 'MULE)
			 (cdr spec)
		       '(charset-id charset)))))
      (if (fboundp 'ccl-compile-write-multibyte-character)
	  (` (((, r1) &= ?\x7f)
	      (,@ (when (car spec)
		    (` (((, r1) |= (((, r0) & ?\x7f) << 7))))))
	      ((, r0) = (, id))
	      (write-multibyte-character (, r0) (, r1))
	      (repeat)))
	(` ((write (, id))
	    (,@ (when (car spec)
		  (` ((write (, r0))))))
	    (write-repeat (, r1)))))))

  (defconst w3m-ccl-write-euc-japan-character
    `((read-multibyte-character r1 r0)
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
	   (write-repeat r0))))
    "CCL program to write characters represented in `euc-japan'.")

  (defconst w3m-ccl-write-iso-latin-1-character
    `((read-multibyte-character r1 r0)
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
	   (write-repeat r0))))
    "CCL program to write characters represented in `iso-latin-1'.")

  (defconst w3m-ccl-get-ucs-codepoint-with-mule-ucs
    '(;; (1) Convert a set of r1 (charset-id) and r0 (codepoint) to a
      ;; character in Emacs internal representation.
      (if (r0 > 255)
	  ((r4 = (r0 & 127))
	   (r0 = (((r0 >> 7) * 96) + r4))
	   (r0 |= (r1 << 16)))
	((r0 |= (r1 << 16))))
      ;; (2) Convert a character in Emacs to a UCS codepoint.
      (call emacs-char-to-ucs-codepoint-conversion)
      (if (r0 <= 0)
	  (r0 = #xfffd)))
    "CCL program to convert multibyte char to ucs with Mule-UCS.")

  (defconst w3m-ccl-get-ucs-codepoint-with-emacs-unicode
    `(,@(if (get 'utf-translation-table-for-encode 'translation-table-id)
	    '((translate-character utf-translation-table-for-encode r1 r0)))
	(if (r1 == ,(charset-id 'latin-iso8859-1))
	    ((r1 = (r0 + 128)))
	  (if (r1 == ,(charset-id 'mule-unicode-0100-24ff))
	      ((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
	       (r0 &= #x7f)
	       (r1 += (r0 + 224)))	; 224 == -32 + #x0100
	    (if (r1 == ,(charset-id 'mule-unicode-2500-33ff))
		((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
		 (r0 &= #x7f)
		 (r1 += (r0 + 9440)))	; 9440 == -32 + #x2500
	      (if (r1 == ,(charset-id 'mule-unicode-e000-ffff))
		  ((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
		   (r0 &= #x7f)
		   (r1 += (r0 + 57312)))	; 57312 == -32 + #xe000
		,(if (fboundp 'ccl-compile-lookup-character)
		     '((lookup-character utf-subst-table-for-encode r1 r0)
		       (if (r7 == 0)	; lookup failed
			   (r1 = #xfffd)))
		   '((r1 = #xfffd)))))))
	(r0 = r1))
    "CCL program to convert multibyte char to ucs with emacs-unicode.")

  (defconst w3m-ccl-generate-ncr
    `((if (r0 == #xfffd)
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
    "CCL program to generate a string which represents a UCS codepoint
in NCR (Numeric Character References)."))

(define-ccl-program w3m-euc-japan-decoder
  (` (2
      (loop
       (read r0)
       ;; Process normal EUC characters.
       (if (r0 < ?\x80)
	   (write-repeat r0))
       (if (r0 > ?\xa0)
	   ((read r1)
	    (,@ (w3m-ccl-write-repeat 'japanese-jisx0208))))
       (if (r0 == ?\x8e)
	   ((read r1)
	    (,@ (w3m-ccl-write-repeat 'katakana-jisx0201))))
       (if (r0 == ?\x8f)
	   ((read r0)
	    (read r1)
	    (,@ (w3m-ccl-write-repeat 'japanese-jisx0212))))
       ;; Process internal characters used in w3m.
       (,@ (mapcar (lambda (pair)
		     (` (if (r0 == (, (car pair)))
			    (write-repeat (, (cdr pair))))))
		   w3m-internal-characters-alist))
       (write-repeat r0)))))

(define-ccl-program w3m-euc-japan-encoder
  `(1
    (loop
     ,@w3m-ccl-write-euc-japan-character
     (write-repeat ?~))))

(define-ccl-program w3m-iso-latin-1-decoder
  (` (2
      (loop
       (read r0)
       ;; Process ASCII characters.
       (if (r0 < ?\x80)
	   (write-repeat r0))
       ;; Process Latin-1 characters.
       (if (r0 > ?\xa0)
	   ((,@ (w3m-ccl-write-repeat 'latin-iso8859-1 'r1))))
       ;; Process internal characters used in w3m.
       (,@ (mapcar (lambda (pair)
		     (` (if (r0 == (, (car pair)))
			    (write-repeat (, (cdr pair))))))
		   w3m-internal-characters-alist))
       (write-repeat r0)))))

(define-ccl-program w3m-iso-latin-1-encoder
  `(1
    (loop
     ,@w3m-ccl-write-iso-latin-1-character
     (write-repeat ?~))))

(provide 'w3m-ccl)

;;; w3m-ccl.el ends here
