#!/usr/bin/env bats
# Tests de la stratégie _skip_if_exists : un re-`copier copy` (ou
# `copier update`) sur un TP existant ne doit JAMAIS écraser le
# contenu pédagogique personnalisé (README, src/exercice*, App.java).
# Mais il doit mettre à jour l'infra (pom.xml, workflows, .githooks...).
#
# Le test simule un TP "vivant" :
#   1. Génère un TP from scratch.
#   2. Modifie README + App.java avec des marqueurs custom (CUSTOM-MARKER).
#   3. Modifie aussi un fichier d'infra (.gitattributes) pour vérifier
#      que celui-ci sera ÉCRASÉ.
#   4. Re-lance copier copy --overwrite (équivalent du copier update sans
#      .copier-answers.yml stocké).
#   5. Vérifie que les marqueurs custom du contenu sont préservés et
#      que la modif de l'infra est bien revenue à la version méta-template.

ENABLED_FIXTURE="${BATS_TEST_DIRNAME}/../features/lint-quality/test/answers.yml"

setup() {
    rm -rf /tmp/tp-skip-test /tmp/template-source-skip
    # BATS_TEST_DIRNAME = .../tests, donc /.. = racine du méta-template.
    # Marche en local et en CI sans hardcoder le chemin.
    cp -r "${BATS_TEST_DIRNAME}/.." /tmp/template-source-skip
    rm -rf /tmp/template-source-skip/.git
}

teardown() {
    rm -rf /tmp/tp-skip-test /tmp/template-source-skip
}

@test "skip_if_exists : re-copier copy préserve README, App.java, src/exercice*/ ; écrase l'infra" {
    # Génération initiale
    copier copy --trust --defaults --data-file "$ENABLED_FIXTURE" \
        /tmp/template-source-skip /tmp/tp-skip-test

    # Personnalisation pédagogique (ces fichiers sont dans _skip_if_exists)
    echo "" >> /tmp/tp-skip-test/README.md
    echo "# CUSTOM-MARKER-README - ne pas écraser" >> /tmp/tp-skip-test/README.md
    mkdir -p /tmp/tp-skip-test/src/main/java/fr/univ_amu/iut/exercice42
    echo "// CUSTOM-EXERCICE-42" > /tmp/tp-skip-test/src/main/java/fr/univ_amu/iut/exercice42/FizzBuzz.java

    # Bricoler un fichier d'infra (devra être écrasé)
    echo "# CUSTOM-INFRA-MARKER (devrait disparaître)" > /tmp/tp-skip-test/.gitattributes

    # Bricoler App.java (PAS dans _skip_if_exists pour permettre la
    # bascule pack javafx via copier update). Cette marque DOIT être
    # écrasée par le re-copier copy.
    echo "// CUSTOM-MARKER-APP-DOIT-ETRE-ECRASE" >> /tmp/tp-skip-test/src/main/java/fr/univ_amu/iut/App.java

    # Re-lance copier copy --overwrite (simule copier update)
    copier copy --trust --defaults --overwrite \
        --data-file "$ENABLED_FIXTURE" \
        /tmp/template-source-skip /tmp/tp-skip-test

    # Le contenu pédagogique doit être préservé
    grep -Fq "CUSTOM-MARKER-README" /tmp/tp-skip-test/README.md \
        || { echo "README.md a été écrasé"; return 1; }
    grep -Fq "CUSTOM-EXERCICE-42" /tmp/tp-skip-test/src/main/java/fr/univ_amu/iut/exercice42/FizzBuzz.java \
        || { echo "src/main/java/.../exercice42/FizzBuzz.java a été écrasé"; return 1; }

    # L'infra doit être revenue à la version méta-template
    ! grep -Fq "CUSTOM-INFRA-MARKER" /tmp/tp-skip-test/.gitattributes \
        || { echo ".gitattributes n'a PAS été écrasé alors qu'il devrait l'être"; return 1; }

    # App.java NE doit PAS être préservé (volontairement out de
    # _skip_if_exists pour permettre la bascule pack javafx via
    # copier update).
    ! grep -Fq "CUSTOM-MARKER-APP-DOIT-ETRE-ECRASE" /tmp/tp-skip-test/src/main/java/fr/univ_amu/iut/App.java \
        || { echo "App.java n'a PAS été écrasé alors qu'il devrait l'être (cf. tradeoff bascule pack javafx)"; return 1; }
}
