#!/usr/bin/env bats
# Tests Bats : feature generate-student ACTIVÉE.
# Test idiomatique = créer une fixture src/ avec les 3 marqueurs
# (--solution--, --student--, --solution-only--), git init + commit
# sur "solution", lancer ./scripts/generate-student.sh --apply,
# vérifier les transformations.

setup() { cd "$TP_DIR"; }

@test "generate-student : .github/workflows/generate-student.yml présent" {
    [ -f .github/workflows/generate-student.yml ]
}

@test "generate-student : YAML strict valide" {
    run python3 -c "import yaml; yaml.safe_load(open('.github/workflows/generate-student.yml'))"
    [ "$status" -eq 0 ]
}

@test "generate-student : workflow appelle ./scripts/generate-student.sh (path corrigé)" {
    grep -q "./scripts/generate-student.sh --apply ." .github/workflows/generate-student.yml
    ! grep -q "^[^/]*\./generate-student.sh --apply" .github/workflows/generate-student.yml
}

@test "generate-student : pas de référence R203/template-tp-java résiduelle" {
    ! grep -q "IUTInfoAix-R203/template-tp-java" .github/workflows/generate-student.yml
}

@test "generate-student : scripts/generate-student.sh présent et exécutable" {
    [ -x scripts/generate-student.sh ]
}

@test "generate-student : --apply transforme les 3 marqueurs (idiomatique : git init + run script)" {
    # IDIOMATIC : on simule le contexte enseignant complet :
    # branche solution avec marqueurs + branche main (orphan vide).
    # Le script lance Spotless en mode permissif (warning si KO,
    # non bloquant), donc le `[ "$status" -eq 0 ]` passe.
    git init -q -b solution
    git config user.email test@test
    git config user.name test
    mkdir -p src/main/java/fr/univ_amu/iut/exercice1
    cat > src/main/java/fr/univ_amu/iut/exercice1/Calcul.java <<'JAVA'
package fr.univ_amu.iut.exercice1;

public class Calcul {
  public int somme(int a, int b) {
    // --solution--
    return a + b;
    // --end-solution--
    /* --student--
    return 0;
    --end-student-- */
  }
}
JAVA
    cat > src/main/java/fr/univ_amu/iut/exercice1/Helper.java <<'JAVA'
// --solution-only--
package fr.univ_amu.iut.exercice1;

public class Helper {
  public static String greet() { return "salut"; }
}
JAVA
    git add -A
    git commit -q -m "init solution"

    # Crée une branche main orpheline (ce que ferait le workflow CI
    # à son premier run, ou un push manuel précédent).
    git checkout -q --orphan main
    git rm -rfq . >/dev/null 2>&1 || true
    : > .keep
    git add .keep
    git commit -q -m "main orpheline"
    git checkout -q solution

    # Lance le script en --apply
    run ./scripts/generate-student.sh --apply .
    [ "$status" -eq 0 ]

    # Le script a basculé sur main et appliqué le résultat. On va voir
    # le résultat sur main.
    git checkout -q main

    # Vérifications post-transformation :
    # 1. --solution-- supprimé
    ! grep -q "return a + b;" src/main/java/fr/univ_amu/iut/exercice1/Calcul.java
    # 2. --student-- décommenté
    grep -q "return 0;" src/main/java/fr/univ_amu/iut/exercice1/Calcul.java
    ! grep -q "/\* --student--" src/main/java/fr/univ_amu/iut/exercice1/Calcul.java
    # 3. --solution-only-- a supprimé Helper.java
    [ ! -f src/main/java/fr/univ_amu/iut/exercice1/Helper.java ]
}
