#!/usr/bin/env bats
# Tests du core (fichiers toujours présents quelle que soit la composition).
# Génération via la fixture lint-quality (déjà existante, minimum vital).

setup() { cd "$TP_DIR"; }

@test "core : README.md présent à la racine du TP" {
    [ -f README.md ]
}

@test "core : README.md interpolé avec module.code et module.titre" {
    grep -Fq "R2.TEST - Test lint-quality" README.md
}

@test "core : README.md interpolé avec contact_email" {
    grep -Fq "mailto:test@example.org" README.md
}

@test "core : README.md interpolé avec org_github + titre_court (lien issues)" {
    grep -Fq "github.com/IUTInfoAix-RTEST/tp-test-lint/issues" README.md
}

@test "core : README.md interpolé avec tp.classroom_link" {
    # Suite Copilot review PR #24 : un placeholder mal nommé (ex {{CLASSROOM_LINK}}
    # au lieu de {{ tp.classroom_link }}) ne déclenchait aucun test, l'URL
    # apparaissait vide et tout passait. On vérifie maintenant l'URL exacte
    # injectée par la fixture lint-quality (TESTLINT).
    grep -Fq "https://classroom.github.com/a/TESTLINT" README.md
}

@test "core : README.md interpolé avec module.classroom_org (vraie variable, pas '{org_github}-2026' hardcodé)" {
    # Fix Copilot review PR #24 + PR #25 : avant on hardcodait '-2026'.
    # Pour que ce test attrape vraiment la régression, la fixture utilise
    # une valeur de classroom_org volontairement DIFFÉRENTE de
    # {org_github}-2026 (cf. lint-quality/test/answers.yml). Ainsi un
    # hardcode '{{ module.org_github }}-2026' ne matcherait pas.
    # grep -Fq pour traiter la chaîne comme littérale (pas regex).
    grep -Fq "ClassroomOrg-Unique-2099" README.md
}

@test "core : README.md sans placeholder Jinja résiduel" {
    ! grep -F "{{" README.md
    ! grep -F "{%" README.md
}

@test "core : .idea/runConfigurations/Lancer_l_application.xml présent (config IntelliJ partagée)" {
    # Régression #23 : ancien R202/R203 posait cette run config qui aide
    # les étudiant·es IntelliJ à lancer l'app en un clic. Le .gitignore
    # whitelist .idea/runConfigurations/ pour qu'elle soit commitée.
    [ -f .idea/runConfigurations/Lancer_l_application.xml ]
}

@test "core : run config IntelliJ utilise compile + exec:java (sans javafx)" {
    grep -Fq -- '<option value="compile" />' .idea/runConfigurations/Lancer_l_application.xml
    grep -Fq -- '<option value="exec:java" />' .idea/runConfigurations/Lancer_l_application.xml
    ! grep -Fq -- '<option value="javafx:run" />' .idea/runConfigurations/Lancer_l_application.xml
}

@test "core : README.md sans placeholder ancien template (TP_*, CLASSROOM_LINK, YEAR)" {
    ! grep -F "TP_REPO_NAME" README.md
    ! grep -F "TP_TITLE" README.md
    ! grep -F "TP_EXERCISES" README.md
    ! grep -F "CLASSROOM_LINK" README.md
    ! grep -F "YEAR" README.md
}
