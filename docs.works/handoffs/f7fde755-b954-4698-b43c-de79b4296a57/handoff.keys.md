---
id: f7fde755-b954-4698-b43c-de79b4296a57
parent: handoff.md
alias: pumux-tmux-mosh-menu-split-planning
---

## Tags

pumux, handoff, tmux, mosh, menu, retry, session-restore, ssh-config, zsh-alias, pumux-tmux-mosh-menu-split-planning

## Keyword Points

### 대상세션

- 다음 세션은 pumux 메뉴바를 TMUX / MOSH TMUX 두 메뉴로 쪼개고, mosh 세션 목록 fetch에 retry/disabled UX를 붙이고, 세션 저장이 명시적 attach 명령을 담도록 만든다.

### 컨텍스트

- 이번 세션 main 최신: 98ec7bde3 Restore remote tmux aliases
- 추가로 upstream cmux v0.64.4 (f028121bc) merge 완료, pumux.app /Applications 설치 완료
- Workspace.swift에 zsh alias 확장 + ssh config Host alias 기반 remote tmux 추론과 mosh canonical command 복원 추가됨
- 사용자가 “title 거꾸로 파싱” 단독 방향 기각, “목록 fetch + UI attach + 명시 저장”으로 전환 결정
- 메뉴 hookpoint: Sources/cmuxApp.swift line 545 Menu("tmux"), Sources/AppDelegate.swift line 2868 promptNewTmuxTab, line 2914 tmuxSessionNames
- 저장 hookpoint: SessionTerminalPanelSnapshot.tmuxStartCommand. canonical 명령을 attach 시 그대로 채우면 기존 복원 경로가 작동

### 지시사항

- TMUX 메뉴 = local `tmux list-sessions`. MOSH TMUX 메뉴 = remote `ssh <host> tmux list-sessions`.
- remote fetch는 비동기 + 최대 5회 retry. fetch 중 메뉴 disable + 진행 표시.
- attach 시 newManagedTmuxSurface의 mosh 변형 호출, snapshot에 canonical attach 명령 저장.
- 기존 title-based restore (`restorableRemoteTmuxStartCommand`)는 fallback only로 강등 검토.
- Pi 계정 라벨 reporter 작업은 별도 트랙으로 분리.

### 검색별칭

- “tmux mosh 메뉴 분리”, “mtl retry”, “mosh tmux 자동 attach”, “세션 프로필 복원 안 됨”, “mt 워크스페이스 다시 안 붙음”
- 관련 파일: Sources/cmuxApp.swift, Sources/AppDelegate.swift, Sources/TabManager.swift, Sources/Workspace.swift
- 관련 명령: tmux list-sessions, mosh, ssh, ./scripts/reload.sh --tag <tag> --name pumux

## 수정기록

- 2026-05-12 f7fde755 — handoff 생성 (코덱스/Pi)
