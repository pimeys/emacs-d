;;; early-init.el --- pre-frame startup settings -*- lexical-binding: t; -*-

;; Runs before init.el and before the first GUI frame exists. Only put here
;; what must be true before that frame is drawn, otherwise it flickers.

;;; Startup performance --------------------------------------------------

;; Load with a large GC threshold so startup is not interrupted by garbage
;; collection. Handed back to a normal value at the end of init.el.
;; Copied from daviwil/emacs-from-scratch (init.el), moved here so the
;; package loading and init.el evaluation are covered as well.
(setq gc-cons-threshold (* 50 1000 1000))

(setq package-enable-at-startup nil)   ; init.el calls package-initialize
(setq inhibit-startup-screen t)

;; This is the PGTK build, so GTK already picks Wayland. No GDK_BACKEND needed.
;; Frame chrome and font must be set here to avoid a resize/repaint on frame 1.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(font . "Inconsolata Nerd Font Mono-13") default-frame-alist)
(push '(frame-resize-pixelwise . t) default-frame-alist)
