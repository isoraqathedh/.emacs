(provide 'shinmera-keys)
(require 'shinmera-general)

;;;;;;
;; Extra keybindings
(defvar my-keys-minor-mode-map (make-keymap) "my-keys-minor-mode keymap.")
(defmacro define-my-key (kbd func)
  `(define-key my-keys-minor-mode-map (kbd ,kbd) ,func))

(define-my-key "C-c k"         'delete-this-buffer-and-file)
(define-my-key "C-S-c C-S-c"   'mc/edit-lines)
(define-my-key "C-M-<next>"    'mc/mark-next-like-this)
(define-my-key "C-M-<prior>"   'mc/mark-previous-like-this)
(define-my-key "C-M-m <down>"  'mc/mark-next-like-this)
(define-my-key "C-M-m <up>"    'mc/mark-previous-like-this)
(define-my-key "C-M-m <right>" 'mc/unmark-next-like-this)
(define-my-key "C-M-m <left>"  'mc/unmark-previous-like-this)
(define-my-key "C-M-m a"       'mc/mark-all-like-this)
(define-my-key "C-q"           'er/expand-region)
(define-my-key "M-g"           'raise-sexp)
(define-my-key "C-v"           'yank)
(define-my-key "C-l"           'switch-dictionary)
(define-my-key "C-o"           'uim-mode)
(define-my-key "C-c d"         'toggle-window-dedication)
(define-my-key "<apps>"        'execute-extended-command)

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)

;; Activate my-keys possibly everywhere
(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  t " My-Keys" 'my-keys-minor-mode-map)

(my-keys-minor-mode 1)
(defun my-minibuffer-setup-hook () (my-keys-minor-mode 0))
(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

(defadvice load (after give-my-keybindings-priority)
  "Try to ensure that my keybindings always have priority."
  (if (not (eq (car (car minor-mode-map-alist)) 'my-keys-minor-mode))
      (let ((mykeys (assq 'my-keys-minor-mode minor-mode-map-alist)))
        (assq-delete-all 'my-keys-minor-mode minor-mode-map-alist)
        (add-to-list 'minor-mode-map-alist mykeys))))
(ad-activate 'load)
