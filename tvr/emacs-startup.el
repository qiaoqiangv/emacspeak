;;{{{ Emacs initialization file for Raman:
;;; $Id: emacs-startup.el 7753 2012-05-06 22:43:52Z tv.raman.tv $
;;; Segre March 22 1991
;;; July 15, 2001 finally cutting over to custom.
;;; August 12, 2007: Cleaned up for Emacs 22
;;}}}
;;{{{ personal lib

(defvar emacs-private-library
  (expand-file-name "~/.elisp")
  "Private personalization directory. ")
(defvar emacs-personal-library
  (expand-file-name "~/emacs/lisp/site-lisp")
  "Directory where we keep personal libraries")

;;}}}
;;{{{ helper functions:

(defmacro csetq (variable value)
  `(funcall (or (get ',variable 'custom-set) 'set-default) ',variable ,value))
;;; Usage:
(csetq tool-bar-mode nil)
(csetq menu-bar-mode nil)

(defsubst augment-load-path (path &optional library whence at-end)
  "add directory to load path.
Path is resolved relative to `whence' which defaults to emacs-personal-library."
  (interactive "Denter directory name: ")
  (declare (special emacs-personal-library))
  (unless (and library (locate-library library))
    (add-to-list
     'load-path
     (expand-file-name
      path
      (or
       whence
       (and (boundp 'emacs-personal-library) emacs-personal-library)))
     at-end))
  (when library (locate-library library)))

(defsubst augment-auto-mode-alist (ext mode)
  "Add to auto-mode-alist."
  (declare (special auto-mode-alist))
  (setq auto-mode-alist
        (cons
         (cons ext mode)
         auto-mode-alist)))
(defsubst load-library-if-available (lib)
  "Load a library only if it is around"
  (let ((emacspeak-speak-messages nil))
    (condition-case nil
        (cond
         ((locate-library lib)
          (load-library lib)
          (message "Loaded %s" lib)
          t)
         (t (message "Could not locate library %s" lib)
            nil))
      (error (message
              "Error loading %s"
              lib)))))

;;}}}
;;{{{ customize custom

(declare (special custom-file))
(setq custom-file (expand-file-name "~/.customize-emacs"))

(setq message-log-max 1024)

;;}}}
(defun start-up-my-emacs()
  "Start up emacs for me. "
  (declare (special emacs-personal-library emacs-private-library))
  (let ((gc-cons-threshold 8000000)
        (debug-on-quit t)
        (debug-on-error t))
    (menu-bar-mode -1)
    (tool-bar-mode -1)
    (scroll-bar-mode -1)
    (fringe-mode 1)
    (setq outline-minor-mode-prefix "\C-x@h")
    (when (file-exists-p  emacs-private-library)
      (augment-load-path emacs-private-library ))
    (when (file-exists-p  emacs-personal-library)
      (augment-load-path emacs-personal-library))
    ;;{{{ Load and customize emacspeak

    (unless (featurep 'emacspeak)
      (load-file (expand-file-name "~/emacs/lisp/emacspeak/lisp/emacspeak-setup.el")))
    (when (featurep 'emacspeak)
      (emacspeak-toggle-auditory-icons t)
      (emacspeak-sounds-select-theme "3d/")
      (emacspeak-tts-startup-hook))

    ;;}}}
    ;;{{{  set up terminal codes and global keys

    (mapc #'load-library-if-available
          '("console" "screen"))
    (when (eq window-system 'x)
      (load-library-if-available "x"))

    (loop for  key in
          '(
            ([f3] bury-buffer)
            ([f4] emacspeak-kill-buffer-quietly)
            ([f5] emacspeak-pianobar)
            ([pause] dtk-stop)
            ("\M--" undo)
            ([delete]dtk-toggle-punctuation-mode)
            ( [f8]emacspeak-remote-quick-connect-to-server)
            ([f11]shell)
            ([f12]vm)
            ( "\C-xc"compile)
            (  "\C-x%"comment-region)
            ( "\M-r"replace-string)
            ( "\M-e"end-of-word)
            ( "\M-\C-j"imenu)
            ( "\M-\C-c"calendar))
          do
          (global-set-key (first key) (second key)))
;;; Smarten up ctl-x-map
(define-key ctl-x-map "\C-n" 'forward-page)
(define-key ctl-x-map "\C-p" 'backward-page)

    ;;}}}
    ;;{{{  initial stuff

    (require 'dired-x)
    (require 'dired-aux)

    (put 'upcase-region 'disabled nil)
    (put 'downcase-region 'disabled nil)
    (put 'narrow-to-region 'disabled nil)
    (put 'eval-expression 'disabled nil)

    (dynamic-completion-mode)

    ;;}}}
    ;;{{{  different mode settings

;;; Mode hooks.

    (eval-after-load "shell"
      '(progn
         (when (locate-library "bash-completion")
           (require 'bash-completion)
(bash-completion-setup))
         (define-key shell-mode-map "\C-cr" 'comint-redirect-send-command)
         (define-key shell-mode-map "\C-ch"
           'emacspeak-wizards-refresh-shell-history)))

    ;;}}}
    ;;{{{ Prepare needed libraries

    (package-initialize)
    (mapc
     #'load-library-if-available
     '(
;;; personal functions and advice
       "my-functions"
;;; Mail readers:
       "vm-prepare" "gm-smtp" "gnus-prepare" "bbdb-prepare"
       "mspools-prepare" "sigbegone"
;;; Web Browsers:
       "w3-prepare"
       "auctex-prepare" "nxml-prepare" "folding-prepare"
       "elfeed-prepare"
       "calc-prepare"
       "hydra-prepare"
       "tcl-prepare"
       "slime-prepare" "company-prepare"
                                        ; jde and ecb will pull in cedet.
                                        ;"jde-prepare" "ecb-prepare"
       "org-prepare"
       "erc-prepare" "jabber-prepare" "twittering-prepare"
       "tramp-prepare" "fff-prepare" "fap-prepare"
       "emms-prepare"
       "iplayer-prepare"
"auto-correct-setup"
"color-theme-prepare"
       "local"
       "emacspeak-dbus"))

    ;;}}}
    ))                                  ; end defun
;;{{{  start it up

(add-hook
 #'after-init-hook
 #'(lambda ()
     (emacspeak-tts-startup-hook)
     (bbdb-insinuate-vm)
     (server-start)
     (shell)
     (calendar)
     (load-library "emacspeak-m-player")
     (initialize-completions)
     (shell-command "aplay ~/cues/highbells.au")
     (tooltip-mode -1)
     (setq frame-title-format '(multiple-frames "%b" ( "Emacs")))
     (message "Successfully initialized Emacs")))
(start-up-my-emacs)
(when (file-exists-p custom-file) (load-file custom-file))
(setq warning-suppress-types nil)

;;}}}
(provide 'emacs-startup)
;;{{{  emacs local variables
;;;local variables:
;;;folded-file: t
;;;end:
;;}}}
