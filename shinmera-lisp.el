;; -*- mode: elisp; lexical-binding: t; -*-
(provide 'shinmera-lisp)
(require 'shinmera-package)

(when (featurep 'shinmera-package)
  (ensure-installed 'slime 'paredit 'elisp-slime-nav))

;;;;;;
;; SLIME
(require 'cl-lib)
(require 'cl-indent)
(require 'slime-autoloads)

(autoload 'hyperspec-lookup "clhs-use-local" t)

(setq
 shinmera-slime-contribs '(slime-fancy slime-asdf slime-sprof slime-mdot-fu
                           slime-compiler-notes-tree slime-hyperdoc
                           slime-indentation slime-repl)
 slime-complete-symbol-function               'slime-fuzzy-complete-symbol
 slime-net-coding-system                      'utf-8-unix
 slime-startup-animation                      nil
 slime-auto-select-connection                 'always
 slime-kill-without-query-p                   t
 slime-description-autofocus                  t 
 slime-fuzzy-explanation                      ""
 slime-asdf-collect-notes                     t
 slime-inhibit-pipelining                     nil
 slime-load-failed-fasl                       'always
 slime-when-complete-filename-expand          t
 slime-repl-history-remove-duplicates         t
 slime-repl-history-trim-whitespaces          t
 slime-export-symbol-representation-auto      t
 lisp-indent-function                         'common-lisp-indent-function
 lisp-loop-indent-subclauses                  nil
 lisp-loop-indent-forms-like-keywords         t
 lisp-lambda-list-keyword-parameter-alignment t)

(add-hook 'slime-repl-mode-hook               #'override-slime-repl-bindings-with-paredit)
(add-hook 'slime-repl-mode-hook               #'set-slime-repl-return)

(defun set-slime-repl-return ()
  (define-key slime-repl-mode-map (kbd "RET") 'slime-repl-return-at-end)
  (define-key slime-repl-mode-map (kbd "<return>") 'slime-repl-return-at-end))

(defun slime-repl-return-at-end ()
  (interactive)
  (if (<= (point-max) (point))
      (slime-repl-return)
      (slime-repl-newline-and-indent)))

(defun override-slime-repl-bindings-with-paredit ()
  (define-key slime-repl-mode-map
      (read-kbd-macro paredit-backward-delete-key) nil))

(defmacro define-lisp-implementations (&rest decl)
  `(progn
     ,@(cl-loop for (symbol . args) in decl
                collect `(progn
                           (defun ,symbol ()
                             (interactive)
                             (slime ',symbol))
                           (cl-pushnew '(,symbol ,@args) slime-lisp-implementations
                                       :key 'car)))))

(with-eval-after-load "slime"
  (when (or (eq system-type 'gnu/linux)
            (eq system-type 'darwin))
    (define-lisp-implementations
      (abcl  ("abcl"))
      (acl   ("alisp"))
      (ccl32 ("ccl"))
      (ccl   ("ccl64"))
      (clasp ("clasp"))
      (clisp ("clisp"))
      (cmucl ("cmucl" "-quiet"))
      (ecl   ("ecl"))
      (mkcl  ("mkcl"))
      (xcl   ("xcl"))
      (sbcl  ("sbcl"))))
  
  (when (eq system-type 'windows-nt)
    (define-lisp-implementations
      (ccl   ("wx86cl64.exe"))
      (ccl32 ("wx86cl.exe"))
      (clisp ("clisp.exe"))
      (sbcl  ("sbcl.exe")))))
  
(defun set-default-lisp-implementation (impl)
  (let ((impl (cl-assoc impl slime-lisp-implementations)))
    (setq slime-lisp-implementations
          (cl-remove impl slime-lisp-implementations))
    (push impl slime-lisp-implementations)))

;;;;;;
;; Paredit
(autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)

(add-hook 'emacs-lisp-mode-hook               #'enable-paredit-mode)
(add-hook 'lisp-mode-hook                     #'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook         #'enable-paredit-mode)
(add-hook 'scheme-mode-hook                   #'enable-paredit-mode)
(add-hook 'ielm-mode-hook                     #'enable-paredit-mode)
(add-hook 'slime-repl-mode-hook               #'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)

(put 'paredit-forward-delete 'delete-selection 'supersede)
(put 'paredit-backward-delete 'delete-selection 'supersede)
(put 'paredit-newline 'delete-selection t)

;; Fix the spacing for macro characters such as #p, etc.
(defvar known-macro-characters (make-hash-table))

(defun determine-cl-macro-character (macro-char)
  (when (slime-connected-p)
    (slime-eval-async
     `(cl:ignore-errors
       (cl:not (cl:null (cl:get-macro-character
                         (cl:code-char ,macro-char)))))
     (lambda (result)
       (puthash macro-char result known-macro-characters)))))

(defun cl-macro-character-p (macro-char)
  (pcase (gethash macro-char known-macro-characters :not-found)
         (`t t)
         (`nil nil)
         (:not-found
          (determine-cl-macro-character macro-char)
          (or ;; Don't know the result (yet), determine statically.
           (eql macro-char ?#)))))

(defun paredit-detect-cl-macro-character (endp delimiter)
  (when (find major-mode '(slime-repl-mode lisp-mode))
    (if (not endp)
        (save-excursion
         (let ((1-back (char-before (point)))
               (2-back (char-before (- (point) 1))))
           (null (or (cl-macro-character-p (char-before (point)))
                     (cl-macro-character-p (char-before (1- (point))))))))
        t)))

(with-eval-after-load 'paredit
  (add-to-list 'paredit-space-for-delimiter-predicates
               #'paredit-detect-cl-macro-character))

;;;;;;
;; Elisp
(require 'elisp-slime-nav)
(add-hook 'emacs-lisp-mode-hook #'elisp-slime-nav-mode)

;;;;;;
;; Autocomplete
(when (featurep 'shinmera-autocomplete)
  (when (featurep 'shinmera-package)
    (ensure-installed 'ac-slime))
  
  (autoload 'slime "ac-slime" "Slime AutoComplete" t)
  (add-to-list 'ac-modes 'slime-repl-mode)
  (add-hook 'slime-mode-hook #'set-up-slime-ac)
  (add-hook 'slime-repl-mode-hook #'set-up-slime-ac))

;;;;;
;; Company
(when (featurep 'shinmera-company)
  (when (featurep 'shinmera-package)
    (ensure-installed 'slime-company))
  (push 'slime-company shinmera-slime-contribs)

  (define-key company-active-map (kbd "\C-n") 'company-select-next)
  (define-key company-active-map (kbd "\C-p") 'company-select-previous)
  (define-key company-active-map (kbd "\C-d") 'company-show-doc-buffer)
  (define-key company-active-map (kbd "M-.") 'company-show-location))

;;;;;
;; Setup slime
(slime-setup shinmera-slime-contribs)
