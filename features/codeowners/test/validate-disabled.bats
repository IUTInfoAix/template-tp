#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-codeowners : .github/CODEOWNERS absent" {
    [ ! -f .github/CODEOWNERS ]
}
