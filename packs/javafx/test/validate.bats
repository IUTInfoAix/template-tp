#!/usr/bin/env bats
# Tests Bats : pack javafx ACTIVÉ.
# Test idiomatique = `xvfb-run --auto-servernum ./mvnw verify` qui
# exécute réellement TestFX. La CI installe xvfb avant ce job.

setup() { cd "$TP_DIR"; }

@test "javafx : pom.xml contient les 4 deps JavaFX" {
    for dep in javafx-controls javafx-fxml javafx-graphics javafx-media; do
        grep -q "$dep" pom.xml || { echo "$dep manquant"; return 1; }
    done
}

@test "javafx : pom.xml contient testfx-core + testfx-junit5" {
    grep -q "testfx-core" pom.xml
    grep -q "testfx-junit5" pom.xml
}

@test "javafx : pom.xml contient javafx-maven-plugin" {
    grep -q "javafx-maven-plugin" pom.xml
}

@test "javafx : module-info.java présent à la racine de src/main/java/" {
    [ -f src/main/java/module-info.java ]
}

@test "javafx : module-info.java nommé 'tp<numero>.javafx' (cohérent avec mainClass pom et compatible avec la convention nom de module Java sans tirets)" {
    # Le nom de module Java n'autorise pas les tirets, donc on dérive de
    # tp.numero (entier) et pas de tp.titre_court (kebab-case). Pour la
    # fixture javafx (numero: 99), le module est tp99.javafx.
    grep -Fq "open module tp99.javafx" src/main/java/module-info.java
}

@test "javafx : module-info.java exporte fr.univ_amu.iut + requires les 5 modules JavaFX (alignés sur les 5 deps du pom)" {
    grep -Fq "exports fr.univ_amu.iut;" src/main/java/module-info.java
    grep -Fq "requires transitive javafx.base;" src/main/java/module-info.java
    grep -Fq "requires transitive javafx.controls;" src/main/java/module-info.java
    grep -Fq "requires transitive javafx.graphics;" src/main/java/module-info.java
    grep -Fq "requires transitive javafx.fxml;" src/main/java/module-info.java
    grep -Fq "requires transitive javafx.media;" src/main/java/module-info.java
}

@test "javafx : pom mainClass aligné avec module-info (cross-fichier)" {
    # Suite Copilot review PR #26 : un test qui parle d'alignement doit
    # vraiment vérifier l'alignement. Si module-info.java dit
    # 'open module tp99.javafx', le mainClass du javafx-maven-plugin doit
    # référencer ce même nom de module.
    grep -Fq "tp99.javafx/fr.univ_amu.iut.App" pom.xml
}

@test "javafx : App.java basculé sur la version JavaFX (extends Application)" {
    grep -q "extends Application" src/main/java/fr/univ_amu/iut/App.java
    grep -q "javafx.application.Application" src/main/java/fr/univ_amu/iut/App.java
    ! grep -q "import java.util.Scanner" src/main/java/fr/univ_amu/iut/App.java
}

@test "javafx : AppTest.java basculé sur la version TestFX (FxRobot)" {
    grep -q "FxRobot" src/test/java/fr/univ_amu/iut/AppTest.java
    grep -q "ApplicationExtension" src/test/java/fr/univ_amu/iut/AppTest.java
    ! grep -q "ByteArrayOutputStream" src/test/java/fr/univ_amu/iut/AppTest.java
}

@test "javafx : .devcontainer/Dockerfile présent (xvfb)" {
    [ -f .devcontainer/Dockerfile ]
    grep -q "xvfb" .devcontainer/Dockerfile
}

@test "javafx : DarkTheme.css présent" {
    [ -f src/main/resources/DarkTheme.css ]
}

@test "core : screenshots Codespace présents dans .github/assets/ (déplacés depuis src/main/resources/assets/ pour rester accessibles aux TPs sans pack javafx)" {
    [ -f .github/assets/codespace_vscode.png ]
    [ -f .github/assets/codespace_vscode_nouveau_terminal.png ]
    [ -f .github/assets/create_codespace_on_main.png ]
}

@test "javafx : devcontainer.json a feature desktop-lite + JDK 25-zulu-fx" {
    grep -q "desktop-lite" .devcontainer/devcontainer.json
    grep -q '"version": "25-zulu-fx"' .devcontainer/devcontainer.json
}

@test "javafx : workflow maven.yml utilise xvfb-run" {
    grep -q "xvfb-run --auto-servernum" .github/workflows/maven.yml
}

@test "javafx : ./mvnw dependency:tree liste les 4 modules JavaFX (idiomatique)" {
    # NB: pas de -q (qui supprimerait l'output dependency:tree).
    run bash -c "./mvnw -B -ntp dependency:tree | grep -c openjfx"
    [ "$status" -eq 0 ]
    [ "$output" -ge 6 ]   # 4 deps directes + transitive (linux classifier)
}

@test "javafx : xvfb-run ./mvnw verify passe (TestFX réellement exécuté, idiomatique)" {
    # IDIOMATIC : on lance vraiment TestFX via xvfb-run. C'est CE test
    # qui couvre la promesse "le TP JavaFX généré marche en CI".
    # xvfb doit être installé sur l'host (apt install xvfb).
    run xvfb-run --auto-servernum ./mvnw -B -q -ntp verify
    [ "$status" -eq 0 ]
}
