#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-maven-ci : .github/workflows/maven.yml absent" {
    [ ! -f .github/workflows/maven.yml ]
}
