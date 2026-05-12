---
parent: 20260512-f7fde755-pumux-tmux-mosh-menu-split.md
handoff: f7fde755-b954-4698-b43c-de79b4296a57
alias: pumux-tmux-mosh-menu-split-planning
project: pumux
doc_type: worklog-sidecar
---

## Tags
pumux, cmux, tmux, mosh, menu-split, retry, upstream-merge, v0.64.4, bonsplit, ssh-config, zsh-alias

## Keyword Points

### 대상세션
- 2026-05-12 pumux 세션: upstream v0.64.4 merge + remote tmux alias resolver 1차 구현 + 메뉴 분리 설계로 마무리.

### 컨텍스트
- main 최신 두 커밋: f028121bc Merge upstream cmux v0.64.4 into pumux, 98ec7bde3 Restore remote tmux aliases.
- vendor/bonsplit submodule은 local custom tab color 2 커밋 위에 stable f65eccb 머지 (`4cc7b9a` push) 형태.
- pumux.app은 `com.cmuxterm.app.debug.pumux` 번들 ID로 `/Applications/pumux.app`에 설치되어 있음.
- 사용자 zsh 함수: `mt`는 mosh attach, `mtl`은 ssh `tmux ls`. `t`/`tl`은 로컬 동등물.

### 지시사항
- 다음 세션은 메뉴를 TMUX/MOSH TMUX 둘로 쪼개고 mosh 쪽은 5회 retry + 로딩 중 disable 처리.
- 세션 저장 시 attach 명령을 명시 저장. canonical 형식: `mosh '<host>' -- tmux new-session -A -s '<session>'`.
- 기존 title-based 추론은 fallback 정도로만 유지 검토.
- Pi 계정 라벨 reporter 트랙은 별도 handoff.

### 검색별칭
- "tmux mosh 메뉴 분리", "mtl 자동 복원 안됨", "ssh config Host alias pumux", "mosh tmux 5회 retry"
- 관련 파일: Sources/cmuxApp.swift, Sources/AppDelegate.swift, Sources/TabManager.swift, Sources/Workspace.swift
- 관련 커밋: 98ec7bde3, f028121bc

## 수정기록
- 2026-05-12 f7fde755 — worklog 생성 + handoff 연결
