# Emacs config and the live daemon

This directory is the user's Emacs configuration. Emacs runs as a **long-lived
daemon** (`emacs --fg-daemon`; verify with `pgrep -a emacs`), and the user
attaches frames with `emacsclient`. Agent sessions (`agent-shell`, omp) also
live inside that daemon.

## Config edits do not reach the running Emacs by themselves

Editing `init.el`, `early-init.el`, or any other file here only changes what a
*future* Emacs will read. The running daemon keeps its current definitions
forever, and restarting it destroys the user's buffers and agent sessions.

**Therefore every config change MUST also be applied to the running daemon with
`emacsclient` in the same turn, and verified there.** Do not stop at a file
edit, `check-parens`, or a batch `emacs -Q` run.

## Applying changes

Evaluate the changed form directly in the daemon (single-quote the Lisp so the
shell does not touch it):

```sh
emacsclient --eval '(setq-default some-variable value)'
emacsclient --eval '(use-package foo :config (foo-mode 1))'
```

For many forms, write them to a temporary `.el` file and load that instead of
fighting shell quoting:

```sh
emacsclient --eval '(load-file "/tmp/change.el")'
```

For broad edits you may reload the whole file:

```sh
emacsclient --eval '(load-file "~/.emacs.d/init.el")'
```

`load-file` re-runs the file; it does **not** undo deletions. If a form was
removed from the file, remove its live effects by hand (next section).

## Removals: keys, hooks, advice, packages

Deleting a `use-package` block or uninstalling a package changes nothing in the
running daemon. Purge it explicitly, in this order:

1. Stop its processes and kill its buffers.
2. Unbind its keys: `(global-unset-key (kbd "C-c x"))`.
3. Remove hooks and advice it installed:
   `(remove-hook 'some-hook #'pkg-fn)`,
   `(advice-remove 'some-command #'pkg-advice)`.
4. Unload its features: `(unload-feature 'pkg t)`.
5. If it is gone from the config, delete the installed package so
   `package-initialize` cannot resurrect its autoloads on the next start:
   `(package-delete (car (alist-get 'pkg package-alist)))`.
6. Remove leftover autoloads if unload did not (`fmakunbound` on symbols that
   are still `autoloadp`).

## Verify in the daemon

Always confirm the live state, not just the file, and report it:

```sh
emacsclient --eval '(prin1 (list :fboundp (fboundp (quote foo))
                                 :key (lookup-key global-map (kbd "C-c x"))
                                 :feature (featurep (quote foo))
                                 :hooks (memq (quote foo-fn) some-hook)))'
```

For removals, verify all of: `featurep`, `fboundp`/`commandp`, key lookup,
hook/advice membership, `package-alist`, `load-path`, process list, buffer list.

## Do not restart Emacs

Restarting the daemon kills the user's frames, buffers, unsaved state, and
running agent sessions. Treat a restart as destructive: only do it when the
user explicitly asks.

`emacsclient --eval` is the reliable route. The Emacs MCP socket
(`.local/cache/emacs-mcp-server.sock`, exposed as `xd://mcp__emacs_*` when
mounted) can disappear mid-session; fall back to `emacsclient`. Use
`emacsclient -c` / `-t` only when a visible frame is needed for verification.
