;;; -*- mode: Emacs-Lisp; coding: euc-japan -*-

;; Copyright (C) 2000,2001 TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>,
;;          Shun-ichi GOTO     <gotoh@taiyo.co.jp>,
;;          Satoru Takabayashi <satoru-t@is.aist-nara.ac.jp>,
;;          Hideyuki SHIRAI    <shirai@meadowy.org>
;; Keywords: w3m, WWW, hypermedia

;; w3m.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; w3m.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with w3m.el; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


;;; Commentary:

;; w3m.el is the interface program of w3m on Emacs.  For more detail
;; about w3m, see:
;;
;;    http://ei5nazha.yz.yamagata-u.ac.jp/~aito/w3m/


;;; How to install:

;; Please put this file to appropriate directory, and if you want
;; byte-compile it.  And add following lisp expressions to your
;; ~/.emacs.
;;
;;     (autoload 'w3m "w3m" "Interface for w3m on Emacs." t)


;;; Code:

(or (and (boundp 'emacs-major-version)
	 (>= emacs-major-version 20))
    (progn
      (require 'poe)
      (require 'pcustom)))

(if (string-match "XEmacs" emacs-version)
    (require 'poem))

(put 'w3m-static-if 'lisp-indent-function 2)
(defmacro w3m-static-if (cond then &rest else)
  (if (eval cond) then (` (progn  (,@ else)))))

(defgroup w3m nil
  "w3m - the web browser of choice."
  :group 'hypermedia)

(defgroup w3m-face nil
  "Faces for w3m."
  :group 'w3m
  :prefix "w3m-")

(defcustom w3m-command "w3m"
  "*Name of the executable file of w3m."
  :group 'w3m
  :type 'string)

(defcustom w3m-fill-column (- (frame-width) 4)
  "*Fill column of w3m."
  :group 'w3m
  :type 'integer)

(defcustom w3m-command-arguments
  '("-T" "text/html" "-t" tab-width "-halfdump" "-cols" w3m-fill-column)
  "*Arguments of w3m."
  :group 'w3m
  :type '(repeat (restricted-sexp :match-alternatives (stringp boundp))))

(defcustom w3m-mailto-url-function nil
  "*Mailto handling Function."
  :group 'w3m
  :type 'function)

(defcustom w3m-coding-system
  (w3m-static-if (boundp 'MULE) '*euc-japan* 'euc-japan)
  "*Coding system for w3m."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-input-coding-system
  (w3m-static-if (boundp 'MULE) '*iso-2022-jp* 'iso-2022-jp)
  "*Coding system for w3m."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-output-coding-system
  (w3m-static-if (boundp 'MULE) '*euc-japan* 'euc-japan)
  "*Coding system for w3m."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-use-cygdrive t
  "*If non-nil, use /cygdrive/ rule when expand-file-name."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-profile-directory "~/.w3m"
  "*Directory of w3m profiles."
  :group 'w3m
  :type 'directory)

(defcustom w3m-default-save-directory "~/.w3m"
  "*Default directory for save file."
  :group 'w3m
  :type 'directory)

(defun w3m-expand-file-name (file &optional directory)
  (setq file (expand-file-name file directory))
  (if (string-match "^\\(.\\):\\(.*\\)" file)
      (if w3m-use-cygdrive
	  (concat "/cygdrive/" (match-string 1 file) (match-string 2 file))
	(concat "file://" (match-string 1 file) (match-string 2 file)))
    file))

(defcustom w3m-bookmark-file
  (w3m-expand-file-name "bookmark.html" w3m-profile-directory)
  "*Bookmark file of w3m."
  :group 'w3m
  :type 'file)

(defcustom w3m-bookmark-file-coding-system
  (w3m-static-if (boundp 'MULE) '*euc-japan* 'euc-japan)
  "*Coding system for bookmark file."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-home-page
  (or (getenv "HTTP_HOME")
      (getenv "WWW_HOME")
      (if (file-readable-p w3m-bookmark-file)
	  w3m-bookmark-file
	"http://www-nagao.kuee.kyoto-u.ac.jp/member/tsuchiya/"))
  "*Home page of w3m.el."
  :group 'w3m
  :type 'string)

(defcustom w3m-arrived-urls-file
  (w3m-expand-file-name ".arrived" w3m-profile-directory)
  "*Arrived URL file of w3m."
  :group 'w3m
  :type 'file)

(defcustom w3m-arrived-file-coding-system
  (w3m-static-if (boundp 'MULE) '*euc-japan*unix 'euc-japan-unix)
  "*Coding system for arrived file."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-keep-arrived-urls 500
  "*Arrived keep count of w3m."
  :group 'w3m
  :type 'integer)

(defcustom w3m-keep-backlog 300
  "*Back log size of w3m."
  :group 'w3m
  :type 'integer)

(defface w3m-anchor-face
  '((((class color) (background light)) (:foreground "red" :underline t))
    (((class color) (background dark)) (:foreground "blue" :underline t))
    (t (:underline t)))
  "*Face to fontify anchors."
  :group 'w3m-face)

(defface w3m-arrived-anchor-face
  '((((class color) (background light))
     (:foreground "navy" :underline t :bold t))
    (((class color) (background dark))
     (:foreground "blue" :underline t :bold t))
    (t (:underline t)))
  "*Face to fontify anchors, if arrived."
  :group 'w3m-face)

(defface w3m-image-face
  '((((class color) (background light)) (:foreground "ForestGreen"))
    (((class color) (background dark)) (:foreground "PaleGreen"))
    (t (:underline t)))
  "*Face to fontify image alternate strings."
  :group 'w3m-face)

(defcustom w3m-hook nil
  "*Hook run before w3m called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-mode-hook nil
  "*Hook run before w3m-mode called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-fontify-before-hook nil
  "*Hook run before w3m-fontify called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-fontify-after-hook nil
  "*Hook run after w3m-fontify called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-async-exec nil
  "*If non-nil, w3m is executed an asynchronously process."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-process-connection-type t
  "*Process connection type for w3m execution."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-executable-type
  (if (memq window-system '(w32 win32))
      'cygwin ; xxx, cygwin on win32 by default
    'native)
  "*Executable binary type of w3m program.
Value is 'native or 'cygwin.
This value is maily used for win32 environment.
In other environment, use 'native."
  :group 'w3m
  :type '(choice (const cygwin) (const native)))

;; FIXME: ������ mailcap ��Ŭ�ڤ��ɤ߹�������ꤹ��ɬ�פ�����
(defcustom w3m-content-type-alist
  '(("text/plain" "\\.\\(txt\\|tex\\|el\\)" nil)
    ("text/html" "\\.s?html?$" ("netscape" url))
    ("application/image" "\\.jpg$" ("xv" file))
    ("application/postscript" "\\.\\(ps\\|eps\\|pdf\\)$" ("gv" file)))
  "Alist of file suffixes vs. content type."
  :group 'w3m
  :type '(repeat
	  (list
	   (string :tag "Type")
	   (string :tag "Regexp")
	   (choice
	    (const :tag "None" nil)
	    (cons :tag "Externai viewer"
		  (string :tag "Command")
		  (repeat :tag "Arguments"
			  (restricted-sexp :match-alternatives
					   (stringp 'file 'url))))
	    (function :tag "Function")))))

(defcustom w3m-charset-coding-system-alist
  (let ((rest
	 '((us-ascii      . raw-text)
	   (gb2312	  . cn-gb-2312)
	   (cn-gb	  . cn-gb-2312)
	   (iso-2022-jp-2 . iso-2022-7bit-ss2)
	   (iso-2022-jp-3 . iso-2022-7bit-ss2)
	   (tis-620	  . tis620)
	   (windows-874	  . tis-620)
	   (cp874	  . tis-620)
	   (x-ctext       . ctext)
	   (unknown       . undecided)
	   (x-unknown     . undecided)
	   (euc-jp        . euc-japan)
	   (shift-jis     . shift_jis)
	   (shift_jis     . shift_jis)
	   (sjis          . shift_jis)
	   (x-euc-jp      . euc-japan)
	   (x-shift-jis   . shift_jis)
	   (x-shift_jis   . shift_jis)
	   (x-sjis        . shift_jis)))
	dest)
    (while rest
      (let ((pair (car rest)))
	(or (find-coding-system (car pair))
	    (setq dest (cons pair dest))))
      (setq rest (cdr rest)))
    dest)
  "Alist MIME CHARSET vs CODING-SYSTEM.
MIME CHARSET and CODING-SYSTEM must be symbol."
  :group 'w3m
  :type '(repeat (cons symbol coding-system)))

(defconst w3m-extended-charcters-table
  '(("\xa0" . " ")))
  
(defvar w3m-current-url nil "URL of this buffer.")
(defvar w3m-current-title nil "Title of this buffer.")
(defvar w3m-url-history nil "History of URL.")

(defvar w3m-backlog-buffer nil)
(defvar w3m-backlog-articles nil)
(defvar w3m-backlog-hashtb nil)
(defvar w3m-input-url-history nil)

(defvar w3m-arrived-anchor-list nil)
(defvar w3m-arrived-user-list nil)

(defvar w3m-process-url nil)
(defvar w3m-process-user nil)
(defvar w3m-process-passwd nil)
(defvar w3m-process-user-counter 0)

(defvar w3m-bookmark-data nil)
(defvar w3m-bookmark-file-time-stamp nil)
(defvar w3m-bookmark-section-history nil)
(defvar w3m-bookmark-title-history nil)

(defconst w3m-work-buffer-name " *w3m-work*")

(defconst w3m-meta-content-type-charset-regexp
  (eval-when-compile
    (concat "<meta[ \t]+http-equiv=\"?Content-type\"?[ \t]+content=\"\\([^;]+\\)"
	    ";[ \t]*charset=\"?\\([^\"]+\\)\"?"
	    ">"))
  "Regexp used in parsing `<META HTTP-EQUIV=\"Content-Type\" content=\"...;charset=...\">
for a charset indication")

(defconst w3m-meta-charset-content-type-regexp
  (eval-when-compile
    (concat "<meta[ \t]+content=\"\\([^;]+\\)"
	    ";[ \t]*charset=\"?\\([^\"]+\\)\"?"
	    "[ \t]+http-equiv=\"?Content-type\"?>"))
  "Regexp used in parsing `<META content=\"...;charset=...\" HTTP-EQUIV=\"Content-Type\">
for a charset indication")


(defun w3m-sub-list (list n)
  "Make new list from LIST with top most N items.
If N is negative, last N items of LIST is returned."
  (if (< n 0)
      ;; N is negative, get items from tail of list
      (nthcdr (+ (length list) n) (copy-sequence list))
    ;; N is non-negative, get items from top of list
    (nreverse (nthcdr (- (length list) n) (reverse list)))))

(defun w3m-load-list (file coding)
  "Load list from FILE with CODING and return list."
  (when (file-readable-p file)
    (with-temp-buffer
      (let ((file-coding-system-for-read coding)
	    (coding-system-for-read coding))
	(insert-file-contents file)
	(condition-case nil
	    (read (current-buffer))	; return value
	  (error nil))))))

(defun w3m-save-list (file coding list)
  "Save LIST into file with CODING."
  (when (and list (file-writable-p file))
    (with-temp-buffer
      (let ((file-coding-system coding)
	    (coding-system-for-write coding))
	(print list (current-buffer))
	(write-region (point-min) (point-max)
		      file nil 'nomsg)))))

(defun w3m-arrived-list-load ()
  "Load arrived url list from 'w3m-arrived-urls-file'."
  (setq w3m-arrived-anchor-list
	(w3m-load-list w3m-arrived-urls-file w3m-arrived-file-coding-system)))

(defun w3m-arrived-list-save ()
  "Save arrived url list to 'w3m-arrived-urls-file'."
  (w3m-save-list w3m-arrived-urls-file w3m-arrived-file-coding-system
		 (w3m-sub-list w3m-arrived-anchor-list w3m-keep-arrived-urls)))

(defun w3m-arrived-list-add (&optional url)
  "Cons url to 'w3m-arrived-anchor-list'. CAR is newest."
  (setq url (or url w3m-current-url))
  (when (> (length url) 5) ;; ignore short
    (set-text-properties 0 (length url) nil url)
    (setq w3m-arrived-anchor-list
	  (cons url (delete url w3m-arrived-anchor-list)))))

(defun w3m-fontify ()
  "Fontify this buffer."
  (let ((case-fold-search t)
	(buffer-read-only))
    (run-hooks 'w3m-fontify-before-hook)
    ;; Delete <?xml ... ?> tag
    (if (search-forward "<?xml" nil t)
	(let ((start (match-beginning 0)))
	  (search-forward "?>" nil t)
	  (delete-region start (match-end 0))))
    ;; Delete extra title tag.
    (goto-char (point-min))
    (let (start)
      (and (search-forward "<title>" nil t)
	   (setq start (match-beginning 0))
	   (search-forward "</title>" nil t)
	   (delete-region start (match-end 0))))
    ;; Fontify bold characters.
    (goto-char (point-min))
    (while (search-forward "<b>" nil t)
      (let ((start (match-beginning 0)))
	(delete-region start (match-end 0))
	(when (search-forward "</b>" nil t)
	  (delete-region (match-beginning 0) (match-end 0))
	  (put-text-property start (match-beginning 0) 'face 'bold))))
    ;; Delete excessive `hseq' elements of anchor tags.
    (goto-char (point-min))
    (while (re-search-forward "<a\\( hseq=\"[-0-9]+\"\\)" nil t)
      (delete-region (match-beginning 1) (match-end 1)))
    ;; Re-ordering anchor elements.
    (goto-char (point-min))
    (let (href)
      (while (re-search-forward "<a\\([ \t\n]\\)[^>]+[ \t\n]href=\\(\"[^\"]*\"\\)" nil t)
	(setq href (buffer-substring (match-beginning 2) (match-end 2)))
	(delete-region (match-beginning 2) (match-end 2))
	(goto-char (match-beginning 1))
	(insert " href=" href)))
    ;; Fontify anchor tags.
    (goto-char (point-min))
    (while (re-search-forward
	    "<a\\([ \t\n]+href=\"\\([^\"]*\\)\"\\)?\\([ \t\n]+name=\"\\([^\"]*\\)\"\\)?[^>]*>"
	    nil t)
      (let ((url (match-string 2))
	    (tag (match-string 4))
	    (start (match-beginning 0))
	    (end))
	(delete-region start (match-end 0))
	(cond (url
	       (when (search-forward "</a>" nil t)
		 (delete-region (setq end (match-beginning 0)) (match-end 0))
		 (if (member (w3m-expand-url url w3m-current-url)
			     w3m-arrived-anchor-list)
		     (put-text-property start end 'face 'w3m-arrived-anchor-face)
		   (put-text-property start end 'face 'w3m-anchor-face))
		 (put-text-property start end 'w3m-href-anchor url)
		 (put-text-property start end 'mouse-face 'highlight))
	       (when tag
		 (put-text-property start end 'w3m-name-anchor tag)))
	      (tag
	       (when (re-search-forward "<\\|\n" nil t)
		 (setq end (match-beginning 0))
		 (put-text-property start end 'w3m-name-anchor tag))))))
    ;; Fontify image alternate strings.
    (goto-char (point-min))
    (while (re-search-forward "<img_alt src=\"\\([^\"]*\\)\">" nil t)
      (let ((src (match-string 1))
	    (start (match-beginning 0))
	    (end))
	(delete-region start (match-end 0))
	(when (search-forward "</img_alt>" nil t)
	  (delete-region (setq end (match-beginning 0)) (match-end 0))
	  (put-text-property start end 'face 'w3m-image-face)
	  (put-text-property start end 'w3m-image src)
	  (put-text-property start end 'mouse-face 'highlight))))
    ;; Remove other markups.
    (goto-char (point-min))
    (while (re-search-forward "</?[A-z][^>]*>" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    ;; Decode escaped characters.
    (goto-char (point-min))
    (let (prop)
      (while (re-search-forward
	      "&\\(\\(nbsp\\)\\|\\(gt\\)\\|\\(lt\\)\\|\\(amp\\)\\|\\(quot\\)\\|\\(apos\\)\\);"
	      nil t)
	(setq prop (text-properties-at (match-beginning 0)))
	(delete-region (match-beginning 0) (match-end 0))
	(insert (if (match-beginning 2) " "
		  (if (match-beginning 3) ">"
		    (if (match-beginning 4) "<"
		      (if (match-beginning 5) "&"
			(if (match-beginning 6) "\"" "'"))))))
	(if prop (add-text-properties (1- (point)) (point) prop))))
    ;; Decode w3m-specific extended charcters.
    (goto-char (point-min))
    (let ((x enable-multibyte-characters)
	  (table w3m-extended-charcters-table))
      (set-buffer-multibyte nil)
      (while table
	(while (search-forward (car (car table)) nil t)
	  (delete-region (match-beginning 0) (match-end 0))
	  (insert (cdr (car table))))
	(setq table (cdr table)))
      (set-buffer-multibyte x))
    (run-hooks 'w3m-fontify-after-hook)))

(defun w3m-refontify-anchor (&optional buff)
  "Change face 'w3m-anchor-face to 'w3m-arrived-anchor-face."
  (save-excursion
    (and buff (set-buffer buff))
    (when (and (eq major-mode 'w3m-mode)
	       (eq (get-text-property (point) 'face) 'w3m-anchor-face))
      (let* ((start)
	     (end (next-single-property-change (point) 'face))
	     (buffer-read-only))
	(when (and end
		   (setq start (previous-single-property-change end 'face)))
	  (put-text-property start end 'face 'w3m-arrived-anchor-face))
	(set-buffer-modified-p nil)))))

(defun w3m-input-url (&optional prompt default)
  "Read a URL from the minibuffer, prompting with string PROMPT."
  (let (url candidates)
    (w3m-backlog-setup)
    (or w3m-input-url-history
	(setq w3m-input-url-history (or w3m-arrived-anchor-list
					(w3m-arrived-list-load))))
    (mapatoms (lambda (x)
		(setq candidates (cons (cons (symbol-name x) x) candidates)))
	      w3m-backlog-hashtb)
    (setq url (completing-read (or prompt "URL: ")
			       candidates nil nil
			       default 'w3m-input-url-history))
    ;; remove duplication
    (setq w3m-input-url-history (cons url (delete url w3m-input-url-history)))
    ;; return value
    url))


;;; Backlog:
(defun w3m-backlog-setup ()
  "Initialize backlog variables."
  (unless (and (bufferp w3m-backlog-buffer)
	       (buffer-live-p w3m-backlog-buffer))
    (save-excursion
      (set-buffer (get-buffer-create " *w3m backlog*"))
      (buffer-disable-undo)
      (setq buffer-read-only t
	    w3m-backlog-buffer (current-buffer))))
  (unless w3m-backlog-hashtb
    (setq w3m-backlog-hashtb (make-vector 1021 0))))

(defun w3m-backlog-shutdown ()
  "Clear all backlog variables and buffers."
  (when (get-buffer w3m-backlog-buffer)
    (kill-buffer w3m-backlog-buffer))
  (setq w3m-backlog-hashtb nil
	w3m-backlog-articles nil))

(defun w3m-backlog-enter (url buffer)
  (w3m-backlog-setup)
  (let ((ident (intern url w3m-backlog-hashtb)))
    (unless (memq ident w3m-backlog-articles)
      ;; Remove the oldest article, if necessary.
      (and (numberp w3m-keep-backlog)
	   (>= (length w3m-backlog-articles) w3m-keep-backlog)
	   (w3m-backlog-remove-oldest))
      ;; Insert the new article.
      (save-excursion
	(set-buffer w3m-backlog-buffer)
	(let (buffer-read-only)
	  (goto-char (point-max))
	  (unless (bolp) (insert "\n"))
	  (let ((b (point)))
	    (insert-buffer-substring buffer)
	    ;; Tag the beginning of the article with the ident.
	    (when (> (point-max) b)
	      (put-text-property b (1+ b) 'w3m-backlog ident)
	      (put-text-property b (1+ b) 'w3m-backlog-title
				 (save-current-buffer
				   (set-buffer buffer)
				   w3m-current-title))
	      (setq w3m-backlog-articles (cons ident w3m-backlog-articles)))
	    ))))))

(defun w3m-backlog-remove-oldest ()
  (save-excursion
    (set-buffer w3m-backlog-buffer)
    (goto-char (point-min))
    (if (zerop (buffer-size))
	()				; The buffer is empty.
      (let ((ident (get-text-property (point) 'w3m-backlog))
	    buffer-read-only)
	;; Remove the ident from the list of articles.
	(when ident
	  (setq w3m-backlog-articles (delq ident w3m-backlog-articles)))
	;; Delete the article itself.
	(delete-region (point)
		       (next-single-property-change
			(1+ (point)) 'w3m-backlog nil (point-max)))))))

(defun w3m-backlog-remove (url)
  "Remove data of URL from the backlog."
  (w3m-backlog-setup)
  (let ((ident (intern url w3m-backlog-hashtb))
	beg end)
    (when (memq ident w3m-backlog-articles)
      ;; It was in the backlog.
      (save-excursion
	(set-buffer w3m-backlog-buffer)
	(let (buffer-read-only)
	  (when (setq beg (text-property-any
			   (point-min) (point-max) 'w3m-backlog ident))
	    ;; Find the end (i. e., the beginning of the next article).
	    (setq end (next-single-property-change
		       (1+ beg) 'w3m-backlog (current-buffer) (point-max)))
	    (delete-region beg end)))
	(setq w3m-backlog-articles (delq ident w3m-backlog-articles))))))

(defun w3m-backlog-request (url &optional buffer)
  (w3m-backlog-setup)
  (let ((ident (intern url w3m-backlog-hashtb)))
    (when (memq ident w3m-backlog-articles)
      ;; It was in the backlog.
      (let (beg end title)
	(save-excursion
	  (set-buffer w3m-backlog-buffer)
	  (if (setq beg (text-property-any
			 (point-min) (point-max) 'w3m-backlog ident))
	      ;; Find the end (i. e., the beginning of the next article).
	      (setq title (get-text-property beg 'w3m-backlog-title)
		    end (next-single-property-change
			 (1+ beg) 'w3m-backlog (current-buffer) (point-max)))
	    ;; It wasn't in the backlog after all.
	    (setq w3m-backlog-articles (delq ident w3m-backlog-articles))))
	(and beg
	     end
	     (save-excursion
	       (and buffer (set-buffer buffer))
	       (let (buffer-read-only)
		 (insert-buffer-substring w3m-backlog-buffer beg end))
	       (set (make-local-variable 'w3m-current-title) title)
	       (set (make-local-variable 'w3m-current-url) url)))))))


;;; Handle process:
(defun w3m-exec-process (&rest args)
  (save-excursion
    (let ((coding-system-for-read
	   (w3m-static-if (boundp 'MULE) '*noconv* 'binary))
	  (coding-system-for-write w3m-coding-system)
	  (default-process-coding-system
	    (cons (w3m-static-if (boundp 'MULE) '*noconv* 'binary)
		  w3m-coding-system))
	  (process-connection-type w3m-process-connection-type))
      (if w3m-async-exec
	  ;; start-process
	  (let ((w3m-process-user)
		(w3m-process-passwd)
		(w3m-process-user-counter 2)
		(proc (apply 'start-process w3m-command (current-buffer) w3m-command args)))
	    (set-process-filter proc 'w3m-exec-filter)
	    (set-process-sentinel proc (lambda (proc event) nil))
	    (process-kill-without-query proc)
	    (while (eq (process-status proc) 'run)
	      (sit-for 0.2)
	      (discard-input))
	    (and w3m-current-url
		 w3m-process-user
		 (setq w3m-arrived-user-list
		       (cons
			(cons w3m-current-url
			      (list w3m-process-user w3m-process-passwd))
			(delete (assoc w3m-current-url w3m-arrived-user-list)
				w3m-arrived-user-list)))))
	;; call-process
	(apply 'call-process w3m-command nil t nil args)))))

(defun w3m-exec-get-user (url)
  (if (= w3m-process-user-counter 0)
      nil
    (let ((urllist w3m-arrived-user-list))
      (catch 'get
	(while urllist
	  (when (string-match (concat "^"
				      (regexp-quote (car (car urllist))))
			      url)
	    (setq w3m-process-user-counter (1- w3m-process-user-counter))
	    (throw 'get (cdr (car urllist))))
	  (setq urllist (cdr urllist)))))))

(defun w3m-read-file-name (&optional prompt dir default existing initial)
  (let* ((default (and default (file-name-nondirectory default)))
	 (prompt (or prompt
		     (if default (format "Save to (%s): " default) "Save to: ")))
	 (initial (or initial default))
	 (dir (file-name-as-directory (or dir w3m-default-save-directory)))
	 (default-directory dir)
	 (file (read-file-name prompt dir default existing initial)))
    (if (not (file-directory-p file))
	(setq w3m-default-save-directory
	      (or (file-name-directory file) w3m-default-save-directory))
      (setq w3m-default-save-directory file)
      (if default
	  (setq file (expand-file-name default file))))
    (expand-file-name file)))

(defun w3m-read-passwd (prompt)
  (let ((inhibit-input-event-recording t))
    (if (fboundp 'read-passwd)
	(condition-case nil
	    (read-passwd prompt)
	  (error ""))
      (let ((pass "")
	    (c 0)
	    (echo-keystrokes 0)
	    (ociea cursor-in-echo-area))
	(condition-case nil
	    (progn
	      (setq cursor-in-echo-area 1)
	      (while (and (/= c ?\r) (/= c ?\n) (/= c ?\e) (/= c 7)) ;; ^G
		(message "%s%s"
			 prompt
			 (make-string (length pass) ?.))
		(setq c (read-char-exclusive))
		(cond
		 ((char-equal c ?\C-u)
		  (setq pass ""))
		 ((or (char-equal c ?\b) (char-equal c ?\177))  ;; BS DELL
		  ;; delete one character in the end
		  (if (not (equal pass ""))
		      (setq pass (substring pass 0 -1))))
		 ((< c 32) ()) ;; control, just ignore
		 (t
		  (setq pass (concat pass (char-to-string c))))))
	      (setq cursor-in-echo-area -1))
	  (quit
	   (setq cursor-in-echo-area ociea)
	   (signal 'quit nil))
	  (error
	   ;; Probably not happen. Just align to the code above.
	   (setq pass "")))
	(setq cursor-in-echo-area ociea)
	(message "")
	(sit-for 0)
	pass))))

(defun w3m-exec-filter (process string)
  (if (buffer-name (process-buffer process))
      (with-current-buffer (process-buffer process)
	(let ((buffer-read-only nil)
	      (case-fold-search nil)
	      (mark (process-mark process))
	      (str))
	  (goto-char mark)
	  (insert string)
	  (set-marker mark (point))
	  (forward-line 0)
	  (cond
	   ((looking-at "Username: Password: ")
	    (setq w3m-process-passwd
		  (or (nth 1 (w3m-exec-get-user w3m-current-url))
		      (w3m-read-passwd (match-string 0)))
		  str w3m-process-passwd))
	   ((looking-at "Username: ")
	    (setq w3m-process-user
		  (or (nth 0 (w3m-exec-get-user w3m-current-url))
		      (read-from-minibuffer (match-string 0)))
		  str w3m-process-user)))
	  (if str
	      (process-send-string process (concat str "\n")))))))


;;; Handle character sets:
(defun w3m-charset-to-coding-system (charset)
  "Return coding-system corresponding with CHARSET.
CHARSET is a symbol whose name is MIME charset.
This function is imported from mcharset.el."
  (if (stringp charset)
      (setq charset (intern (downcase charset))))
  (let ((cs (assq charset w3m-charset-coding-system-alist)))
    (setq cs (if cs (cdr cs) charset))
    (if (find-coding-system cs)
	cs)))

(defun w3m-decode-buffer (type charset)
  (unless charset
    (setq charset
	  (let ((case-fold-search t))
	    (goto-char (point-min))
	    (and (string= type "text/html")
		 (or (re-search-forward
		      w3m-meta-content-type-charset-regexp nil t)
		     (re-search-forward
		      w3m-meta-charset-content-type-regexp nil t))
		 (buffer-substring-no-properties (match-beginning 2)
						 (match-end 2))))))
  (decode-coding-region
   (point-min) (point-max)
   (if charset
       (w3m-charset-to-coding-system charset)
     (let ((default (condition-case nil
			(coding-system-category w3m-coding-system)
		      (error nil)))
	   (candidate (detect-coding-region (point-min) (point-max))))
       (unless (listp candidate)
	 (setq candidate (list candidate)))
       (catch 'coding
	 (dolist (coding candidate)
	   (if (eq default (coding-system-category coding))
	       (throw 'coding coding)))
	 (if (eq (coding-system-category 'binary)
		 (coding-system-category (car candidate)))
	     w3m-coding-system
	   (car candidate))))))
  (set-buffer-multibyte t))


;;; Retrieve local data:
(defun w3m-local-content-type (url)
  (let ((alist w3m-content-type-alist))
    (catch 'type-detected
      (while alist
	(if (string-match (nth 1 (car alist)) url)
	    (throw 'type-detected (car (car alist))))
	(setq alist (cdr alist)))
      "unknown")))

(defun w3m-local-retrieve (url &optional no-decode)
  (let ((type (w3m-local-content-type url)))
    (if (string-match "file:" url)
	(setq url (substring url (match-end 0))))
    (with-current-buffer (get-buffer-create w3m-work-buffer-name)
      (delete-region (point-min) (point-max))
      (if (and (string-match "^text/" type)
	       (not no-decode))
	  (progn
	    (set-buffer-multibyte t)
	    (insert-file-contents url))
	(set-buffer-multibyte nil)
	(let ((coding-system-for-read
	       (w3m-static-if (boundp 'MULE) '*noconv* 'binary))
	      (file-coding-system-for-read
	       (w3m-static-if (boundp 'MULE) '*noconv* 'binary)))
	  (insert-file-contents url)))
      type)))


;;; Retrieve data via HTTP:
(defun w3m-remove-redundant-spaces (str)
  "Remove spaces/tabs at the front of a string and at the end of a string"
  (save-match-data
    (if (string-match "^[ \t\r\f\n]+" str)
	(setq str (substring str (match-end 0))))
    (if (string-match "[ \t\r\f\n]+$" str)
	(setq str (substring str 0 (match-beginning 0)))))
  str)

(defun w3m-http-check-header (url)
  "Ask the header of the URL to HTTP server."
  (with-current-buffer (get-buffer-create w3m-work-buffer-name)
    (delete-region (point-min) (point-max))
    (let ((w3m-current-url url)
	  (case-fold-search t)
	  length type charset)
      (w3m-exec-process "-dump_head" url)
      (goto-char (point-min))
      (if (re-search-forward "^content-type:\\([^\r\n]+\\)\r*$" nil t)
	  (progn
	    (setq type (match-string 1))
	    (if (string-match ";[ \t]*charset=" type)
		(setq charset (w3m-remove-redundant-spaces
			       (substring type (match-end 0)))
		      type (w3m-remove-redundant-spaces
			    (substring type 0 (match-beginning 0))))
	      (setq type (w3m-remove-redundant-spaces type)))))
      (goto-char (point-min))
      (if (re-search-forward "^content-length:\\([^\r\n]+\\)\r*$" nil t)
	  (setq length (string-to-number (match-string 1))))
      (list (or type (w3m-local-content-type url) "unknown")
	    charset
	    length))))

(defun w3m-http-retrieve (url &optional no-decode)
  (let* ((headers (w3m-http-check-header url))
	 (type    (car headers))
	 (charset (nth 1 headers))
	 (length  (nth 2 headers)))
    (with-current-buffer (get-buffer-create w3m-work-buffer-name)
      (delete-region (point-min) (point-max))
      (set-buffer-multibyte nil)
      (let ((w3m-current-url url))
	(w3m-exec-process "-dump_source" url))
      (if length
	  (if (eq w3m-executable-type 'cygwin)
	      (cond
	       ;; No authentication and no bugs in output.
	       ((= (buffer-size) length))
	       ;; No authentication but new-line character is replaced to CRLF.
	       ((= (buffer-size)
		   (+ length (count-lines (point-min) (point-max))))
		(while (search-forward "\r\n" nil t)
		  (delete-region (- (point) 2) (1- (point)))))
	       (t ;; Authentication
		(while (and
			(re-search-forward "^Username: Password: \n" nil t)
			(cond
			 ((= (- (point-max) (point)) length)
			  (delete-region (point-min) (point))
			  nil)
			 ((= (- (point-max) (point))
			     (+ length (count-lines (point) (point-max))))
			  (delete-region (point-min) (point))
			  (while (search-forward "\r\n" nil t)
			    (delete-region (- (point) 2) (1- (point))))))))))
	    (delete-region (point-min) (- (point-max) length))))
      (and (string-match "^text/" type)
	   (not no-decode)
	   (w3m-decode-buffer type charset))
      type)))

(defun w3m-retrieve (url &optional no-decode)
  (if (string-match "^\\(file:\\|/\\)" url)
      (w3m-local-retrieve url no-decode)
    (w3m-http-retrieve url no-decode)))

(defun w3m-download (url &optional filename)
  (unless filename
    (setq filename (w3m-read-file-name)))
  (w3m-retrieve url t)
  (with-current-buffer (get-buffer w3m-work-buffer-name)
    (let ((buffer-file-coding-system
	   (w3m-static-if (boundp 'MULE) '*noconv* 'binary))
	  (coding-system-for-write
	   (w3m-static-if (boundp 'MULE) '*noconv* 'binary)))
      (write-region (point-min) (poinat-max) filename nil nil t))))

(defun w3m-content-type (url)
  (if (string-match "^\\(file:\\|/\\)" url)
      (w3m-local-content-type url)
    (car (w3m-http-check-header url))))


;;; Retrieve data via FTP:
(defun w3m-exec-ftp (url)
  (let ((ftp (w3m-convert-ftp-to-emacsen url))
	(file (file-name-nondirectory url)))
    (if (string-match "\\(\\.gz\\|\\.bz2\\|\\.zip\\|\\.lzh\\)$" file)
	(copy-file ftp (w3m-read-file-name nil nil file))
      (dired-other-window ftp))))

(defun w3m-convert-ftp-to-emacsen (url)
  (or (and (string-match "^ftp://?\\([^/@]+@\\)?\\([^/]+\\)\\(/~/\\)?" url)
	   (concat "/"
		   (if (match-beginning 1)
		       (substring url (match-beginning 1) (match-end 1))
		     "anonymous@")
		   (substring url (match-beginning 2) (match-end 2))
		   ":"
		   (substring url (match-end 2))))
      (error "URL is strange.")))

(defun w3m-rendering-region (start end)
  "Rendering data in current buffer as HTML."
  (let ((coding-system-for-read w3m-output-coding-system)
	(coding-system-for-write w3m-input-coding-system)
	(default-process-coding-system
	  (cons w3m-output-coding-system w3m-input-coding-system)))
    (apply 'call-process-region
	   start end w3m-command t t nil
	   (mapcar (lambda (x)
		     (if (stringp x)
			 x
		       (prin1-to-string (eval x))))
		   w3m-command-arguments))
    (goto-char (point-min))
    (let (title)
      (mapcar (lambda (regexp)
		(goto-char 1)
		(when (re-search-forward regexp nil t)
		  (setq title (match-string 1))
		  (delete-region (match-beginning 0) (match-end 0))))
	      '("<title_alt[ \t\n]+title=\"\\([^\"]+\\)\">"
		"<title>\\([^<]\\)</title>"))
      (if (and (null title)
	       (< 0 (length (file-name-nondirectory url))))
	  (setq title (file-name-nondirectory url)))
      (set (make-local-variable 'w3m-current-title) (or title "<no-title>")))))

(defun w3m-exec (url &optional buffer)
  "Download URL with w3m to the BUFFER.
If BUFFER is nil, all data is placed to the current buffer."
  (save-excursion
    (if buffer (set-buffer buffer))
    (if (and (string-match "^ftp://" url)
	     (not (string= "text/html" (w3m-local-content-type url))))
	(progn (w3m-exec-ftp url) t)
      ;; backlog exist.
      (let (buffer-read-only)
	(delete-region (point-min) (point-max))
	(or (w3m-backlog-request url)
	    (let ((type (w3m-retrieve url)))
	      (when (string-match "^text/" type)
		(insert-buffer w3m-work-buffer-name)
		(set (make-local-variable 'w3m-current-url) url)
		(if (string= "text/html" type)
		    (w3m-rendering-region (point-min) (point-max))
		  (set (make-local-variable 'w3m-current-title)
		       (file-name-nondirectory url)))
		(w3m-backlog-enter url (current-buffer)))))
	(set (make-local-variable 'w3m-url-history)
	     (cons url w3m-url-history))
	(setq-default w3m-url-history
		      (cons url (default-value 'w3m-url-history)))
	nil))))


(defun w3m-search-name-anchor (name &optional quiet)
  (interactive "sName: ")
  (let ((pos (point-min)))
    (catch 'found
      (while (setq pos (next-single-property-change pos 'w3m-name-anchor))
	(when (equal name (get-text-property pos 'w3m-name-anchor))
	  (goto-char pos)
	  (throw 'found t))
	(setq pos (next-single-property-change pos 'w3m-name-anchor)))
      (unless quiet
	(message "Not found such name anchor."))
      nil)))


(defun w3m-save-position (url)
  (if url
      (let ((ident (intern-soft url w3m-backlog-hashtb)))
	(when ident
	  (set ident (cons (window-start) (point)))))))

(defun w3m-restore-position (url)
  (let ((ident (intern-soft url w3m-backlog-hashtb)))
    (when (and ident (boundp ident))
      (set-window-start nil (car (symbol-value ident)))
      (goto-char (cdr (symbol-value ident))))))


(defun w3m-view-previous-page (&optional arg)
  (interactive "p")
  (unless arg (setq arg 1))
  (let ((url (nth arg w3m-url-history)))
    (when url
      (let (w3m-url-history) (w3m-goto-url url))
      ;; restore last position
      (w3m-restore-position url)
      (setq w3m-url-history
	    (nthcdr arg w3m-url-history)))))

(defun w3m-view-previous-point ()
  (interactive)
  (w3m-restore-position w3m-current-url))

(defun w3m-expand-url (url base)
  "Convert URL to absolute, and canonicalize it."
  (if (not base) (setq base ""))
  (if (string-match "^[^:]+://[^/]*$" base)
      (setq base (concat base "/")))
  (cond
   ;; URL is relative on BASE.
   ((string-match "^#" url)
    (concat base url))
   ;; URL has absolute spec.
   ((string-match "^[^:]+:" url)
    url)
   ((string-match "^/" url)
    (if (string-match "^\\([^:]+://[^/]*\\)/" base)
	(concat (match-string 1 base) url)
      url))
   (t
    (let ((server "") path)
      (if (string-match "^\\([^:]+://[^/]*\\)/" base)
	  (setq server (match-string 1 base)
		base (substring base (match-end 1))))
      (setq path (expand-file-name url (file-name-directory base)))
      ;; remove drive (for Win32 platform)
      (if (string-match "^.:" path)
	  (setq path (substring path (match-end 0))))
      (concat server path)))))


(defun w3m-view-this-url (&optional arg)
  "*View the URL of the link under point."
  (interactive "P")
  (let ((url (get-text-property (point) 'w3m-href-anchor)))
    (if url (w3m-goto-url (w3m-expand-url url w3m-current-url) arg))))

(defun w3m-mouse-view-this-url (event)
  (interactive "e")
  (mouse-set-point event)
  (let ((url (get-text-property (point) 'w3m-href-anchor))
	(img (get-text-property (point) 'w3m-image)))
    (cond
     (url (w3m-view-this-url))
     (img (w3m-view-image))
     (t (message "No URL at point.")))))

(defun w3m-external-view (content-type url)
  (let ((method (nth 2 (assoc content-type w3m-content-type-alist))))
    (if method
	(cond
	 ((not method)
	  (message "No external viewer is defined."))
	 ((functionp method)
	  (funcall method url))
	 ((consp method)
	  (let ((command (car method))
		(arguments (cdr method))
		(file (make-temp-name
		       (expand-file-name "w3mel" w3m-profile-directory)))
		(proc))
	    (unwind-protect
		(with-current-buffer
		    (generate-new-buffer " *w3m-external-view*")
		  (if (memq 'file arguments) (w3m-download url file))
		  (setq proc
			(apply 'start-process
			       "w3m-external-view"
			       (current-buffer)
			       command
			       (mapcar (function eval) arguments)))
		  (set (make-local-variable 'w3m-tmp-file) file)
		  (set-process-sentinel
		   proc
		   (lambda (proc event)
		     (and (string-match "^\\(finished\\|exited\\)" event)
			  (buffer-name (process-buffer proc))
			  (save-excursion
			    (set-buffer (process-buffer proc))
			    (if (file-exists-p w3m-tmp-file)
				(delete-file w3m-tmp-file)))
			  (kill-buffer (process-buffer proc))))))
	      (if (file-exists-p file)
		  (unless (and (processp proc) (process-status proc 'run))
		    (delete-file file)))))))
      (error "Unknown content type: %s" content-type))))

(defun w3m-view-image ()
  "*View the image under point."
  (interactive)
  (let ((file (get-text-property (point) 'w3m-image)))
    (if file
	(w3m-external-view (w3m-content-type url)
			   (w3m-expand-url file w3m-current-url))
      (message "No file at point."))))

(defun w3m-save-image ()
  "*Save the image under point to a file."
  (interactive)
  (let ((file (get-text-property (point) 'w3m-image)))
    (if file
	(w3m-download (w3m-expand-url file w3m-current-url))
      (message "No file at point."))))

(defun w3m-view-current-url-with-external-browser ()
  "*View this URL."
  (interactive)
  (let ((url (get-text-property (point) 'w3m-href-anchor)))
    (if url
	(setq url (w3m-expand-url url w3m-current-url))
      (if (y-or-n-p (format "Browse <%s> ? " w3m-current-url))
	  (setq url w3m-current-url)))
    (when url
      (message "Browse <%s>" url)
      (w3m-external-view (w3m-content-type url) url))))

(defun w3m-download-this-url ()
  "*Download the URL of the link under point to a file."
  (interactive)
  (let ((url (get-text-property (point) 'w3m-href-anchor)))
    (if url
	(progn
	  (w3m-download url)
	  (w3m-refontify-anchor (current-buffer)))
      (message "No URL at point."))))

(defun w3m-print-current-url ()
  "*Print the URL of current page and push it into kill-ring."
  (interactive)
  (kill-new w3m-current-url)
  (message "%s" w3m-current-url))

(defun w3m-print-this-url ()
  "*Print the URL of the link under point."
  (interactive)
  (let ((url (get-text-property (point) 'w3m-href-anchor)))
    (if url
	(kill-new (setq url (w3m-expand-url url w3m-current-url))))
    (message "%s" (or url "Not found."))))


(defun w3m-next-anchor (&optional arg)
  "*Move cursor to the next anchor."
  (interactive "p")
  (unless arg (setq arg 1))
  (let (pos)
    (if (< arg 0)
	;; If ARG is negative.
	(w3m-previous-anchor (- arg))
      (when (get-text-property (point) 'w3m-href-anchor)
	(goto-char (next-single-property-change (point) 'w3m-href-anchor)))
      (while (and
	      (> arg 0)
	      (setq pos (next-single-property-change (point) 'w3m-href-anchor)))
	(goto-char pos)
	(unless (zerop (setq arg (1- arg)))
	  (goto-char (next-single-property-change (point) 'w3m-href-anchor)))))))


(defun w3m-previous-anchor (&optional arg)
  "Move cursor to the previous anchor."
  (interactive "p")
  (unless arg (setq arg 1))
  (let (pos)
    (if (< arg 0)
	;; If ARG is negative.
	(w3m-next-anchor (- arg))
      (when (get-text-property (point) 'w3m-href-anchor)
	(goto-char (previous-single-property-change (1+ (point)) 'w3m-href-anchor)))
      (while (and
	      (> arg 0)
	      (setq pos (previous-single-property-change (point) 'w3m-href-anchor)))
	(goto-char (previous-single-property-change pos 'w3m-href-anchor))
	(setq arg (1- arg))))))


(defun w3m-view-bookmark ()
  (interactive)
  (if (file-readable-p w3m-bookmark-file)
      (w3m-goto-url (w3m-expand-file-name w3m-bookmark-file))))


(defun w3m-copy-buffer (buf &optional newname and-pop) "\
Create a twin copy of the current buffer.
if NEWNAME is nil, it defaults to the current buffer's name.
if AND-POP is non-nil, the new buffer is shown with `pop-to-buffer'."
  (interactive (list (current-buffer)
		     (if current-prefix-arg (read-string "Name: "))
		     t))
  (setq newname (or newname (buffer-name)))
  (if (string-match "<[0-9]+>\\'" newname)
      (setq newname (substring newname 0 (match-beginning 0))))
  (with-current-buffer buf
    (let ((ptmin (point-min))
	  (ptmax (point-max))
	  (content (save-restriction (widen) (buffer-string)))
	  (mode major-mode)
	  (lvars (buffer-local-variables))
	  (new (generate-new-buffer (or newname (buffer-name)))))
      (with-current-buffer new
	;;(erase-buffer)
	(insert content)
	(narrow-to-region ptmin ptmax)
	(funcall mode)			;still needed??  -sm
	(mapcar (lambda (v)
		  (if (not (consp v)) (makunbound v)
		    (condition-case ()	;in case var is read-only
			(set (make-local-variable (car v)) (cdr v))
		      (error nil))))
		lvars)
	(when and-pop (pop-to-buffer new))
	new))))


(defvar w3m-mode-map nil)
(unless w3m-mode-map
  (let ((map (make-keymap)))
    (define-key map " " 'scroll-up)
    (define-key map "b" 'scroll-down)
    (define-key map [backspace] 'scroll-down)
    (define-key map [delete] 'scroll-down)
    (define-key map "h" 'backward-char)
    (define-key map "j" 'next-line)
    (define-key map "k" 'previous-line)
    (define-key map "l" 'forward-char)
    (define-key map "J" (lambda () (interactive) (scroll-up 1)))
    (define-key map "K" (lambda () (interactive) (scroll-up -1)))
    (define-key map "G" 'goto-line)
    (define-key map "\C-?" 'scroll-down)
    (define-key map "\t" 'w3m-next-anchor)
    (define-key map [down] 'w3m-next-anchor)
    (define-key map "\M-\t" 'w3m-previous-anchor)
    (define-key map [up] 'w3m-previous-anchor)
    (define-key map "\C-m" 'w3m-view-this-url)
    (define-key map [right] 'w3m-view-this-url)
    (if (featurep 'xemacs)
	(define-key map [(button2)] 'w3m-mouse-view-this-url)
      (define-key map [mouse-2] 'w3m-mouse-view-this-url))
    (define-key map "\C-c\C-b" 'w3m-view-previous-point)
    (define-key map [left] 'w3m-view-previous-page)
    (define-key map "B" 'w3m-view-previous-page)
    (define-key map "d" 'w3m-download-this-url)
    (define-key map "u" 'w3m-print-this-url)
    (define-key map "I" 'w3m-view-image)
    (define-key map "\M-I" 'w3m-save-image)
    (define-key map "c" 'w3m-print-current-url)
    (define-key map "M" 'w3m-view-current-url-with-external-browser)
    (define-key map "g" 'w3m)
    (define-key map "U" 'w3m)
    (define-key map "V" 'w3m)
    (define-key map "v" 'w3m-view-bookmark)
    (define-key map "q" 'w3m-quit)
    (define-key map "Q" (lambda () (interactive) (w3m-quit t)))
    (define-key map "\M-n" 'w3m-copy-buffer)
    (define-key map "R" 'w3m-reload-this-page)
    (define-key map "?" 'describe-mode)
    (define-key map "\M-a" 'w3m-bookmark-add-this-url)
    (define-key map "a" 'w3m-bookmark-add-current-url)
    (setq w3m-mode-map map)))


(defun w3m-quit (&optional force)
  (interactive "P")
  (when (or force
	    (y-or-n-p "Do you want to exit w3m? "))
    (kill-buffer (current-buffer))
    (w3m-arrived-list-save)
    (or (save-excursion
	  ;; Check existing w3m buffers.
	  (delq nil (mapcar (lambda (b)
			      (set-buffer b)
			      (eq major-mode 'w3m-mode))
			    (buffer-list))))
	;; If no w3m buffer exists, then destruct all cache.
	(w3m-backlog-shutdown))))


(defun w3m-mode ()
  "\\<w3m-mode-map>
   Major mode to browsing w3m buffer.

\\[w3m-view-this-url]	View this url.
\\[w3m-mouse-view-this-url]	View this url.
\\[w3m-reload-this-page]	Reload this page.
\\[w3m-next-anchor]	Jump next anchor.
\\[w3m-previous-anchor]	Jump previous anchor.
\\[w3m-view-previous-page]	Back to previous page.

\\[w3m-download-this-url]	Download this url.
\\[w3m-print-this-url]	Print this url.
\\[w3m-view-image]	View image.
\\[w3m-save-image]	Save image.

\\[w3m-print-current-url]	Print current url.
\\[w3m-view-current-url-with-external-browser]	View current url with external browser.

\\[scroll-up]	Scroll up.
\\[scroll-down]	Scroll down.

\\[next-line]	Next line.
\\[previous-line]	Previous line.

\\[forward-char]	Forward char.
\\[backward-char]	Backward char.

\\[goto-line]	Jump to line.
\\[w3m-view-previous-point]	w3m-view-previous-point.

\\[w3m]	w3m.
\\[w3m-view-bookmark]	w3m-view-bookmark.
\\[w3m-copy-buffer]	w3m-copy-buffer.

\\[w3m-quit]	w3m-quit.
\\[describe-mode]	describe-mode.
"
  (kill-all-local-variables)
  (buffer-disable-undo)
  (setq major-mode 'w3m-mode
	mode-name "w3m")
  (use-local-map w3m-mode-map)
  (run-hooks 'w3m-mode-hook))

(defun w3m-mailto-url (url)
  (if (and (symbolp w3m-mailto-url-function)
	   (fboundp w3m-mailto-url-function))
      (funcall w3m-mailto-url-function url)
    (let (comp)
      ;; Require `mail-user-agent' setting
      (if (not (and (boundp 'mail-user-agent)
		    mail-user-agent
		    (setq comp (intern-soft (concat (symbol-name mail-user-agent)
						    "-compose")))
		    (fboundp comp)))
	  (error "You must specify valid `mail-user-agent'."))
      ;; Use rfc2368.el if exist.
      ;; rfc2368.el is written by Sen Nagata.
      ;; You can find it in "contrib" directory of Mew package
      ;; or in "utils" directory of Wanderlust package.
      (if (or (featurep 'rfc2368)
	      (condition-case nil (require 'rfc2368) (error nil)))
	  (let ((info (rfc2368-parse-mailto-url url)))
	    (apply comp (mapcar (lambda (x)
				  (cdr (assoc x info)))
				'("To" "Subject"))))
	;; without rfc2368.el.
	(funcall comp (match-string 1 url))))))


(defun w3m-goto-url (url &optional reload)
  "Retrieve URL and display it in this buffer."
  (let (name buff)
    (if reload
	(w3m-backlog-remove url))
    (cond
     ;; process mailto: protocol
     ((string-match "^mailto:\\(.*\\)" url)
      (w3m-mailto-url url))
     (t
      (when (string-match "#\\([^#]+\\)$" url)
	(setq name (match-string 1 url)
	      url (substring url 0 (match-beginning 0))))
      (w3m-save-position w3m-current-url)
      (or w3m-arrived-anchor-list (w3m-arrived-list-load))
      (w3m-arrived-list-add url)
      (if (setq buff (w3m-exec url))
	  ;; no w3m exec and return *w3m* buffer.
	  (w3m-refontify-anchor buff)
	;; w3m exec.
	(w3m-fontify)
	(setq buffer-read-only t)
	(set-buffer-modified-p nil)
	(or (and name (w3m-search-name-anchor name))
	    (goto-char (point-min))))))))


(defun w3m-reload-this-page ()
  "Reload current page without cache."
  (interactive)
  (setq w3m-url-history (cdr w3m-url-history))
  (w3m-goto-url w3m-current-url 'reload))


(defun w3m (url &optional args)
  "Interface for w3m on Emacs."
  (interactive (list (w3m-input-url)))
  (set-buffer (get-buffer-create "*w3m*"))
  (or (eq major-mode 'w3m-mode)
      (w3m-mode))
  (setq mode-line-buffer-identification
	(list "%12b" " / " 'w3m-current-title))
  (if (string= url "")
      (w3m-goto-url w3m-home-page)
    (w3m-goto-url url))
  (switch-to-buffer (current-buffer))
  (run-hooks 'w3m-hook))


(defun w3m-browse-url (url &optional new-window)
  "w3m interface function for browse-url.el."
  (interactive
   (progn
     (require 'browse-url)
     (browse-url-interactive-arg "w3m URL: ")))
  (if new-window (split-window))
  (w3m url))

(defun w3m-find-file (file)
  "w3m Interface function for local file."
  (interactive "fFilename: ")
  (w3m (w3m-expand-file-name file)))

;; bookmark operations

(defun w3m-bookmark-file-modified-p ()
  "Predicate for FILE is something modified."
  (and (file-exists-p w3m-bookmark-file)
       w3m-bookmark-file-time-stamp 
       (not (equal (elt (file-attributes w3m-bookmark-file) 5) 
		   w3m-bookmark-file-time-stamp))))

;; bookmark data format
;; bookmark has some section.
;; section has some entries.
;; entry is pair of link name (title) and url
;; for example:
;; bookmark := ( ("My Favorites"                    ; section
;;                ( "title1" . "http://foo.com/" )  ; entry
;;                ( "title2" . "http://bar.org/" )) ; entry
;;               ("For Study"                       ; section
;;                ( "Title3" . "http://baz.net/" )) ; entry
;;
;; In w3m, section is h2 level contents. (HTML/BODY/H2)
;; entry is A item (represented as UL/LI)
;; `w3m-bookmark-parse' assumes above
;;  because this is easy implementation. :-)

(defun w3m-bookmark-parse ()
  "Parse current buffer and returns bookmark data alist for internal."
  (let (bookmark tag url str)
    (goto-char 1)
    (while (re-search-forward
	    "<\\(h2\\|a\\)\\( *href=\"\\([^\"]+\\)\"[^>]*\\)?>" nil t)
      (setq tag (match-string 1))
      (cond 
       ((string= tag "h2")
	;; make new section (in top)
	(setq bookmark (cons (list (buffer-substring
				    (match-end 0)
				    (progn (re-search-forward "</h2>")
					   (match-beginning 0))))
			     bookmark)))
       ((string= tag "a")
	(if (null (match-beginning 2))
	    (error "parse error, href attribute is expected."))
	(setq url (match-string 3)
	      str (buffer-substring (match-end 0)
				    (progn
				      (re-search-forward "</a>")
				      (match-beginning 0))))
	(setcar bookmark (cons (cons str url) (car bookmark))))
       (t (error "parse error, unknown tag is matched."))))
    ;; reverse entries and sections
    (nreverse (mapcar 'nreverse bookmark))))
			 
	       
    
(defun w3m-bookmark-load (&optional file)
  "Load bookmark from FILE.
Parsed bookmark data is hold in `w3m-bookmark-data'."
  (or file
      (setq file w3m-bookmark-file))	; default name
  (message "Loading bookmarks...")
  (with-temp-buffer
    (if (file-exists-p w3m-bookmark-file)
	(insert-file-contents w3m-bookmark-file))
    ;; parse
    (setq w3m-bookmark-data (w3m-bookmark-parse)
	  w3m-bookmark-file-time-stamp (elt (file-attributes file) 5)))
  (message "Loading bookmarks...done"))


(defun w3m-bookmark-save (&optional file)
  "Save internal bookmark data into bookmark file as w3m format."
  (let ((bookmark w3m-bookmark-data)
	entries)
    (or file
	(setq file w3m-bookmark-file)) ; default name
    ;; check output directory
    (if (not (file-writable-p file))
	(message "Can't write! Bookmark file is not saved.")
      ;;
      (with-temp-buffer
	;; print beginning of html
	(insert "<html><head><title>Bookmarks</title></head>\n"
		"<body>\n"
		"<h1>Bookmarks</h1>\n")
	(while bookmark
	  (setq entries (car bookmark)
		bookmark (cdr bookmark))
	  (insert "<h2>" (car entries) "</h2>\n")
	  (setq entries (cdr entries))
	  (insert "<ul>\n")
	  (while entries
	    (insert "<li><a href=\"" (cdr (car entries)) "\">"
		    (car (car entries)) "</a>\n")
	    (setq entries (cdr entries)))
	  (insert "<!--End of section (do not delete this comment)-->\n"
		  "</ul>\n"))
	;; print end of html
	(insert "</body>\n"
		"</html>\n")
	;; write to file!
	(let ((coding-system-for-write w3m-bookmark-file-coding-system))
	  (write-region (point-min) (point-max) file))
	(setq w3m-bookmark-file-time-stamp (elt (file-attributes file) 5))
	(message "Saved to '%s'" file)))))

(defun w3m-bookmark-data-prepare ()
  "Prepare for bookmark operation.
If bookmark data is not loaded, load it.
If bookmark file is modified since last load, ask reloading."
  (if (and (null w3m-bookmark-file-time-stamp)
	   (null w3m-bookmark-data)
	   (file-exists-p w3m-bookmark-file))
      (w3m-bookmark-load w3m-bookmark-file)))


(defun w3m-bookmark-add (url &optional title section)
  "Add URL to bookmark data and save it to file.
Optional argument TITLE is title of link.
SECTION is category name in bookmark."
  (let (sec ent)
    (w3m-bookmark-data-prepare)
    ;; check time stamp of bookmark file (localy modified?)
    (if (and (w3m-bookmark-file-modified-p)
	     (y-or-n-p "Bookmark file is modified. Reload it? (y/n): "))
	(w3m-bookmark-load))
    ;; go on ...
    ;; ask section (with completion).
    (setq sec (completing-read
	       "Section: "
	       w3m-bookmark-data nil nil nil 
	       'w3m-bookmark-section-history ))
    (if (string-match sec "^ *$")
	(error "You must specify section name."))
    ;; ask title (with default)
    (setq title (read-string "Title: " title 'w3m-bookmark-title-history))
    (if (string-match sec "^ *$")
	(error "You must specify title."))
    ;; add it to internal bookmark data.
    (if (setq ent (assoc sec w3m-bookmark-data))
	;; add to existing section
	(nconc ent (list (cons title url))) ; add to tail
      ;; add as new section 
      (setq w3m-bookmark-data
	    (nconc w3m-bookmark-data
		   (list (list sec (cons title url))))))
    ;; then save to file. (xxx, force saving, should we ask?)
    (w3m-bookmark-save)))


(defun w3m-bookmark-add-this-url ()
  "Add link under cursor to bookmark."
  (interactive)
  (if (null (get-text-property (point) 'w3m-href-anchor))
      (message "No anchor.")		; nothing to do
    (w3m-bookmark-add
     (get-text-property (point) 'w3m-href-anchor) ; url
     (buffer-substring-no-properties	; title
      (previous-single-property-change (1+ (point)) 'w3m-href-anchor)
      (next-single-property-change (point) 'w3m-href-anchor)))
    (message "Added.")))


(defun w3m-bookmark-add-current-url (&optional arg)
  "Add link of current page to bookmark.
With prefix, ask new url to add instead of current page."
  (interactive "P")
  (w3m-bookmark-add (if (null arg) w3m-current-url (w3m-input-url))
		    w3m-current-title)
  (message "Added."))


(defun w3m-cygwin-path (path)
  "Convert win32 path into cygwin format.
ex.) c:/dir/file => //c/dir/file"
  (if (string-match "^\\([A-Za-z]\\):" path)
      (replace-match "//\\1" nil nil path)
    path))


(defun w3m-region (start end)
  "Render region in current buffer and replace with result."
  (interactive "r")
  (save-restriction
    (narrow-to-region start end)
    (w3m-rendering-region start end)
    (w3m-fontify)))


(provide 'w3m)
;;; w3m.el ends here.
