#!/usr/bin/env bats
# Tests du core (fichiers toujours présents quelle que soit la composition).
# Génération via la fixture lint-quality (déjà existante, minimum vital).

setup() { cd "$TP_DIR"; }

@test "core : README.md présent à la racine du TP" {
    [ -f README.md ]
}

@test "core : README.md interpolé avec module.code et module.titre" {
    grep -q "R2.TEST - Test lint-quality" README.md
}

@test "core : README.md interpolé avec contact_email" {
    grep -q "mailto:test@example.org" README.md
}

@test "core : README.md interpolé avec org_github + titre_court (lien issues)" {
    grep -q "github.com/IUTInfoAix-RTEST/tp-test-lint/issues" README.md
}

@test "core : README.md sans placeholder Jinja résiduel" {
    ! grep -F "{{" README.md
    ! grep -F "{%" README.md
}

@test "core : README.md sans placeholder ancien template ({{TP_TITLE}}, {{TP_REPO_NAME}}, etc.)" {
    ! grep -F "TP_REPO_NAME" README.md
    ! grep -F "TP_TITLE" README.md
    ! grep -F "TP_EXERCISES" README.md
}
