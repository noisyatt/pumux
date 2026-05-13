# Pi Session Context API Proposal for pumux

## Goal

pumux wants to restore a user workspace after app restart or machine reboot by recreating panes and relaunching the correct Pi session. Pi should expose stable session metadata so pumux does not parse Pi internals or session files directly.

The target restore command is deterministic:

```sh
cd <cwd> && pi --session <session_id>
```

`pi --resume` / `pi -r` should remain a manual fallback, not the primary restore path.

## Non-goals

- Do not expose OAuth/API tokens or raw credential file contents.
- Do not require pumux to understand Pi session file formats.
- Do not require HTTP networking. Local CLI JSON and/or Unix socket is enough.
- Do not promise live process survival across reboot; this is recreate-and-resume metadata.

## Recommended transport layers

### 1. Stable CLI JSON API (required)

pumux can call this from Swift using `Process` and parse stdout JSON.

```sh
pi session current --json
pi session list --json
pi session inspect --pid <pid> --json
pi session inspect --tty <tty> --json
pi session inspect --tmux-pane <pane_id> --json
pi session inspect --session <session_id> --json
```

Recommended behavior:

- Exit `0` with JSON object/array on success.
- Exit `2` with JSON error when no matching session is found.
- Exit nonzero with JSON error on other failures.
- Never print human UI text to stdout when `--json` is set.

### 2. Durable local registry (required implementation detail)

Pi updates a registry while running and on relevant state changes:

```text
~/.pi/agent/session-registry.json
```

This registry is Pi-owned. pumux should prefer the CLI API, but the registry enables CLI lookup to be fast and stable.

### 3. Optional Unix socket event stream (nice-to-have)

For live badge/status updates without polling:

```text
~/.pi/agent/session-context.sock
```

JSON-RPC or newline-delimited JSON is fine. Keep CLI JSON as the compatibility contract.

### 4. tmux pane options (strongly recommended)

When Pi is running inside tmux, Pi should set pane-local tmux options so terminal apps can discover metadata without process-tree heuristics:

```sh
tmux set-option -p @pumux_pi_session_id '<session_id>'
tmux set-option -p @pumux_pi_restore_command 'cd <cwd> && pi --session <session_id>'
tmux set-option -p @pumux_pi_cwd '<cwd>'
tmux set-option -p @pumux_pi_account_label '<safe_account_label>'
tmux set-option -p @pumux_pi_model '<provider/model>'
```

pumux can read them via:

```sh
tmux display-message -p -t <pane_id> '#{@pumux_pi_session_id}|#{@pumux_pi_restore_command}|#{@pumux_pi_account_label}|#{@pumux_pi_model}'
```

## Core schema

### `PiSessionContext`

```json
{
  "schema_version": 1,
  "session_id": "7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
  "session_file": "/Users/daniel/.pi/agent/sessions/pumux/7c6d9b08.jsonl",
  "cwd": "/Users/daniel/projects/pumux",
  "project_root": "/Users/daniel/projects/pumux",
  "display_name": "pumux mosh tmux menu",
  "started_at": "2026-05-12T10:12:30Z",
  "last_active_at": "2026-05-12T10:45:11Z",
  "process": {
    "pid": 12345,
    "ppid": 12000,
    "tty": "/dev/ttys012",
    "argv": ["pi", "--model", "anthropic/claude-opus-4-7[1m]"]
  },
  "tmux": {
    "present": true,
    "session": "pumux",
    "window": "1",
    "pane": "%42",
    "pane_tty": "/dev/ttys012"
  },
  "model": {
    "provider": "anthropic",
    "model_id": "claude-opus-4-7[1m]",
    "thinking": "xhigh"
  },
  "account": {
    "label": "anthropic-main",
    "provider_alias": "anthropic",
    "credential_kind": "oauth_file"
  },
  "restore": {
    "cwd": "/Users/daniel/projects/pumux",
    "command": "pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
    "shell_command": "cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
    "preferred": true
  },
  "state": {
    "status": "active",
    "last_user_message_at": "2026-05-12T10:41:00Z",
    "last_assistant_message_at": "2026-05-12T10:45:11Z",
    "compacted": false
  }
}
```

Field notes:

- `session_id`: canonical stable identifier accepted by `pi --session <id>`.
- `session_file`: okay to expose path, but pumux should not parse it.
- `account.label`: safe display label only. Never include tokens.
- `restore.shell_command`: convenience string for terminal restoration.
- `tmux.pane`: should match tmux `%pane_id` if present.

## CLI examples

### Current session

```sh
pi session current --json
```

Response:

```json
{
  "ok": true,
  "session": { "schema_version": 1, "session_id": "...", "cwd": "..." }
}
```

### Inspect by pid

```sh
pi session inspect --pid 12345 --json
```

Response:

```json
{
  "ok": true,
  "match": "pid",
  "session": {
    "schema_version": 1,
    "session_id": "7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
    "cwd": "/Users/daniel/projects/pumux",
    "restore": {
      "shell_command": "cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332"
    }
  }
}
```

### Inspect by tmux pane

