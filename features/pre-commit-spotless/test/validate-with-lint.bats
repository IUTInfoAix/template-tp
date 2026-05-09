#!/usr/bin/env bats
# Test de composition : pre-commit-spotless + lint-quality.
# Vérifie que le bloc TEACHER-LINT est bien injecté dans le hook
# quand les 2 features cohabitent.

setup() { cd "$TP_DIR"; }

@test "spotless+lint : .githooks/pre-commit présent" {
    [ -x .githooks/pre-commit ]
}

@test "spotless+lint : bloc TEACHER-LINT injecté dans le hook" {
    grep -q "TEACHER-LINT\|scripts/lint-doc-coherence\|pmd:check" .githooks/pre-commit
}

@test "spotless+lint : hook référence pmd:check -Pquality-gate" {
    grep -q "Pquality-gate" .githooks/pre-commit
}

@test "spotless+lint : pas de placeholder Jinja résiduel" {
    ! grep -q "{{" .githooks/pre-commit
    ! grep -q "{%" .githooks/pre-commit
}
