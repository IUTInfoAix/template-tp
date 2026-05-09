#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-spotless : .githooks/ entièrement absent" {
    [ ! -d .githooks ]
}

@test "no-spotless : pom.xml ne contient PAS spotless-maven-plugin" {
    ! grep -q "spotless-maven-plugin" pom.xml
}

@test "no-spotless : pom.xml ne contient PAS git-build-hook-maven-plugin" {
    ! grep -q "git-build-hook-maven-plugin" pom.xml
}
