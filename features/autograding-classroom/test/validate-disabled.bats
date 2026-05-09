#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-autograding : .github/workflows/classroom.yml absent" {
    [ ! -f .github/workflows/classroom.yml ]
}

@test "no-autograding : scripts/grade-test.sh absent" {
    [ ! -f scripts/grade-test.sh ]
}

@test "no-autograding : scripts/update-autograding.sh absent" {
    [ ! -f scripts/update-autograding.sh ]
}
