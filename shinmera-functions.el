(provide 'shinmera-functions)

;;;;;;
;; Various helper functions
(defun delete-this-buffer-and-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (delete-file filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

;; Auto-indent yank
(dolist (command '(yank yank-pop))
  (eval `(defadvice ,command (after indent-region activate)
           (and (not current-prefix-arg)
                (member major-mode '(emacs-lisp-mode lisp-mode
                                                     clojure-mode    scheme-mode
                                                     haskell-mode    ruby-mode
                                                     rspec-mode      python-mode
                                                     c-mode          c++-mode
                                                     objc-mode       latex-mode
                                                     plain-tex-mode))
                (let ((mark-even-if-inactive transient-mark-mode))
                  (indent-region (region-beginning) (region-end) nil))))))

(defun sudo ()
  (interactive)
  (let ((position (point)))
    (find-alternate-file (concat "/sudo::"
                                 (buffer-file-name (current-buffer))))
    (goto-char position)))

(defun add-to-path (&rest things)
  (cond ((eql system-type 'windows-nt)
         (setenv "PATH" (concat (mapconcat (lambda (a) (replace-regexp-in-string "/" "\\\\" a)) things ";")
                                ";" (getenv "PATH"))))
        (t
         (setenv "PATH" (concat (mapconcat 'identity things ":")
                                ":" (getenv "PATH")))))
  (setq exec-path (append exec-path things)))

(defun kill-dired-buffers ()
  (interactive)
  (mapc (lambda (buffer) 
          (when (eq 'dired-mode (buffer-local-value 'major-mode buffer)) 
            (kill-buffer buffer))) 
        (buffer-list)))
