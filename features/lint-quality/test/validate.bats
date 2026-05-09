#!/usr/bin/env bats
# Tests Bats idiomatiques de la feature lint-quality.
# Le TP a été généré dans $TP_DIR par la CI (ou par run-tests.sh) AVANT
# que ce fichier ne soit appelé.

setup() {
    cd "$TP_DIR"
}

@test "feature lint-quality : pom.xml contient le plugin maven-pmd-plugin" {
    grep -q "maven-pmd-plugin" pom.xml
}

@test "feature lint-quality : pom.xml contient le profil quality-gate" {
    grep -q "<id>quality-gate</id>" pom.xml
}

@test "feature lint-quality : pmd-ruleset.xml est présent à la racine" {
    [ -f pmd-ruleset.xml ]
}

@test "feature lint-quality : scripts/lint-doc-coherence.sh est présent et exécutable" {
    [ -x scripts/lint-doc-coherence.sh ]
}

@test "feature lint-quality : .github/workflows/lint.yml est présent" {
    [ -f .github/workflows/lint.yml ]
}

@test "feature lint-quality : ./mvnw pmd:check passe sur le TP fraîchement généré (idiomatique)" {
    # IDIOMATIC : on lance vraiment le plugin Maven, pas une vérif de forme.
    # Sur un TP minimal (App.java + AppTest.java), aucune violation attendue.
    run ./mvnw -B -q -ntp pmd:check
    [ "$status" -eq 0 ]
}

@test "feature lint-quality : ./mvnw -Pquality-gate verify passe (failOnViolation=true)" {
    # IDIOMATIC : le profil enseignant doit aussi passer sur un TP minimal.
    run ./mvnw -B -q -ntp -Pquality-gate verify
    [ "$status" -eq 0 ]
}
