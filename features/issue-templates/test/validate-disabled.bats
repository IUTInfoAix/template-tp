#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-issue-templates : .github/ISSUE_TEMPLATE/ entièrement absent" {
    [ ! -d .github/ISSUE_TEMPLATE ]
}
