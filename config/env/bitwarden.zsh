# Bitwarden CLI helpers — on-demand env loading from the vault.
#
# Convention: each service has a vault item named `env/<service>` with custom
# fields whose names match env-var names (e.g. CLOUDFLARE_API_TOKEN).
#
#   bw-unlock         unlock vault, cache session key in macOS Keychain
#   bw-lock           clear cached session and lock vault
#   bw-env <svc>      export all fields of env/<svc> into current shell
#   bw-env-list       list known env/* items

BW_KEYCHAIN_SERVICE="bw-session"
BW_KEYCHAIN_ACCOUNT="$USER"

_bw_session_get() {
  security find-generic-password -s "$BW_KEYCHAIN_SERVICE" -a "$BW_KEYCHAIN_ACCOUNT" -w 2>/dev/null
}

_bw_session_set() {
  security delete-generic-password -s "$BW_KEYCHAIN_SERVICE" -a "$BW_KEYCHAIN_ACCOUNT" >/dev/null 2>&1
  security add-generic-password -s "$BW_KEYCHAIN_SERVICE" -a "$BW_KEYCHAIN_ACCOUNT" -w "$1" -U
}

_bw_session_clear() {
  security delete-generic-password -s "$BW_KEYCHAIN_SERVICE" -a "$BW_KEYCHAIN_ACCOUNT" >/dev/null 2>&1
}

_bw_ensure_session() {
  local session bw_state
  session=$(_bw_session_get)
  if [[ -n "$session" ]]; then
    bw_state=$(BW_SESSION="$session" bw status 2>/dev/null | bw_json_status)
    if [[ "$bw_state" == "unlocked" ]]; then
      export BW_SESSION="$session"
      return 0
    fi
  fi
  bw-unlock
}

bw_json_status() {
  python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' 2>/dev/null
}

bw-unlock() {
  command -v bw >/dev/null || {
    echo "bw not installed"
    return 1
  }
  local bw_state
  bw_state=$(bw status 2>/dev/null | bw_json_status)
  if [[ "$bw_state" == "unauthenticated" ]]; then
    echo "Not logged in. Run: bw login"
    return 1
  fi
  local session
  if ! session=$(bw unlock --raw); then
    _bw_session_clear
    unset BW_SESSION
    bw_state=$(bw status 2>/dev/null | bw_json_status)
    if [[ "$bw_state" == "unauthenticated" ]]; then
      echo "bw unlock failed and the account is now logged out (expired refresh token)."
      echo "Run: bw login   # add 'bw config server <url>' first if you are not on the US cloud"
    else
      echo "bw unlock failed (state: ${bw_state:-unknown})"
    fi
    return 1
  fi
  _bw_session_set "$session"
  export BW_SESSION="$session"
  echo "bw unlocked, session cached in Keychain ($BW_KEYCHAIN_SERVICE)"
}

bw-lock() {
  bw lock >/dev/null 2>&1
  _bw_session_clear
  unset BW_SESSION
  echo "bw locked, cached session cleared"
}

bw-env() {
  local service="$1"
  if [[ -z "$service" ]]; then
    echo "usage: bw-env <service>   # loads env/<service> into current shell"
    return 2
  fi
  _bw_ensure_session || return 1
  local item="env/$service"
  local json
  json=$(bw get item "$item" 2>/dev/null)
  if [[ -z "$json" ]]; then
    bw sync >/dev/null 2>&1
    json=$(bw get item "$item" 2>/dev/null)
  fi
  if [[ -z "$json" ]]; then
    echo "bw: item '$item' not found (after sync)"
    return 1
  fi
  # NUL-delimited name/value pairs rather than generated shell: a field name is
  # vault-controlled, and `export "$name=$value"` can never evaluate it as code.
  local name value loaded=0
  while IFS= read -r -d '' name && IFS= read -r -d '' value; do
    export "$name=$value"
    loaded=$((loaded + 1))
  done < <(printf '%s' "$json" | python3 -c '
import json, re, sys
item = json.load(sys.stdin)
for f in item.get("fields") or []:
    name = f.get("name") or ""
    value = f.get("value")
    if not name or value is None:
        continue
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
        print(f"bw: skipping field {name!r}: not a usable variable name", file=sys.stderr)
        continue
    sys.stdout.write(f"{name}\0{value}\0")
')
  if ((loaded == 0)); then
    echo "bw: item '$item' has no usable custom fields"
    return 1
  fi
}

bw-env-list() {
  _bw_ensure_session || return 1
  bw list items --search "env/" 2>/dev/null | python3 -c '
import json, re, sys
usable = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
for it in json.load(sys.stdin):
    name = it.get("name","")
    if name.startswith("env/"):
        fields = [f.get("name") for f in (it.get("fields") or []) if f.get("name")]
        # Mark what bw-env would refuse, so the listing and the loader agree.
        shown = [f if usable.fullmatch(f) else f"{f} (skipped)" for f in fields]
        joined = ", ".join(shown) if shown else "(no fields)"
        print(f"{name}: {joined}")
'
}
