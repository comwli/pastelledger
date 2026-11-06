#!/usr/bin/env bash
# 매 사용자 메시지마다 전역 절차 규칙 묶음을 컨텍스트로 주입
f="$HOME/.claude/rules/procedure-rules.md"
[ -f "$f" ] || exit 0
cat "$f"
exit 0
