(provide 'shinmera-lisp)

;;;;;;
;; SLIME
(require 'slime-autoloads)

(autoload 'slime "ac-slime" "Slime AutoComplete" t)
(autoload 'hyperspec-lookup "clhs-use-local" t)

(slime-setup '(slime-fancy slime-asdf slime-sprof
               slime-compiler-notes-tree slime-hyperdoc
               slime-mrepl slime-indentation slime-repl slime-media))

(setq
 slime-lisp-implementations                   '((sbcl  ("/usr/bin/sbcl")
                                                       :coding-system utf-8-unix)
                                                (clisp ("/usr/bin/clisp"))
                                                (abcl  ("/usr/bin/abcl"))
                                                (ccl32 ("/usr/bin/ccl"))
                                                (ccl   ("/usr/bin/ccl64"))
                                                (cmucl ("/usr/bin/cmucl" "-quiet"))
                                                (ecl   ("/usr/bin/ecl")))
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

(defun sbcl () (interactive) (slime 'sbcl))
(defun ccl () (interactive) (slime 'ccl))
(defun ccl32 () (interactive) (slime 'ccl32))
(defun cmucl () (interactive) (slime 'cmucl))
(defun abcl () (interactive) (slime 'abcl))
(defun clisp () (interactive) (slime 'clisp))
(defun ecl () (interactive) (slime 'ecl))

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

;;;;;;
;; Elisp
(add-hook 'emacs-lisp-mode-hook               #'flyspell-prog-mode)
