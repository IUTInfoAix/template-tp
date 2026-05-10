#!/usr/bin/env bats
# Tests Bats : feature pre-commit-spotless ACTIVÉE (sans lint-quality).
# Test idiomatique = `./mvnw spotless:apply` doit reformater un fichier
# mal formaté.

setup() { cd "$TP_DIR"; }

@test "spotless : .githooks/pre-commit présent et exécutable" {
    [ -x .githooks/pre-commit ]
}

@test "spotless : pas de bloc TEACHER-LINT injecté (lint-quality absent)" {
    ! grep -q "TEACHER-LINT\|scripts/lint-doc-coherence\|pmd:check" .githooks/pre-commit
}

@test "spotless : pas de placeholder Jinja résiduel" {
    ! grep -q "{{" .githooks/pre-commit
    ! grep -q "{%" .githooks/pre-commit
}

@test "spotless : pom.xml contient le plugin spotless-maven-plugin" {
    grep -q "spotless-maven-plugin" pom.xml
}

@test "spotless : pom.xml contient le plugin git-build-hook (configure core.hooksPath)" {
    grep -q "git-build-hook-maven-plugin" pom.xml
    grep -q "core.hooksPath>.githooks" pom.xml
}

@test "spotless : ./mvnw spotless:check passe sur le code minimal (idiomatique)" {
    # Pas de -q : on veut voir l'output en cas d'échec CI (sinon impossible
    # à debugger quand bats avale stdout). On valide juste l'exit code.
    run ./mvnw -B -ntp spotless:check
    if [ "$status" -ne 0 ]; then
        echo "=== spotless:check FAILED ==="
        echo "$output"
        return 1
    fi
}

@test "spotless : ./mvnw spotless:apply reformate un fichier mal formaté (idiomatique)" {
    # IDIOMATIC : crée un fichier .java volontairement non-formaté Google
    # Java Format (2 espaces, accolades collées, etc.), apply, vérifie
    # qu'il a été reformaté.
    cat > src/main/java/fr/univ_amu/iut/MalFormate.java <<'JAVA'
package fr.univ_amu.iut;
public class MalFormate{public static int  somme(int a,int b){return a+b;}}
JAVA
    avant=$(md5sum src/main/java/fr/univ_amu/iut/MalFormate.java | awk '{print $1}')
    ./mvnw -B -q -ntp spotless:apply
    apres=$(md5sum src/main/java/fr/univ_amu/iut/MalFormate.java | awk '{print $1}')
    rm src/main/java/fr/univ_amu/iut/MalFormate.java
    [ "$avant" != "$apres" ]
}
