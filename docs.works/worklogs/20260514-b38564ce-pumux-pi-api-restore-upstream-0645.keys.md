---
parent: 20260514-b38564ce-pumux-pi-api-restore-upstream-0645.md
handoff: b38564ce-c239-4b64-80f8-d9b2261fcdde
alias: pumux-pi-api-restore-upstream-0645
project: pumux
doc_type: worklog-sidecar
---

## Tags

pumux, cmux, pi, session-registry, restore, mosh-tmux, upstream-merge, v0.64.5, pumux-pi-api-restore-upstream-0645

## Search card

- Resume: pumux main is at upstream `v0.64.5` with MOSH TMUX menu + Pi session registry restore implemented; next verify actual app/reboot restore and small UI/socket issues.
- Open work: dogfood `Pi-Pumux` auto-resume (`tmuxStartCommand` + `pi --session`) and installed 0.64.5 MOSH TMUX menu attach.
- Key paths: `Sources/Workspace.swift`, `Sources/VaultAgentProcessScanner.swift`, `Sources/AppDelegate.swift`, `docs.works/tmp/subagent-upstream-stable-check.md`
- Instruction/memory updates: none; design note at `docs.works/design/20260512-pi-session-context-api-for-pumux.md`
- Subagents/artifacts: `0cdc83f5-2827-43c0-bc13-5b76154ebdc7`, `/Users/daniel/projects/pumux/docs.works/tmp/subagent-upstream-stable-check.md`
- User decisions: Pi owns session context API/registry; pumux consumes restore metadata; accept upstream stable `v0.64.5`.
- Search aliases: pi api pumux restore, Pi-Pumux auto resume, MOSH TMUX mtl, upstream 0.64.5 merge, session-registry.json

## 수정기록

- 2026-05-14 b38564ce — worklog 생성 + handoff 연결