```sh
pi session inspect --tmux-pane %42 --json
```

Response:

```json
{
  "ok": true,
  "match": "tmux-pane",
  "session": { "schema_version": 1, "session_id": "..." }
}
```

### List recent sessions for cwd

```sh
pi session list --cwd /Users/daniel/projects/pumux --limit 5 --json
```

Response:

```json
{
  "ok": true,
  "sessions": [
    {
      "schema_version": 1,
      "session_id": "7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
      "cwd": "/Users/daniel/projects/pumux",
      "last_active_at": "2026-05-12T10:45:11Z",
      "restore": {
        "shell_command": "cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332"
      }
    }
  ]
}
```

### Error response

```json
{
  "ok": false,
  "error": {
    "code": "not_found",
    "message": "No Pi session matched pid 12345"
  }
}
```

## Registry file shape

Pi can maintain this atomically via write-temp-then-rename:

```json
{
  "schema_version": 1,
  "updated_at": "2026-05-12T10:45:11Z",
  "sessions": [
    {
      "session_id": "7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
      "session_file": "/Users/daniel/.pi/agent/sessions/pumux/7c6d9b08.jsonl",
      "cwd": "/Users/daniel/projects/pumux",
      "project_root": "/Users/daniel/projects/pumux",
      "last_active_at": "2026-05-12T10:45:11Z",
      "process": { "pid": 12345, "tty": "/dev/ttys012" },
      "tmux": { "present": true, "pane": "%42", "pane_tty": "/dev/ttys012" },
      "model": { "provider": "anthropic", "model_id": "claude-opus-4-7[1m]" },
      "account": { "label": "anthropic-main", "provider_alias": "anthropic" },
      "restore": {
        "cwd": "/Users/daniel/projects/pumux",
        "command": "pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
        "shell_command": "cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332"
      },
      "status": "active"
    }
  ]
}
```

Recommended retention:

- Keep active sessions.
- Keep recent inactive sessions for at least 30 days or the existing Pi session retention period.
- Mark process as inactive if pid no longer exists, but keep restore metadata.

## Live event stream, optional

If Pi provides a Unix socket, newline-delimited JSON events are enough:

```json
{"type":"pi.session.started","session_id":"...","cwd":"/Users/daniel/projects/pumux","pid":12345}
{"type":"pi.session.updated","session_id":"...","last_active_at":"2026-05-12T10:45:11Z","model":{"provider":"anthropic","model_id":"claude-opus-4-7[1m]"}}
{"type":"pi.session.ended","session_id":"...","pid":12345,"ended_at":"2026-05-12T11:00:00Z"}
```

pumux can use this for live badges, but should not require it for restore.

## pumux consumption flow

### While saving a workspace/session profile

1. For each terminal panel, detect whether the active process tree includes `pi`.
2. If terminal is inside tmux, read tmux pane options first.
3. Otherwise call:

```sh
pi session inspect --pid <foreground_or_child_pid> --json
```

4. If pid lookup fails, try tty:

```sh
pi session inspect --tty /dev/ttys012 --json
```

5. Store only the stable restore subset in pumux profile:

```json
{
  "kind": "pi",
  "cwd": "/Users/daniel/projects/pumux",
  "sessionId": "7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
  "restoreCommand": "pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
  "restoreShellCommand": "cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332",
  "provider": "anthropic",
  "model": "claude-opus-4-7[1m]",
  "accountLabel": "anthropic-main",
  "lastActiveAt": "2026-05-12T10:45:11Z"
}
```

### While restoring a workspace/session profile

1. Recreate tmux/session/pane or terminal panel with saved cwd.
2. If `kind == "pi"`, launch:

```sh
cd /Users/daniel/projects/pumux && pi --session 7c6d9b08-5fd0-4a2a-b4f7-fc1dd6a2b332
```

3. If `pi --session` fails because the session is gone, fallback to:

```sh
cd /Users/daniel/projects/pumux && pi --continue
```

4. If that also fails, open a normal shell in the cwd and show a non-blocking restore warning.

## Security and privacy

- Safe to expose:
  - provider id / provider alias
  - model id
  - user-defined account label
  - credential kind, e.g. `oauth_file`
  - credential file path only if already part of Pi settings and not sensitive
- Never expose:
  - API keys
  - OAuth tokens
  - refresh tokens
  - raw auth JSON contents
  - prompt/message contents unless a separate explicit API is added

## Minimum viable implementation

For Pi maintainers, MVP can be just:

```sh
pi session current --json
pi session inspect --pid <pid> --json
pi session inspect --tty <tty> --json
pi session list --cwd <cwd> --json
```

Plus these fields:

```json
{
  "session_id": "...",
  "cwd": "...",
  "project_root": "...",
  "last_active_at": "...",
  "process": { "pid": 12345, "tty": "/dev/ttys012" },
  "model": { "provider": "anthropic", "model_id": "claude-opus-4-7[1m]" },
  "account": { "label": "anthropic-main" },
  "restore": { "shell_command": "cd ... && pi --session ..." }
}
```

That is enough for pumux to save and restore Pi panes reliably.
