#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-generate-student : .github/workflows/generate-student.yml absent" {
    [ ! -f .github/workflows/generate-student.yml ]
}

@test "no-generate-student : scripts/generate-student.sh absent" {
    [ ! -f scripts/generate-student.sh ]
}
