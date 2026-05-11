#!/usr/bin/env bats
# Tests Bats : feature ai-tutor ACTIVÉE.
# Le check critique est la SYNCHRONISATION du bloc TDD-PLAYBOOK entre
# AGENTS.md (lu par Claude/Codex/Aider...) et copilot-instructions.md
# (lu par Copilot Chat). Si les deux divergent, les agents IA reçoivent
# des consignes incohérentes selon l'outil utilisé en séance.

setup() { cd "$TP_DIR"; }

# Helper : extrait le bloc entre <!-- TDD-PLAYBOOK-START --> et
# <!-- TDD-PLAYBOOK-END --> d'un fichier markdown.
extract_playbook() {
    sed -n '/<!-- TDD-PLAYBOOK-START -->/,/<!-- TDD-PLAYBOOK-END -->/p' "$1"
}

@test "ai-tutor : AGENTS.md présent" {
    [ -f AGENTS.md ]
}

@test "ai-tutor : .github/copilot-instructions.md présent" {
    [ -f .github/copilot-instructions.md ]
}

@test "ai-tutor : AGENTS.md interpolé avec module.code/module.titre" {
    grep -q "Test ai-tutor" AGENTS.md
    grep -q "R2\.99" AGENTS.md
}

@test "ai-tutor : pas de placeholder Jinja résiduel dans AGENTS.md" {
    ! grep -q "{{" AGENTS.md
}

@test "ai-tutor : pas de placeholder Jinja résiduel dans copilot-instructions.md" {
    ! grep -q "{{" .github/copilot-instructions.md
}

@test "ai-tutor : marqueurs TDD-PLAYBOOK présents dans AGENTS.md" {
    grep -q "<!-- TDD-PLAYBOOK-START -->" AGENTS.md
    grep -q "<!-- TDD-PLAYBOOK-END -->" AGENTS.md
}

@test "ai-tutor : marqueurs TDD-PLAYBOOK présents dans copilot-instructions.md" {
    grep -q "<!-- TDD-PLAYBOOK-START -->" .github/copilot-instructions.md
    grep -q "<!-- TDD-PLAYBOOK-END -->" .github/copilot-instructions.md
}

@test "ai-tutor : bloc TDD-PLAYBOOK strictement identique entre AGENTS.md et copilot-instructions.md (idiomatique : diff)" {
    # IDIOMATIC : on extrait le bloc entre marqueurs des 2 fichiers et on
    # compare bit-à-bit. Aucune divergence tolérée. C'est le check qui
    # fait foi pour garantir la cohérence des consignes IA.
    extract_playbook AGENTS.md > /tmp/playbook-agents.md
    extract_playbook .github/copilot-instructions.md > /tmp/playbook-copilot.md
    run diff -u /tmp/playbook-agents.md /tmp/playbook-copilot.md
    [ "$status" -eq 0 ]
}

@test "ai-tutor sans javafx : variation 'artisanat logiciel' active (Maven Wrapper, pas JavaFX/TestFX)" {
    # Suite régression #16 : sans pack javafx, le tuteur IA doit parler
    # d'artisanat logiciel (TDD/kata/refactoring), pas de concepts JavaFX.
    grep -Fq "Maven Wrapper" AGENTS.md
    grep -Fq "Mockito" AGENTS.md
    grep -Fq "artisanat logiciel" AGENTS.md
    ! grep -Fq "JavaFX" AGENTS.md
    ! grep -Fq "TestFX" AGENTS.md
    ! grep -Fq "concept JavaFX" AGENTS.md
}

@test "ai-tutor sans javafx : meme variation dans copilot-instructions.md" {
    grep -Fq "Maven Wrapper" .github/copilot-instructions.md
    grep -Fq "artisanat logiciel" .github/copilot-instructions.md
    ! grep -Fq "JavaFX" .github/copilot-instructions.md
    ! grep -Fq "TestFX" .github/copilot-instructions.md
}

@test "ai-tutor : bloc TDD-PLAYBOOK non-vide (au moins 100 lignes)" {
    n=$(extract_playbook AGENTS.md | wc -l)
    [ "$n" -gt 100 ]
}
