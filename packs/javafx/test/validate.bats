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

@test "javafx : pom surefire useModulePath=false + argLine TestFX complet (6 entrées)" {
    # Le `--` après grep -Fq force grep à traiter le motif comme un argument
    # positionnel, sinon `--add-opens` serait pris pour une option de grep.
    # Suite Copilot review PR #27 : vérifier les 6 entrées de l'argLine, pas
    # juste un sous-ensemble.
    grep -Fq -- "<useModulePath>false</useModulePath>" pom.xml
    grep -Fq -- "--enable-native-access=ALL-UNNAMED" pom.xml
    grep -Fq -- "--enable-native-access=javafx.graphics" pom.xml
    grep -Fq -- "--add-reads javafx.graphics=ALL-UNNAMED" pom.xml
    grep -Fq -- "--add-opens javafx.graphics/com.sun.javafx.application=ALL-UNNAMED" pom.xml
    grep -Fq -- "--add-opens javafx.base/com.sun.javafx.runtime=ALL-UNNAMED" pom.xml
    grep -Fq -- "--add-exports javafx.graphics/com.sun.javafx.application=ALL-UNNAMED" pom.xml
}

@test "javafx : pom javafx-maven-plugin a jlinkImageName + launcher + options native-access" {
    grep -Fq -- "<jlinkImageName>app</jlinkImageName>" pom.xml
    grep -Fq -- "<launcher>launcher</launcher>" pom.xml
    # L'option native-access est aussi dans le bloc <options> du javafx-maven-plugin
    grep -Fq -- "<option>--enable-native-access=javafx.graphics</option>" pom.xml
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

@test "javafx : .vscode/tasks.json bascule sur 'javafx:run' (label 'JavaFX : lancer')" {
    grep -Fq -- '"label": "JavaFX : lancer (via Maven)"' .vscode/tasks.json
    grep -Fq -- '"command": "./mvnw verify javafx:run"' .vscode/tasks.json
    ! grep -Fq -- '"command": "./mvnw compile exec:java"' .vscode/tasks.json
}

@test "javafx : .vscode/launch.json bascule sur la version JavaFX (mainClass module + vmArgs)" {
    grep -Fq -- '"mainClass": "tp99.javafx/fr.univ_amu.iut.App"' .vscode/launch.json
    grep -Fq -- '"--add-opens"' .vscode/launch.json
    grep -Fq -- '"javafx.graphics/com.sun.javafx.application=ALL-UNNAMED"' .vscode/launch.json
}

@test "javafx : ai-tutor injecte la variation JavaFX (AGENTS.md + copilot-instructions.md)" {
    # Suite régression #16 : avec pack javafx, le tuteur IA doit parler
    # de concepts JavaFX (Property, Binding, FXML), pas d'artisanat
    # logiciel (TDD/kata).
    for f in AGENTS.md .github/copilot-instructions.md; do
        grep -Fq "JavaFX" "$f" || { echo "manque 'JavaFX 25' dans $f"; return 1; }
        grep -Fq "TestFX" "$f" || { echo "manque 'TestFX' dans $f"; return 1; }
        grep -Fq "concept JavaFX" "$f" || { echo "manque 'concept JavaFX' dans $f"; return 1; }
        grep -Fq "Property" "$f" || { echo "manque 'Property' dans $f"; return 1; }
        # Pas la variation artisanat
        ! grep -Fq "Maven Wrapper, JUnit Jupiter 6, AssertJ, Mockito" "$f" || { echo "$f a la variation artisanat alors que pack javafx actif"; return 1; }
    done
}

@test "javafx : workflow maven.yml utilise xvfb-run + java-package: jdk+fx" {
    grep -Fq "xvfb-run --auto-servernum" .github/workflows/maven.yml
    # Zulu standard sans 'jdk+fx' ne ramène pas les natives openjfx,
    # cf. issue #18.
    grep -Fq "java-package: 'jdk+fx'" .github/workflows/maven.yml
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
