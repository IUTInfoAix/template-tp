#!/usr/bin/env bats
# Tests Bats : feature lint-quality DÉSACTIVÉE.
# Vérifie qu'aucun artefact PMD/lint ne fuit dans le TP généré.

setup() {
    cd "$TP_DIR"
}

@test "no-lint : pmd-ruleset.xml absent" {
    [ ! -f pmd-ruleset.xml ]
}

@test "no-lint : scripts/lint-doc-coherence.sh absent" {
    [ ! -f scripts/lint-doc-coherence.sh ]
}

@test "no-lint : .github/workflows/lint.yml absent" {
    [ ! -f .github/workflows/lint.yml ]
}

@test "no-lint : pom.xml ne contient PAS maven-pmd-plugin" {
    ! grep -q "maven-pmd-plugin" pom.xml
}

@test "no-lint : pom.xml ne contient PAS le profil quality-gate" {
    ! grep -q "<id>quality-gate</id>" pom.xml
}

@test "no-lint : ./mvnw test passe (le TP minimal compile et teste)" {
    run ./mvnw -B -q -ntp test
    [ "$status" -eq 0 ]
}
