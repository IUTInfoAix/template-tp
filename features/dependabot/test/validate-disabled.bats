#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-dependabot : .github/dependabot.yml absent" {
    [ ! -f .github/dependabot.yml ]
}
