;;; -*- mode: Emacs-Lisp; coding: euc-japan -*-

;; Copyright (C) 2000 TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>,
;;          Shun-ichi GOTO     <gotoh@taiyo.co.jp>,
;;          Satoru Takabayashi <satoru-t@is.aist-nara.ac.jp>
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

(defcustom w3m-command-arguments '("-e" "-halfdump" "-cols" col url)
  "*Arguments of w3m."
  :group 'w3m
  :type '(repeat (restricted-sexp :match-alternatives (stringp 'col 'url))))

(defcustom w3m-viewer-command "xv"
  "*Name of the viewer."
  :group 'w3m
  :type 'string)

(defcustom w3m-viewer-command-arguments '(file)
  "Arguments of viewer."
  :group 'w3m
  :type '(repeat (restricted-sexp :match-alternatives (stringp 'file))))

(defcustom w3m-browser-command "netscape"
  "*Name of the browser."
  :group 'w3m
  :type 'string)

(defcustom w3m-browser-command-arguments '(url)
  "Arguments of browser."
  :group 'w3m
  :type '(repeat (restricted-sexp :match-alternatives (stringp 'url))))

(defcustom w3m-coding-system (if (boundp 'MULE) '*euc-japan* 'euc-japan)
  "*Coding system for w3m."
  :group 'w3m
  :type 'symbol)

(defcustom w3m-bookmark-file (expand-file-name "~/.w3m/bookmark.html")
  "*Bookmark file of w3m."
  :group 'w3m
  :type 'file)

(defcustom w3m-fill-column (- (frame-width) 4)
  "*Fill column of w3m."
  :group 'w3m
  :type 'integer)

(defface w3m-anchor-face
  '((((class color) (background light)) (:foreground "red" :underline t))
    (((class color) (background dark)) (:foreground "blue" :underline t))
    (t (:underline t)))
  "*Face to fontify anchors."
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


(defun w3m-fontify ()
  "Fontify this buffer."
  (let ((case-fold-search t))
    (run-hooks 'w3m-fontify-before-hook)
    ;; Delete extra title tag.
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
		 (put-text-property start end 'face 'w3m-anchor-face)
		 (put-text-property start end 'w3m-href-anchor url))
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
	  (put-text-property start end 'w3m-image src))))
    ;; Remove other markups.
    (goto-char (point-min))
    (while (re-search-forward "</?[A-z][^>]*>" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    ;; Decode escaped characters.
    (goto-char (point-min))
    (while (re-search-forward
	    "&\\(\\(nbsp\\)\\|\\(gt\\)\\|\\(lt\\)\\|\\(amp\\)\\|\\(quot\\)\\|\\(apos\\)\\);"
	    nil t)
      (delete-region (match-beginning 0) (match-end 0))
      (insert (if (match-beginning 2) " "
		(if (match-beginning 3) ">"
		  (if (match-beginning 4) "<"
		    (if (match-beginning 5) "&"
		      (if (match-beginning 6) "\"" "'")))))))
    (run-hooks 'w3m-fontify-after-hook)))


(defvar w3m-input-url-history nil)

(defun w3m-input-url (&optional prompt default)
  "Read a URL from the minibuffer, prompting with string PROMPT."
  (let (url candidates)
    (w3m-backlog-setup)
    (mapatoms (lambda (x)
		(setq candidates (cons (cons (symbol-name x) x) candidates)))
	      w3m-backlog-hashtb)
    (setq url (completing-read (or prompt "URL: ")
			       candidates nil nil
			       default 'w3m-input-url-history default))
    ;; remove duplication
    (setq w3m-input-url-history (cons url (delete url w3m-input-url-history)))
    ;; return value
    url))


(defcustom w3m-keep-backlog 300
  "*Back log size of w3m."
  :group 'w3m
  :type 'integer)

(defvar w3m-backlog-buffer nil)
(defvar w3m-backlog-articles nil)
(defvar w3m-backlog-hashtb nil)

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
    (if (memq ident w3m-backlog-articles)
	()				; It's already kept.
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
      (let (beg end)
	(save-excursion
	  (set-buffer w3m-backlog-buffer)
	  (if (not (setq beg (text-property-any
			      (point-min) (point-max) 'w3m-backlog ident)))
	      ;; It wasn't in the backlog after all.
	      (setq w3m-backlog-articles (delq ident w3m-backlog-articles))
	    ;; Find the end (i. e., the beginning of the next article).
	    (setq end
		  (next-single-property-change
		   (1+ beg) 'w3m-backlog (current-buffer) (point-max)))))
	(and beg
	     end
	     (save-excursion
	       (and buffer (set-buffer buffer))
	       (let (buffer-read-only)
		 (insert-buffer-substring w3m-backlog-buffer beg end))
	       t))))))

(defvar w3m-current-url nil "URL of this buffer.")
(defvar w3m-current-title nil "Title of this buffer.")
(defvar w3m-url-history nil "History of URL.")

(defun w3m-exec (url &optional buffer)
  "Download URL with w3m to the BUFFER.
If BUFFER is nil, all data is placed to the current buffer."
  (save-excursion
    (if buffer (set-buffer buffer))
    (delete-region (point-min) (point-max))
    (or (w3m-backlog-request url)
	(let ((coding-system-for-read w3m-coding-system)
	      (default-process-coding-system (cons w3m-coding-system w3m-coding-system))
	      (args (copy-sequence w3m-command-arguments)))
	  (cond
	   ((string-match "\\.s?html?$\\|/$" url)) ; do nothing
	   ((string-match "\\.\\(txt\\|el\\)$" url)
	    (setq args (cons "-dump" (delete "-halfdump" args))))
;;	   (t
;;	    (error "Unsupported suffix to retrieve.")))
	   )
	  (message "Loading page...")
	  (apply 'call-process w3m-command nil t nil
		 (mapcar (lambda (arg)
			   (if (eq arg 'col)
			       (format "%d" w3m-fill-column)
			     (eval arg)))
			 args))
	  (w3m-backlog-enter url (current-buffer))
	  (message "Loading page...done")))
    ;; Setting buffer local variables.
    (set (make-local-variable 'w3m-current-url) url)
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
      (set (make-local-variable 'w3m-current-title) (or title "<no-title>")))
    (set (make-local-variable 'w3m-url-history)
	 (cons url w3m-url-history))
    (setq-default w3m-url-history
		  (cons url (default-value 'w3m-url-history)))))


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


(defun w3m-expand-url (url base)
  "Convert URL to absolute, and canonicalize it."
  (if (string-match "^[^:]+://[^/]*$" base)
      (setq base (concat base "/")))
  (cond
   ;; URL has absolute spec.
   ((string-match "^[^:]+:" url)
    url)
   ((string-match "^/" url)
    (if (string-match "^\\([^:]+://[^/]*\\)/" base)
	(concat (match-string 1 base) url)
      url))
   ;; URL is relative on BASE.
   ((string-match "^#" url)
    (concat base url))
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


(defun w3m-view-this-url (arg)
  "*View the URL of the link under point."
  (interactive "P")
  (let ((url (get-text-property (point) 'w3m-href-anchor)))
    (if url (w3m-goto-url (w3m-expand-url url w3m-current-url) arg))))

(defun w3m-mouse-view-this-url (event)
  (interactive "e")
  (mouse-set-point event)
  (call-interactively (function w3m-view-this-url)))

(defun w3m-view-image ()
  "*View the image under point."
  (interactive)
  (let ((file (get-text-property (point) 'w3m-image)))
    (if file
	(let ((buffer (get-buffer-create " *w3m-view*")))
	  (apply 'start-process
		 "w3m-view"
		 buffer
		 w3m-viewer-command
		 (mapcar 'eval w3m-viewer-command-arguments))))))


(defun w3m-save-image ()
  "*Save the image under point to a file."
  (interactive)
  (let ((file (get-text-property (point) 'w3m-image)))
    (message "Please implement this function !!")))


(defun w3m-view-current-url-with-external-browser ()
  "*View this URL."
  (interactive)
  (let ((buffer (get-buffer-create " *w3m-view*"))
	(url (w3m-expand-url (get-text-property (point) 'w3m-href-anchor)
			     w3m-current-url)))
    (apply 'start-process
	   "w3m-external-browser"
	   buffer
	   w3m-browser-command
	   (mapcar (function eval)
		   w3m-browser-command-arguments))))


(defun w3m-download-this-url ()
  "*Download the URL of the link under point to a file."
  (interactive)
  (message "Please implement this function !!"))

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
	(goto-char (next-single-property-change (point) 'w3m-href-anchor))))))


(defun w3m-previous-anchor (&optional arg)
  "Move cursor to the previous anchor."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (< arg 0)
      ;; If ARG is negative.
      (w3m-next-anchor (- arg))
    (when (get-text-property (point) 'w3m-href-anchor)
      (goto-char (previous-single-property-change (1+ (point)) 'w3m-href-anchor)))
    (while (and
	    (> arg 0)
	    (setq pos (previous-single-property-change (point) 'w3m-href-anchor)))
      (goto-char (previous-single-property-change pos 'w3m-href-anchor))
      (setq arg (1- arg)))))

(defun w3m-expand-file-name (file)
  (setq file (expand-file-name file))
  (if (string-match "^\\(.\\):\\(.*\\)" file)
      (concat "/cygdrive/" (match-string 1 file) (match-string 2 file))
    file))

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
  (setq w3m-mode-map (make-keymap))
  (define-key w3m-mode-map " " 'scroll-up)
  (define-key w3m-mode-map "b" 'scroll-down)
  (define-key w3m-mode-map [backspace] 'scroll-down)
  (define-key w3m-mode-map [delete] 'scroll-down)
  (define-key w3m-mode-map "h" 'backward-char)
  (define-key w3m-mode-map "j" 'next-line)
  (define-key w3m-mode-map "k" 'previous-line)
  (define-key w3m-mode-map "l" 'forward-char)
  (define-key w3m-mode-map "J" (lambda () (interactive) (scroll-up 1)))
  (define-key w3m-mode-map "K" (lambda () (interactive) (scroll-up -1)))
  (define-key w3m-mode-map "G" 'goto-line)
  (define-key w3m-mode-map "\C-?" 'scroll-down)
  (define-key w3m-mode-map "\t" 'w3m-next-anchor)
  (define-key w3m-mode-map [down] 'w3m-next-anchor)
  (define-key w3m-mode-map "\M-\t" 'w3m-previous-anchor)
  (define-key w3m-mode-map [up] 'w3m-previous-anchor)
  (define-key w3m-mode-map "\C-m" 'w3m-view-this-url)
  (define-key w3m-mode-map [right] 'w3m-view-this-url)
  (define-key w3m-mode-map [mouse-2] 'w3m-mouse-view-this-url)
  (define-key w3m-mode-map [left] 'w3m-view-previous-page)
  (define-key w3m-mode-map "B" 'w3m-view-previous-page)
  (define-key w3m-mode-map "d" 'w3m-download-this-url)
  (define-key w3m-mode-map "u" 'w3m-print-this-url)
  (define-key w3m-mode-map "I" 'w3m-view-image)
  (define-key w3m-mode-map "\M-I" 'w3m-save-image)
  (define-key w3m-mode-map "c" 'w3m-print-current-url)
  (define-key w3m-mode-map "M" 'w3m-view-current-url-with-external-browser)
  (define-key w3m-mode-map "g" 'w3m)
  (define-key w3m-mode-map "U" 'w3m)
  (define-key w3m-mode-map "V" 'w3m)
  (define-key w3m-mode-map "v" 'w3m-view-bookmark)
  (define-key w3m-mode-map "q" 'w3m-quit)
  (define-key w3m-mode-map "Q" (lambda () (interactive) (w3m-quit t)))
  (define-key w3m-mode-map "\M-n" 'w3m-copy-buffer)
  (define-key w3m-mode-map "R" 'w3m-reload-this-page)
  )


(defun w3m-quit (&optional force)
  (interactive "P")
  (when (or force
	    (y-or-n-p "Do you want to exit w3m? "))
    (w3m-backlog-shutdown)
    (kill-buffer (current-buffer))))


(defun w3m-mode ()
  "Major mode to browsing w3m buffer."
  (kill-all-local-variables)
  (setq major-mode 'w3m-mode
	mode-name "w3m")
  (use-local-map w3m-mode-map)
  (run-hooks 'w3m-mode-hook))

(defun w3m-mailto-url (url)
  (let (func)
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
      (funcall comp (match-string 1 url)))))


(defun w3m-goto-url (url &optional reload)
  "Retrieve URL and display it in this buffer."
  (let (name)
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
      (setq buffer-read-only nil)
      (w3m-save-position w3m-current-url)
      (w3m-exec url)
      (w3m-fontify)
      (setq buffer-read-only t)
      (set-buffer-modified-p nil)
      (or (and name (w3m-search-name-anchor name))
	  (goto-char (point-min)))))))


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
      (w3m-view-bookmark)
    (w3m-goto-url url))
  (switch-to-buffer (current-buffer))
  (run-hooks 'w3m-hook))


(provide 'w3m)
;;; w3m.el ends here.
