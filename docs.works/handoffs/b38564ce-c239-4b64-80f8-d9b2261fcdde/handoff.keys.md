---
id: b38564ce-c239-4b64-80f8-d9b2261fcdde
parent: handoff.md
alias: pumux-pi-api-restore-upstream-0645
---

## Tags

pumux, handoff, pi-api-restore-upstream-0645, pi, session-registry, mosh-tmux, upstream-v0.64.5, pumux-pi-api-restore-upstream-0645

## Search card

- Resume: pumux main is at `v0.64.5` with Pi registry restore and MOSH TMUX implemented; next dogfood `Pi-Pumux` restart/auto-resume.
- Open work: verify actual restored tmux pane runs `pi --session 019e1b9f-3e22-722b-9075-b7715758ed23`; check MOSH TMUX UI and possible socket broken-pipe reproduction.
- Key paths: `Sources/Workspace.swift`, `Sources/VaultAgentProcessScanner.swift`, `Sources/AppDelegate.swift`, `docs.works/worklogs/20260514-b38564ce-pumux-pi-api-restore-upstream-0645.md`
- Instruction/memory updates: none
- Subagents/artifacts: `0cdc83f5-2827-43c0-bc13-5b76154ebdc7`, `docs.works/tmp/subagent-upstream-stable-check.md`
- User decisions: Pi registry is source of truth; pumux stores/uses restore metadata; upstream `v0.64.5` accepted.
- Search aliases: pi api pumux, Pi-Pumux restore, session-registry.json, MOSH TMUX mtl, upstream 0.64.5

## 수정기록

- 2026-05-14 b38564ce — handoff 생성
