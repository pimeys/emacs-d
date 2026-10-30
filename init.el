;;; init.el --- -*- lexical-binding: t; -*-

;;; Packages ------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)

(require 'use-package)                  ; bundled since Emacs 29
(setq use-package-always-ensure t)      ; :ensure is implicit for every use-package
(setq use-package-expand-minimally t)

;;; Files ---------------------------------------------------------------

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :noerror)

;; Keep backups and auto-saves out of the working tree.
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups" user-emacs-directory))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save/" user-emacs-directory) t)))
(setq backup-by-copying t
      version-control t
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2)

(setq-default indent-tabs-mode nil
              sentence-end-double-space nil)

;;; Editing behaviour ---------------------------------------------------

(delete-selection-mode 1)
(show-paren-mode 1)
(column-number-mode 1)
(global-auto-revert-mode 1)             ; follow files changed by jj/git/tools
(setq use-short-answers t)              ; y/n instead of yes/no
(setq confirm-kill-processes nil)

;;; Appearance ----------------------------------------------------------

;; Line numbers in every buffer's gutter, including terminals and the agent.
(global-display-line-numbers-mode 1)

;; Default theme. `doom-one' lives in `doom-themes' (MELPA).
(use-package doom-themes
  :config
  (load-theme 'doom-one t))

;; Ember (github.com/ember-theme/emacs) is not on MELPA yet, so `:vc'
;; clones it with package-vc. Built on `doom-themes'; ships `ember',
;; `ember-soft' and `ember-light', all available via `consult-theme'.
(use-package ember-theme
  :vc (:url "https://github.com/ember-theme/emacs")
  :config
  ;; The package does not add itself to `custom-theme-load-path' (its files
  ;; are written for Doom's loader), so point it at the installed copy.
  (add-to-list 'custom-theme-load-path
               (file-name-directory (locate-library "ember-theme"))))

;;; Mode line -----------------------------------------------------------

;; Doom's segmented modeline: evil state, buffer name, VC, LSP diagnostics,
;; flycheck/flymake counts, etc. Draws icons via `nerd-icons'; the Symbols
;; Nerd Font is installed, so no extra font setup.
(use-package doom-modeline
  :config
  (doom-modeline-mode 1))

;;; Completion ----------------------------------------------------------

;; Minibuffer completion: M-x, C-x C-f, switch-buffer.
(use-package vertico
  :config
  (vertico-mode 1))

;; Consult builds richer commands on top of the minibuffer (`consult-buffer'
;; sources, previews, async ripgrep/grep). It complements vertico rather
;; than replacing it: vertico renders the candidates, consult produces them.
(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x p b" . consult-project-buffer)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-s l"   . consult-line)
         ("M-s r"   . consult-ripgrep)))

;; Fuzzy matching for every minibuffer prompt (`M-x', buffers, files): input is
;; split on spaces, the parts match in any order, and `orderless-flex' allows
;; in-order subsequences — so `M-x insbuf' finds `insert-buffer'.  `basic'
;; stays as the fallback style.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion))))
  (orderless-matching-styles '(orderless-flex orderless-literal orderless-regexp)))

;; In-buffer popup for `completion-at-point' (eglot/rust-analyzer, ...).
(use-package corfu
  :custom
  (corfu-auto t)                       ; pop up while typing
  (corfu-cycle t)                      ; TAB wraps around the candidates
  :config
  (global-corfu-mode 1))

;;; Modal editing (Evil) ------------------------------------------------

(use-package evil
  :init
  (setq evil-want-integration t          ; bindings follow Emacs conventions
        evil-want-keybinding nil         ; leave mode keymaps to evil-collection
        evil-undo-system 'undo-redo)     ; built-in undo-redo, no undo-tree
  :config
  (evil-mode 1)
  ;; Doom-style leader on C-SPC, which no mode-local map claims, unlike SPC
  ;; (dired's `dired-next-line', help's page scrolling). A real C-SPC press
  ;; arrives as NUL, i.e. `C-@', so bind that event: (kbd "C-SPC") is the
  ;; unrelated `C-SPC' modifier event and never matches a real press.
  ;; C-SPC SPC opens `project-find-file'; C-SPC no longer sets the mark in
  ;; normal/visual/motion state, so use `m' to set a marker.
  (defvar my/leader-map (make-sparse-keymap)
    "Leader keymap, entered with C-SPC in evil normal/visual/motion state.")
  (keymap-set my/leader-map "SPC" #'project-find-file)
  (dolist (map (list evil-normal-state-map
                     evil-visual-state-map
                     evil-motion-state-map))
    (keymap-set map "C-@" my/leader-map)))

;; Vim-like keymaps for the rest of Emacs (dired, magit, help, ...).
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;;; Discoverability ------------------------------------------------------

;; which-key is bundled with Emacs 30+. After a prefix key (`C-x', `C-c a',
;; evil operators), it pops up the keys available under it. `C-h b' still
;; lists every binding in the current buffer, `C-h k' describes one key.
(use-package which-key
  :ensure nil
  :custom
  (which-key-idle-delay 0.3)
  :config
  (which-key-mode 1))

;;; Terminal -------------------------------------------------------------

;; ghostel renders with libghostty-vt (the Ghostty VT engine) through a
;; native module downloaded on first use; no Zig/cmake needed. `C-c t'
;; opens a shell (fish, via $SHELL). In alt-screen TUIs evil-ghostel
;; sends ESC to the app; `C-c C-r' toggles that routing.
(use-package ghostel
  :custom
  ;; Keep the downloaded module out of `elpa/': package upgrades can
  ;; delete that tree. `download' skips the first-use prompt.
  (ghostel-module-directory
   (expand-file-name "ghostel-module/" user-emacs-directory))
  (ghostel-module-auto-install 'download)
  :bind (("C-c t" . ghostel)))

(use-package evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

;;; Languages: Rust -----------------------------------------------------

;; rust-ts-mode and eglot are bundled with Emacs 29+, so `:ensure nil'.
;; The grammar itself is not bundled: install it once with
;;   M-x treesit-install-language-grammar RET rust RET
;; which drops libtree-sitter-rust.so into ~/.emacs.d/tree-sitter.
(require 'treesit)                     ; defines treesit-language-source-alist
(add-to-list 'treesit-language-source-alist
             '(rust "https://github.com/tree-sitter/tree-sitter-rust"))

(setq treesit-font-lock-level 4)       ; richest tree-sitter highlighting

;; Format with rustfmt on save.  rustfmt reading stdin assumes the 2015
;; edition, so pass the edition from the nearest Cargo.toml.
(defun my/rust-edition ()
  "Return the Rust edition that applies to the current buffer.
Walk up to the nearest Cargo.toml with an explicit `edition', which
covers both a member crate's own edition and `[workspace.package]'
inherited by `edition.workspace = true'.  Default to 2021."
  (let ((dir (and buffer-file-name
                  (file-name-directory (expand-file-name buffer-file-name))))
        edition)
    (while (and dir (not edition))
      (let ((manifest (expand-file-name "Cargo.toml" dir)))
        (when (file-readable-p manifest)
          (setq edition
                (with-temp-buffer
                  (insert-file-contents manifest)
                  (goto-char (point-min))
                  (when (re-search-forward
                         "^[ \t]*edition[ \t]*=[ \t]*\"\\([0-9]+\\)\"" nil t)
                    (match-string 1))))))
      (setq dir (let ((parent (file-name-directory (directory-file-name dir))))
                  (unless (equal parent dir) parent))))
    (or edition "2021")))

(defun my/rustfmt-buffer ()
  "Pipe the buffer through rustfmt, replacing the text on success.
Runs from `before-save-hook'.  Leaves the buffer untouched when
rustfmt is missing or rejects the text, as a half-typed edit is a
syntax error more often than not."
  (when (and (derived-mode-p 'rust-ts-mode)
             (not buffer-read-only)
             (executable-find "rustfmt"))
    (let ((formatted (generate-new-buffer " *rustfmt*"))
          (errors (make-temp-file "rustfmt-errors")))
      (unwind-protect
          (save-restriction
            (widen)
            (if (zerop (call-process-region (point-min) (point-max)
                                            "rustfmt" nil
                                            (list formatted errors) nil
                                            "--emit" "stdout"
                                            "--edition" (my/rust-edition)))
                (replace-region-contents (point-min) (point-max) formatted)
              (message "rustfmt: %s"
                       (with-temp-buffer
                         (insert-file-contents errors)
                         (car (split-string (buffer-string) "\n"))))))
        (kill-buffer formatted)
        (delete-file errors)))))

(defun my/rustfmt-on-save ()
  "Format the current buffer with rustfmt before saving."
  (add-hook 'before-save-hook #'my/rustfmt-buffer nil t))

(use-package rust-ts-mode
  :ensure nil
  :hook ((rust-ts-mode . eglot-ensure)       ; start rust-analyzer on first .rs file
         (rust-ts-mode . my/rustfmt-on-save)) ; rustfmt before every save
  :custom
  (rust-ts-mode-indent-offset 4))

(use-package eglot
  :ensure nil
  :hook (eglot-managed-mode . eglot-inlay-hints-mode)
  :init
  ;; rust-analyzer annotates every inferred binding and every step of a method
  ;; chain with its type.  Keep eglot's inlay hints for the useful parts
  ;; (parameter names, closing-brace labels) but make the server stop sending
  ;; the type hints, which bury the code.
  (setq-default eglot-workspace-configuration
                '(:rust-analyzer
                  (:inlayHints
                   (:typeHints (:enable :json-false)
                    :chainingHints (:enable :json-false)))))
  :custom
  (eglot-autoshutdown t)               ; kill rust-analyzer with last buffer
  (eglot-events-buffer-size 0)         ; no *EGLOT events* chatter
  :config
  ;; Emacs 31's eglot binds no keys of its own; evil-collection-eglot adds
  ;; `gd'/`gD'.  `g .' applies the code action(s) at point (rust-analyzer
  ;; assists such as "Replace qualified path with use").
  (evil-collection-define-key 'normal 'eglot-mode-map "g." #'eglot-code-actions))

;;; Version control (Jujutsu) --------------------------------------------

;; Majutsu is not on MELPA, so `:vc' clones it with package-vc (Emacs 29+).
;; Dependencies pulled from the archives: magit, transient, consult, plz,
;; compat. `M-x majutsu' opens the log for the repository at `default-directory'.
(use-package majutsu
  :vc (:url "https://github.com/0WD0/majutsu"))

;; vc-jj is the VC backend for jj, which diff-hl and vc-dir need. GNU ELPA
;; still ships 0.5, whose `vc-jj--process-lines' signature no longer
;; matches what diff-hl calls, so pin upstream master. Its autoloads
;; register `JJ' ahead of `Git', which matters for colocated repos.
(use-package vc-jj
  :vc (:url "https://codeberg.org/emacs-jj-vc/vc-jj.el"
       :rev "17310449644cc527dfa6b8ca5320de4c33d1c7f3"))

;; Gutter marks (added/changed/deleted lines) in the fringe, computed by
;; the VC backend: for jj that is the working copy (@) against its parent
;; (@-), so they clear after `jj commit'/`jj new'. Refreshed on save,
;; revert and VC commands. `C-x v =' jumps to the diff at point, `C-x v n'
;; reverts a hunk, `C-x v [' / `C-x v ]' move between hunks.
(use-package diff-hl
  :demand t                             ; the global mode must run at startup
  :hook ((vc-dir-mode . turn-on-diff-hl-mode)
         (dired-mode . diff-hl-dired-mode-unless-remote)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (global-diff-hl-mode 1))

;;; Agent (omp over ACP) -------------------------------------------------

;; Exa's hosted MCP accepts a keyless connection, but `agent_run' and the
;; higher rate limits need the key. Keep the secret out of this file: read
;; `EXA_API_KEY' from the environment, else an auth-source entry such as
;;   machine mcp.exa.ai password <key>
;; in ~/.authinfo or ~/.authinfo.gpg.
(defun my/exa-api-key ()
  "Return the Exa API key, or nil for keyless hosted access."
  (or (getenv "EXA_API_KEY")
      (when (require 'auth-source nil t)
        (or (auth-source-pick-first-password :host "mcp.exa.ai")
            (auth-source-pick-first-password :host "api.exa.ai")))))

;; omp is an ACP server (`omp acp'); agent-shell ships a matching client
;; config, so sessions share omp's own credentials and session store.
(use-package agent-shell
  :custom
  ;; No picker: `M-x agent-shell' goes straight to omp.
  ;; Use `(preselect . omp)' instead if you want the picker with omp on top.
  (agent-shell-preferred-agent-config 'omp)
  ;; Approval prompts for tool calls are skipped entirely.
  (agent-shell-confirm-interrupt nil)
  ;; `omp acp' ignores on-disk MCP config (ACP sessions run with MCP
  ;; discovery disabled); the ACP client must declare servers instead.
  (agent-shell-mcp-servers
   ;; omp advertises mcpCapabilities.http, so Exa runs over its hosted
   ;; streamable-HTTP endpoint with no local node/npx process.
   '(((name . "exa")
      (type . "http")
      (url . "https://mcp.exa.ai/mcp")
      ;; Evaluated when a session starts; nil headers mean keyless access.
      (headers . (lambda ()
                   (when-let* ((key (my/exa-api-key)))
                     (list (list (cons 'name "x-api-key")
                                 (cons 'value key)))))))
     ;; Linear speaks OAuth; ACP can't carry credentials, but omp resolves
     ;; its URL-keyed stored credential automatically. Authorize once with
     ;; `/mcp reauth linear` (works in agent-shell on omp >= 18.13.3, or in
     ;; the `omp` TUI); the token lives in ~/.omp auth storage.
     ((name . "linear")
      (type . "http")
      (url . "https://mcp.linear.app/mcp"))))
  :config
  ;; Runs before the permission dialog; non-nil return means "already handled".
  (setq agent-shell-permission-responder-function
        #'agent-shell-permission-allow-always))

;; Per-project side window instead of a full-frame agent buffer. Not on
;; MELPA, so `:vc'. `C-c a s' toggles visibility, `C-c a f' moves focus
;; between the sidebar and the buffer you were editing.
(use-package agent-shell-sidebar
  :after agent-shell
  :vc (:url "https://github.com/cmacrae/agent-shell-sidebar")
  :custom
  ;; Skip the provider picker, same as the full-buffer `agent-shell'.
  (agent-shell-sidebar-default-config (agent-shell-omp-make-agent-config))
  :bind (("C-c a s" . agent-shell-sidebar-toggle)
         ("C-c a f" . agent-shell-sidebar-toggle-focus)))

;; Landing page for every omp session: triage queue, live sessions and
;; recently closed ones. Not on MELPA, so `:vc'. The last-reply summarizer
;; defaults to `claude -p' and falls back to the raw message tail when it is
;; not on PATH.
(use-package agent-shell-dashboard
  :after agent-shell
  :vc (:url "https://github.com/wandersoncferreira/agent-shell-dashboard")
  :bind (("C-c a D" . agent-shell-dashboard)))

;;; Agent notifications --------------------------------------------------

;; knockknock renders posframe popups. The multi-format icon embedding that
;; agent-shell needs (its LobeHub icons are PNG) is still an unmerged PR, so
;; pin the PR head; posframe/nerd-icons come from MELPA as dependencies.
(use-package knockknock
  :vc (:url "https://github.com/xenodium/knockknock"
       :rev "7a6ab46503554317b639a7333ec8046d7d181520"))

;; Notify when a turn finishes or a tool asks for permission while the
;; agent-shell buffer (or its viewport) is not visible. Covers sidebar and
;; full-buffer sessions, since both run `agent-shell-mode'.
(use-package agent-shell-knockknock
  :after (agent-shell knockknock)
  :vc (:url "https://github.com/xenodium/agent-shell-knockknock"
       :rev :newest)
  :hook (agent-shell-mode . agent-shell-knockknock-mode))

;;; Agent awareness ------------------------------------------------------

;; Persistent count of sessions waiting for input, rendered as `AS:n' in
;; `mode-line-misc-info' (doom-modeline has a misc-info segment).
(use-package agent-shell-attention
  :after agent-shell
  :demand t
  :bind (("C-c a j" . agent-shell-attention-jump)
         ("C-c a d" . agent-shell-attention-dashboard))
  :config
  (agent-shell-attention-mode 1))

;; Search, browse and resume agent-shell transcripts. They live in each
;; project's `.agent-shell/transcripts/' directory; the index is built from
;; these roots (local projects only -- remote transcripts need TRAMP).
(use-package agent-recall
  :after agent-shell
  :demand t
  :hook (agent-shell-mode . agent-recall-track-sessions)
  :bind (("C-c a r" . agent-recall-resume)
         ("C-c a /" . agent-recall-search)
         ("C-c a b" . agent-recall-browse))
  :config
  (setq agent-recall-search-paths
        (list (expand-file-name "~/code")
              (expand-file-name "~/Projects")
              (expand-file-name user-emacs-directory))
        ;; ripgrep + consult are installed, so searches get live filtering.
        agent-recall-search-function 'consult-ripgrep))

;;; Startup -------------------------------------------------------------

(setq initial-scratch-message
      (format ";; Emacs %s on %s. C-h t tutorial, C-h r manual.\n\n"
              emacs-version system-type))

;; Report startup duration and GC count once init is done.
;; Copied from daviwil/emacs-from-scratch.
(defun my/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'my/display-startup-time)

;;; Runtime performance -------------------------------------------------

;; Dial the GC threshold back down so collections happen more often but in
;; less time. Must stay at the end: everything above loaded under the big
;; threshold from early-init.el.
(setq gc-cons-threshold (* 2 1000 1000))
