#!/usr/bin/env bats
# Tests Bats : feature maven-ci ACTIVÉE.
# Test idiomatique : YAML valide via parser strict + grep des éléments
# critiques (action setup-java, version Java interpolée, mvnw verify).
# Le vrai test fonctionnel = `act -j build` (https://github.com/nektos/act),
# mais c'est lourd à installer en CI à chaque exécution. À ajouter en
# job séparé "test-maven-ci-with-act" plus tard si valeur ajoutée.

setup() { cd "$TP_DIR"; }

@test "maven-ci : .github/workflows/maven.yml présent" {
    [ -f .github/workflows/maven.yml ]
}

@test "maven-ci : YAML strict valide (parser python)" {
    run python3 -c "import yaml; yaml.safe_load(open('.github/workflows/maven.yml'))"
    [ "$status" -eq 0 ]
}

@test "maven-ci : action setup-java (v5+) référencée" {
    grep -qE "actions/setup-java@v[5-9]" .github/workflows/maven.yml
}

@test "maven-ci : version Java interpolée depuis stack.java_version" {
    grep -q "Set up JDK 25" .github/workflows/maven.yml
    grep -q "java-version: '25'" .github/workflows/maven.yml
}

@test "maven-ci : distribution zulu" {
    grep -q "distribution: 'zulu'" .github/workflows/maven.yml
}

@test "maven-ci : utilise ./mvnw verify (pas 'mvn' direct)" {
    grep -q "./mvnw -B verify" .github/workflows/maven.yml
}

@test "maven-ci : pas de placeholder Jinja résiduel" {
    ! grep -q "{{" .github/workflows/maven.yml
    ! grep -q "{%" .github/workflows/maven.yml
}

@test "maven-ci : pas de bloc xvfb-run (pack javafx absent)" {
    ! grep -q "xvfb-run" .github/workflows/maven.yml
}
