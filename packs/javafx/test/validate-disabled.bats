#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-javafx : pom.xml ne contient AUCUNE dep JavaFX" {
    ! grep -qE "javafx-(controls|fxml|graphics|media)" pom.xml
}

@test "no-javafx : pom.xml ne contient AUCUNE dep TestFX" {
    ! grep -q "testfx" pom.xml
}

@test "no-javafx : pom.xml ne contient PAS javafx-maven-plugin" {
    ! grep -q "javafx-maven-plugin" pom.xml
}

@test "no-javafx : module-info.java absent (pas de mode JPMS sans pack javafx)" {
    [ ! -f src/main/java/module-info.java ]
}

@test "no-javafx : App.java reste sur la version console (Scanner)" {
    grep -q "import java.util.Scanner" src/main/java/fr/univ_amu/iut/App.java
    ! grep -q "extends Application" src/main/java/fr/univ_amu/iut/App.java
}

@test "no-javafx : .devcontainer/Dockerfile absent" {
    [ ! -f .devcontainer/Dockerfile ]
}

@test "no-javafx : DarkTheme.css absent" {
    [ ! -f src/main/resources/DarkTheme.css ]
}

@test "no-javafx : assets Codespace présents dans .github/assets/ (core, posés indépendamment du pack)" {
    # Les screenshots Codespace ne dépendent pas du pack javafx (déplacés
    # vers .github/assets/ après PR #25 pour éviter les liens cassés dans
    # le README sur les TPs sans javafx).
    [ -f .github/assets/codespace_vscode.png ]
}

@test "no-javafx : devcontainer.json sans desktop-lite, JDK 25-zulu (sans -fx)" {
    ! grep -q "desktop-lite" .devcontainer/devcontainer.json
    grep -q '"version": "25-zulu"' .devcontainer/devcontainer.json
    ! grep -q '"version": "25-zulu-fx"' .devcontainer/devcontainer.json
}

@test "no-javafx : workflow maven.yml sans xvfb-run et sans jdk+fx" {
    ! grep -q "xvfb-run" .github/workflows/maven.yml
    ! grep -Fq "java-package: 'jdk+fx'" .github/workflows/maven.yml
}
