#!/usr/bin/env bats
# Tests Bats : feature autograding-classroom ACTIVÉE.
# Test idiomatique = lancer ./mvnw test, puis ./scripts/grade-test.sh
# sur une méthode existante (exit 0) et une méthode bidon (exit ≠ 0).

setup() { cd "$TP_DIR"; }

@test "autograding : .github/workflows/classroom.yml présent" {
    [ -f .github/workflows/classroom.yml ]
}

@test "autograding : YAML strict valide" {
    run python3 -c "import yaml; yaml.safe_load(open('.github/workflows/classroom.yml'))"
    [ "$status" -eq 0 ]
}

@test "autograding : marqueurs AUTOGRADING-BEGIN / END présents (régénérables par update-autograding.sh)" {
    grep -q "#@@@AUTOGRADING-BEGIN@@@" .github/workflows/classroom.yml
    grep -q "#@@@AUTOGRADING-END@@@" .github/workflows/classroom.yml
}

@test "autograding : scripts/grade-test.sh présent et exécutable" {
    [ -x scripts/grade-test.sh ]
}

@test "autograding : scripts/update-autograding.sh présent et exécutable" {
    [ -x scripts/update-autograding.sh ]
}

@test "autograding : Java 25 référencé (workflow non templated, version commune R202/R203)" {
    grep -q "Set up JDK 25" .github/workflows/classroom.yml
    grep -q "java-version: '25'" .github/workflows/classroom.yml
}

@test "autograding : référence aux actions IUTInfoAix-R202/autograding-* (infra partagée)" {
    grep -q "IUTInfoAix-R202/autograding-command-grader" .github/workflows/classroom.yml
    grep -q "IUTInfoAix-R202/autograding-grading-reporter" .github/workflows/classroom.yml
}

@test "autograding : pas de référence R203/template-tp-java résiduelle (rendu générique)" {
    ! grep -q "IUTInfoAix-R203/template-tp-java" .github/workflows/classroom.yml
}

@test "autograding : update-autograding.sh génère ./scripts/grade-test.sh (path corrigé)" {
    grep -q '"./scripts/grade-test.sh' scripts/update-autograding.sh
    ! grep -q '"./grade-test.sh ' scripts/update-autograding.sh
}

@test "autograding : grade-test.sh sur une méthode existante (idiomatique : mvnw test puis grade)" {
    # IDIOMATIC : on génère target/surefire-reports/ via un vrai mvnw test
    # puis on appelle grade-test.sh sur la méthode AppTest qui doit passer.
    ./mvnw -B -q -ntp test
    run ./scripts/grade-test.sh fr.univ_amu.iut.AppTest le_menu_affiche_le_titre_du_TP_et_le_repere_IUT
    [ "$status" -eq 0 ]
}

@test "autograding : grade-test.sh sur une méthode bidon échoue (idiomatique)" {
    # mvnw test déjà lancé par le test précédent (les fichiers surefire
    # sont sur disque). On grade une méthode inexistante : doit exit ≠ 0.
    [ -d target/surefire-reports ]
    run ./scripts/grade-test.sh fr.univ_amu.iut.AppTest methode_qui_existe_pas
    [ "$status" -ne 0 ]
}

@test "autograding : update-autograding.sh tourne sans crash sur un TP minimal (pas d'exercice)" {
    # Le TP minimal n'a pas de sous-paquets exerciceN. Le script doit
    # exit 0 (rien à régénérer) ou exit avec un message clair.
    run ./scripts/update-autograding.sh
    # Accepte exit 0 OU un échec contrôlé (message d'erreur clair).
    # On veut juste s'assurer que le script ne tombe pas en erreur de
    # syntaxe shell.
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
