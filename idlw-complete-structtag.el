;;; idlw-complete-structtag.el --- Completion of structure tags.
;; Copyright (c) 1999, 2000, 2001 Free Software Foundation

;; Author: Carsten Dominik <dominik@astro.uva.nl>
;; Version: 1.0
;; Date: $Date: 2001/12/05 20:04:09 $
;; Keywords: languages

;; Completion of structure tags is highly ambiguous since you never
;; know what kind of structure a variable will hold at runtime.
;; However, in some applications there is one main structure which
;; contains a large amount of information.  For example, in many
;; widget applications, a "state" structure contains all important
;; data about the application is stored in the main widget.  The
;; different routines called by the event handler then use this
;; structure for their actions.  If you use the same variable name for
;; this structure throughout your application (a good idea for many
;; reasons), IDLWAVE can support completion for its tags.  
;;
;; This file is a completion plugin which implements this kind of
;; completion. It is also an example which shows how completion
;; plugins should be programmed.
;;
;; INSTALLATION
;; ============
;; Put this file on the emacs load path and load it with the following 
;; line in your .emacs file:
;;
;;   (add-hook 'idlwave-load-hook 
;;             (lambda () (require 'idlw-complete-structtag)))
;;
;; DESCRIPTION
;; ===========
;; Suppose your IDL program contains something like
;;
;;     myvar = state.a*
;;
;; where the star marks the cursor position.  If you now press the
;; completion key M-TAB, IDLWAVE searches the current file for a
;; structure definition
;;
;;   state = {tag1:val1, tag2:val2, ...}
;;
;; and offers the tags for completion.
;;
;; Notes
;; -----
;;  - The structure definition assignment "state = {...}" must use the
;;    same variable name as the the completion location "state.*".
;;  - The structure definition must be in the same file.
;;  - The structure definition is searched first backwards, then
;;    forward from the cursor position.
;;  - The file is parsed again for the definition only if the variable 
;;    name (like "state") of the current completion differs from the
;;    previous tag completion.
;;  - You can force and update of the tag list with the usual command
;;    to update routine info in IDLWAVE: C-c C-i
;;
;;
(defvar idlwave-current-tags-var nil)
(defvar idlwave-current-tags-buffer nil)
(defvar idlwave-current-struct-tags nil)
(defvar idlwave-sint-structtags nil)
(idlwave-new-sintern-type 'structtag)
(add-to-list 'idlwave-complete-special 'idlwave-complete-structure-tag)
(add-hook 'idlwave-update-rinfo-hook 'idlwave-structtag-reset)

(defun idlwave-complete-structure-tag ()
  "Complete a structure tag.
This works by looking in the current file for a structure assignment to a
variable with the same name and takes the tags from there.  Quite useful
for big structures like the state variables of a widget application."
  (interactive)
  (let ((pos (point))
	(case-fold-search t))
    (if (save-excursion
	  ;; Check if the context is right
	  (skip-chars-backward "[a-zA-Z0-9._$]")
	  (and (< (point) pos)
	       (looking-at "\\([a-zA-Z][a-zA-Z0-9_]*\\)\\.")
	       (>= pos (match-end 0))
	       (not (string= (downcase (match-string 1)) "self"))))  ;; FIXME:  Can we avoid checking for self here?
	(let* ((var (downcase (match-string 1))))
	  ;; Check if we need to update the "current" class
	  (if (or (not (string= var (or idlwave-current-tags-var "@")))
		  (not (eq (current-buffer) idlwave-current-tags-buffer)))
	      (idlwave-prepare-structure-tag-completion var))
	  (setq idlwave-completion-help-info nil)
	  (idlwave-complete-in-buffer 'structtag 'structtag 
				      idlwave-current-struct-tags nil
				      "Select a structure tag" "structure tag")
	  t) ; return t to skip other completions
      nil)))

(defun idlwave-structtag-reset ()
  (setq idlwave-current-tags-buffer nil))

(defun idlwave-prepare-structure-tag-completion (var)
  "Find and parse the necessary class definitions for class structure tags."
  ;; (message "switching to var %s" var) ; FIXME: take this out.
  ;; (sit-for 2)
  (save-excursion
    (if (idlwave-find-structure-definition var nil 'all)
	(progn
	  (setq idlwave-sint-structtags nil
		idlwave-current-tags-buffer (current-buffer)
		idlwave-current-tags-var var
		idlwave-current-struct-tags
		(mapcar (lambda (x)
			  (list (idlwave-sintern-structtag x 'set)))
			(idlwave-struct-tags))))
      (error "Cannot complete structure tags of variable %s" var))))

(provide 'idlwave-complete-structtag)

;;; idlw-complete-structtag.el ends here