(provide 'shinmera-lisp)
(require 'shinmera-package)

(when (featurep 'shinmera-package)
  (ensure-installed 'auto-complete 'slime 'ac-slime 'paredit))

;;;;;;
;; SLIME
(require 'cl-lib)
(require 'slime-autoloads)

(autoload 'slime "ac-slime" "Slime AutoComplete" t)
(autoload 'hyperspec-lookup "clhs-use-local" t)

(slime-setup '(slime-fancy slime-asdf slime-sprof
               slime-compiler-notes-tree slime-hyperdoc
               slime-mrepl slime-indentation slime-repl slime-media))

(setq
 lisp-indent-function                         'common-lisp-indent-function
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
 lisp-loop-indent-subclauses                  nil
 slime-when-complete-filename-expand          t
 slime-repl-history-remove-duplicates         t
 slime-repl-history-trim-whitespaces          t
 lisp-loop-indent-forms-like-keywords         t
 lisp-lambda-list-keyword-parameter-alignment t
 slime-export-symbol-representation-auto      t)

(add-hook 'slime-mode-hook                    #'flyspell-prog-mode)
(add-hook 'slime-mode-hook                    #'set-up-slime-ac)
(add-hook 'slime-repl-mode-hook               #'set-up-slime-ac)
(add-hook 'slime-repl-mode-hook               #'override-slime-repl-bindings-with-paredit)
(add-hook 'slime-repl-mode-hook               #'set-slime-history-keys)

(add-to-list 'ac-modes                        'slime-repl-mode)

(defun set-slime-history-keys ()
  (local-set-key (kbd "C-x <up>") 'slime-repl-backward-input)
  (local-set-key (kbd "C-x <down>") 'slime-repl-forward-input))

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
  (sbcl  ("sbcl")))

(when window-system
  (slime))

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

;; Fix the spacing for dispatch macros, such as #p, etc.
(defun dispatch-macro-character-p (disp sub)
  (or
   (and (slime-connected-p)
        (slime-eval `(cl:ignore-errors (cl:not (cl:null (cl:get-dispatch-macro-character (cl:code-char ,disp) (cl:code-char ,sub)))))))
   ;; Not connected, determine statically by just "knowing".
   (eql disp ?#)))

(defun paredit-detect-dispatch-macro (endp delimiter)
  (when (find major-mode '(slime-repl-mode lisp-mode))
    (if (not endp)
        (save-excursion
         (let ((1-back (char-before (point)))
               (2-back (char-before (- (point) 1))))
           (null
            (dispatch-macro-character-p 2-back 1-back))))
        t)))

(add-to-list 'paredit-space-for-delimiter-predicates
             #'paredit-detect-dispatch-macro)


;;;;;;
;; Elisp
(add-hook 'emacs-lisp-mode-hook               #'flyspell-prog-mode)
