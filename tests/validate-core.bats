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

@test "core : README.md interpolé avec tp.classroom_link" {
    # Suite Copilot review PR #24 : un placeholder mal nommé (ex {{CLASSROOM_LINK}}
    # au lieu de {{ tp.classroom_link }}) ne déclenchait aucun test, l'URL
    # apparaissait vide et tout passait. On vérifie maintenant l'URL exacte
    # injectée par la fixture lint-quality (TESTLINT).
    grep -q "https://classroom.github.com/a/TESTLINT" README.md
}

@test "core : README.md interpolé avec module.classroom_org (et pas org_github-2026)" {
    # Fix Copilot review PR #24 : avant on hardcodait '-2026'. Maintenant on
    # utilise classroom_org de la fixture (IUTInfoAix-RTEST-2026).
    grep -q "IUTInfoAix-RTEST-2026" README.md
}

@test "core : README.md sans placeholder Jinja résiduel" {
    ! grep -F "{{" README.md
    ! grep -F "{%" README.md
}

@test "core : README.md sans placeholder ancien template (TP_*, CLASSROOM_LINK, YEAR)" {
    ! grep -F "TP_REPO_NAME" README.md
    ! grep -F "TP_TITLE" README.md
    ! grep -F "TP_EXERCISES" README.md
    ! grep -F "CLASSROOM_LINK" README.md
    ! grep -F "YEAR" README.md
}
