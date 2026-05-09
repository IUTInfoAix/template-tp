#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-ai-tutor : AGENTS.md absent" {
    [ ! -f AGENTS.md ]
}

@test "no-ai-tutor : .github/copilot-instructions.md absent" {
    [ ! -f .github/copilot-instructions.md ]
}
