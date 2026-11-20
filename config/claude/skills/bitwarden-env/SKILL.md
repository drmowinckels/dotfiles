---
name: bitwarden-env
description: How env secrets (API tokens, keys) are stored in Bitwarden and loaded into the shell on demand. Use when a task needs a secret/env var, when a command fails for a missing token, or when adding secrets for a new service. Never hardcode secrets — pull them from the vault.
---

# bitwarden-env

Secrets live in the Bitwarden vault, not in dotfiles or `.env` files. Each service has one vault
item, and its fields are exported into the current shell on demand. Helpers are defined in
`config/env/bitwarden.zsh` and sourced from `zshrc`.

## Vault convention

- One item per service, named `env/<service>` (e.g. `env/cloudflare`, `env/openai`).
- Each **custom field** name is an env-var name; its value is the secret
  (e.g. field `CLOUDFLARE_API_TOKEN` → `export CLOUDFLARE_API_TOKEN=…`).
- Add a secret for a new service by creating/editing the `env/<service>` item and adding fields —
  no code change needed. The loader picks up any field whose name is non-empty.

## Commands

- `bw-unlock` — unlock the vault, cache the session key in the macOS Keychain (`bw-session` / `$USER`).
- `bw-lock` — lock the vault and clear the cached session.
- `bw-env <service>` — export every field of `env/<service>` into the current shell. Auto-unlocks
  (prompts for the master password) if no valid cached session, and `bw sync`s once if the item
  isn't found locally.
- `bw-env-list` — list all `env/*` items and their field names.

## How to use it

- When a task needs a token, load it first: `bw-env <service>`, then run the command in the same shell.
  Don't ask the user to paste a secret and don't read it from disk.
- If a command fails on a missing env var, check `bw-env-list` for the right service, then `bw-env` it.
- The session is cached in the Keychain, so `bw-unlock` is only needed once per vault-lock cycle;
  `bw-env` handles unlocking transparently otherwise.

## Guardrails

- Never echo, log, or commit a secret value. `bw-env` exports into the shell — it never prints values.
- Never hardcode a token in a script, dotfile, or `.env`; reference the env var and load it via `bw-env`.
- Prerequisites: `bw login` must have been run once (the helpers detect `unauthenticated` and tell you).
- The unlock prompt and Keychain access are interactive/macOS-specific — if you need a secret loaded,
  ask the user to run `bw-env <service>` in their session rather than trying to unlock non-interactively.
